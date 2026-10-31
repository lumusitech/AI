#!/usr/bin/env bash

# ==============================================================================
# Lumusitech AI Workspace - Machine Setup Script
# ==============================================================================
# Idempotent setup script to link custom skills, MCP configurations, and global
# agent directives for OpenCode and Antigravity across machines.
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Initializing AI Workspace Setup from: ${REPO_DIR}"

# Idempotent link helper: skips when the link already resolves to the target,
# and replaces real (non-link) files/dirs so the repo stays the source of truth.
# Comparison uses `readlink` without -f for macOS portability: setup always
# creates links with absolute targets.
link_with_skip() {
  local src="$1" dst="$2"
  if [ -e "${dst}" ] && [ ! -L "${dst}" ]; then
    echo "🧹 Replacing existing '${dst}' with repo link (repo is source of truth)."
    rm -rf "${dst}"
  fi
  if [ -L "${dst}" ] && [ "$(readlink "${dst}")" = "${src}" ]; then
    echo "✅ Already linked: ${dst}"
    return 0
  fi
  ln -sfn "${src}" "${dst}"
  echo "🔗 Linked: ${dst}"
}

# 1. Environment & Credentials Setup
if [ ! -f "${REPO_DIR}/.env" ]; then
    echo "⚠️  .env file missing. Creating from .env.template..."
    cp "${REPO_DIR}/.env.template" "${REPO_DIR}/.env"
    echo "🔑 Please edit ${REPO_DIR}/.env with your actual tokens (e.g., GITHUB_TOKEN)."
else
    echo "✅ .env configuration file exists."
fi

# Load variables if .env exists
if [ -f "${REPO_DIR}/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "${REPO_DIR}/.env" || true
    set +a
fi

# 2. Antigravity Configuration Links (~/.gemini/config)
# Antigravity (App / IDE / CLI) reads skills, rules, MCP servers and lifecycle
# hooks from its global config directory. Everything links back to this repo
# (single source of truth), so a `git pull` propagates to both agents.
GEMINI_CONFIG_DIR="${HOME}/.gemini/config"
mkdir -p "${GEMINI_CONFIG_DIR}"

# Global skills (auto-discovered; same open SKILL.md standard as OpenCode).
echo "🔗 Linking skills to Antigravity global config (${GEMINI_CONFIG_DIR}/skills)..."
link_with_skip "${REPO_DIR}/skills" "${GEMINI_CONFIG_DIR}/skills"

# Global rules: Antigravity reads AGENTS.md as an always-on rule. We link the
# single source of truth instead of duplicating it into a separate GEMINI.md.
echo "🔗 Linking AGENTS.md to Antigravity global rules (${GEMINI_CONFIG_DIR}/AGENTS.md)..."
link_with_skip "${REPO_DIR}/AGENTS.md" "${GEMINI_CONFIG_DIR}/AGENTS.md"

# MCP servers (standard `mcpServers` schema). Generated further below with the
# machine-specific env values resolved (Antigravity does not expand ${VAR}).

# Lifecycle hooks (PreToolUse env-protection + Stop notification).
echo "🔗 Linking hooks.json to Antigravity global config (${GEMINI_CONFIG_DIR}/hooks.json)..."
link_with_skip "${REPO_DIR}/hooks.json" "${GEMINI_CONFIG_DIR}/hooks.json"

# Remove artifacts from the previous Antigravity wiring (obsolete names).
for legacy in skills.json GEMINI.md mcp.json mcp_config.json.backup; do
    if [ -e "${GEMINI_CONFIG_DIR}/${legacy}" ] || [ -L "${GEMINI_CONFIG_DIR}/${legacy}" ]; then
        echo "🧹 Removing obsolete Antigravity artifact ${GEMINI_CONFIG_DIR}/${legacy}..."
        rm -f "${GEMINI_CONFIG_DIR}/${legacy}"
    fi
done
if [ -L "${HOME}/.gemini/extensions/lumusitech" ]; then
    echo "🧹 Removing obsolete Gemini extension link (~/.gemini/extensions/lumusitech)..."
    rm -f "${HOME}/.gemini/extensions/lumusitech"
fi

# 3. OpenCode Configuration Links (~/.config/opencode)
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
mkdir -p "${OPENCODE_CONFIG_DIR}"

echo "🔗 Linking opencode.jsonc to OpenCode config (${OPENCODE_CONFIG_DIR}/opencode.jsonc)..."
link_with_skip "${REPO_DIR}/opencode.jsonc" "${OPENCODE_CONFIG_DIR}/opencode.jsonc"

echo "🔗 Linking dcp.jsonc to OpenCode config (${OPENCODE_CONFIG_DIR}/dcp.jsonc)..."
link_with_skip "${REPO_DIR}/dcp.jsonc" "${OPENCODE_CONFIG_DIR}/dcp.jsonc"

echo "🔗 Linking AGENTS.md to OpenCode config (${OPENCODE_CONFIG_DIR}/AGENTS.md)..."
link_with_skip "${REPO_DIR}/AGENTS.md" "${OPENCODE_CONFIG_DIR}/AGENTS.md"

echo "🔗 Linking opencode agents to OpenCode config (${OPENCODE_CONFIG_DIR}/agents)..."
mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
for agent in "${REPO_DIR}"/agents/*.md; do
  [ -f "${agent}" ] || continue
  link_with_skip "${agent}" "${OPENCODE_CONFIG_DIR}/agents/$(basename "${agent}")"
done

# Remove orphan agent links pointing at agents no longer in the repo
for agent_link in "${OPENCODE_CONFIG_DIR}"/agents/*; do
  [ -L "${agent_link}" ] || continue
  if [ ! -e "${agent_link}" ]; then
    echo "🧹 Removing orphan agent link: $(basename "${agent_link}")"
    rm -f "${agent_link}"
  fi
done

echo "🔗 Linking opencode plugins to OpenCode config (${OPENCODE_CONFIG_DIR}/plugins)..."
link_with_skip "${REPO_DIR}/plugins" "${OPENCODE_CONFIG_DIR}/plugins"

echo "🔗 Linking tui.json to OpenCode config (${OPENCODE_CONFIG_DIR}/tui.json)..."
link_with_skip "${REPO_DIR}/tui.json" "${OPENCODE_CONFIG_DIR}/tui.json"

echo "🔗 Linking skills to OpenCode config (${OPENCODE_CONFIG_DIR}/skills)..."
link_with_skip "${REPO_DIR}/skills" "${OPENCODE_CONFIG_DIR}/skills"

# 3b. Per-user local memory database (never committed to the repo)
echo "🧠 Setting up per-user local memory database..."
bash "${REPO_DIR}/scripts/memory-setup.sh"

# 3c. Install MCP servers locally and expose their binaries on PATH.
# This removes `npx -y <pkg>` from opencode.jsonc, so opencode no
# longer resolves/downloads packages from the registry at startup.
echo "📦 Installing local MCP servers (package.json)..."
LOCAL_BIN_DIR="${HOME}/.local/bin"
mkdir -p "${LOCAL_BIN_DIR}"

# MCP launchers, node/npm/npx and the archify CLI are exposed as links here, so
# this directory must be on PATH for them to resolve (fresh WSL2 images often
# lack it).
case ":${PATH}:" in
    *":${LOCAL_BIN_DIR}:"*) ;;
    *)
        echo "  ⚠️  ${LOCAL_BIN_DIR} is not on PATH. Add this to your shell profile:"
        echo "        export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

if command -v pnpm >/dev/null 2>&1; then
    PM="pnpm"
elif command -v corepack >/dev/null 2>&1; then
    corepack enable pnpm >/dev/null 2>&1 || true
    if command -v pnpm >/dev/null 2>&1; then
        PM="pnpm"
    else
        PM="npm"
    fi
else
    PM="npm"
fi
echo "  • Package manager: ${PM}"
( cd "${REPO_DIR}" && "${PM}" install --loglevel=error )

# MCP servers are Node processes: every launcher installed in node_modules/.bin
# is a pnpm cmd-shim whose last line is `exec node ...`. If node is missing the
# whole MCP layer dies at startup with exit 127 ("exec: node: not found"), which
# used to surface only as a generic "network" warning below.
NODE_AVAILABLE=0
NODE_REASON=""

# Remediation steps shown whenever the Node runtime is missing or too old.
# Kept in a function so the preflight and the final summary cannot drift apart.
print_node_remediation() {
    cat <<'NODE_HELP'
════════════════════════════════════════════════════════════════════════════
  ❌ Node.js is not usable — every MCP server will fail to start
════════════════════════════════════════════════════════════════════════════
  MCP launchers are pnpm shims whose last line is `exec node ...`, so they
  exit with code 127 ("exec: node: not found") until Node is available.

  Do the following, then re-run ./setup.sh:

    1. Install Node:
         mise use -g node@lts        # recommended: mise manages the toolchain
       No mise yet? Install it, then repeat step 1:
         macOS:      brew install mise
         Linux/WSL2: curl https://mise.run | sh
       Not using mise: brew install node (macOS) or your distro's nodejs package.

    2. Open a NEW terminal (or run: exec zsh) and confirm it resolves:
         node -v                   # must print a version, e.g. v26.13.0

    3. Re-run the installer:
         cd ~/.agent && ./setup.sh

  This run continues (configs are linked, skills are verified) but skips the
  postinstall steps and every MCP server, so setup is NOT complete.
════════════════════════════════════════════════════════════════════════════
NODE_HELP
}

if command -v node >/dev/null 2>&1; then
    NODE_MAJOR="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')"
    if [ -n "${NODE_MAJOR}" ] && [ "${NODE_MAJOR}" -lt 20 ]; then
        NODE_REASON="node $(node -v) is too old (MCP servers need >= 20)"
        echo "  ❌ Node runtime too old: $(node -v) ($(command -v node))"
    else
        NODE_AVAILABLE=1
        echo "  • Node runtime: $(node -v) ($(command -v node))"
    fi
else
    NODE_REASON="node is missing from PATH"
    echo "  ❌ Node runtime not found on PATH"
fi

if [ "${NODE_AVAILABLE}" -eq 0 ]; then
    print_node_remediation
fi

# codegraph-mcp fetches its native engine in postinstall; pnpm 10+ blocks build
# scripts by default, so run it explicitly (idempotent: skips when engine present).
CODEGRAPH_POSTINSTALL="${REPO_DIR}/node_modules/@astudioplus/codegraph-mcp/bin/postinstall.js"
if [ -f "${CODEGRAPH_POSTINSTALL}" ]; then
    echo "  • Ensuring codegraph-mcp native engine..."
    if [ "${NODE_AVAILABLE}" -eq 1 ]; then
        node "${CODEGRAPH_POSTINSTALL}" || echo "  ⚠️ codegraph-mcp engine fetch failed (network required on first install)"
    else
        echo "  ⏭️  Skipped: no usable Node runtime (see the fix steps above)"
    fi
fi

# codebase-memory-mcp fetches its native runtime in postinstall (node install.js);
# pnpm 10+ blocks build scripts by default, so run it explicitly (idempotent).
CODEBASE_MEMORY_POSTINSTALL="${REPO_DIR}/node_modules/codebase-memory-mcp/install.js"
if [ -f "${CODEBASE_MEMORY_POSTINSTALL}" ]; then
    echo "  • Ensuring codebase-memory-mcp native runtime..."
    if [ "${NODE_AVAILABLE}" -eq 1 ]; then
        node "${CODEBASE_MEMORY_POSTINSTALL}" || echo "  ⚠️ codebase-memory-mcp runtime fetch failed (network required on first install)"
    else
        echo "  ⏭️  Skipped: no usable Node runtime (see the fix steps above)"
    fi
fi

MCP_BINS=(
    "codebase-memory-mcp"
    "codegraph-mcp"
    "context7-mcp"
    "mcp-server-github"
    "mcp-server-memory"
    "playwright-mcp"
)
for bin in "${MCP_BINS[@]}"; do
    src="${REPO_DIR}/node_modules/.bin/${bin}"
    if [ -e "${src}" ]; then
        ln -sfn "${src}" "${LOCAL_BIN_DIR}/${bin}"
        echo "  ✅ MCP bin on PATH: ${bin}"
    else
        echo "  ❌ MCP bin missing after install: ${bin}"
    fi
done

# The MCP launchers above call bare `node`. Interactive shells get it from the
# mise shims, but the background service and GUI launches can inherit a PATH
# without them (that is why every server used to fail with exit 127). Exposing
# node/npm/npx in ~/.local/bin — already present in the PATH of the service and
# of most macOS launch contexts — makes the runtime resolvable everywhere.
# The links point at mise's shims, not at a versioned binary, so `mise use -g
# node@X` keeps working without re-running this script.
if [ "${NODE_AVAILABLE}" -eq 1 ]; then
    NODE_BIN_DIR="$(dirname "$(command -v node)")"
    # Prefer mise's shims when mise manages node: the shim path is stable across
    # `mise use -g node@X` upgrades, while installs/node/<version>/bin is not.
    MISE_SHIM_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/mise/shims"
    if [ -x "${MISE_SHIM_DIR}/node" ]; then
        NODE_BIN_DIR="${MISE_SHIM_DIR}"
    fi
    for tool in node npm npx; do
        if [ -x "${NODE_BIN_DIR}/${tool}" ] \
           && [ ! -e "${LOCAL_BIN_DIR}/${tool}" ] && [ ! -L "${LOCAL_BIN_DIR}/${tool}" ]; then
            ln -sfn "${NODE_BIN_DIR}/${tool}" "${LOCAL_BIN_DIR}/${tool}"
            echo "  ✅ Node tool on PATH: ${LOCAL_BIN_DIR}/${tool}"
        fi
    done
fi

# Expose archify CLI binary on PATH if installed in skills/archify
if [ -f "${REPO_DIR}/skills/archify/bin/archify.mjs" ]; then
    chmod +x "${REPO_DIR}/skills/archify/bin/archify.mjs"
    ln -sfn "${REPO_DIR}/skills/archify/bin/archify.mjs" "${LOCAL_BIN_DIR}/archify"
    echo "  ✅ Archify CLI on PATH: archify"
fi

# Expose github-mcp-bridge binary on PATH (resolves auth from gh keyring)
if [ -f "${REPO_DIR}/scripts/github-mcp-bridge.mjs" ]; then
    chmod +x "${REPO_DIR}/scripts/github-mcp-bridge.mjs"
    ln -sfn "${REPO_DIR}/scripts/github-mcp-bridge.mjs" "${LOCAL_BIN_DIR}/github-mcp-bridge"
    echo "  ✅ GitHub MCP bridge on PATH: github-mcp-bridge"
fi

# Detect Chrome for playwright; fall back to chromium when absent.
# PLAYWRIGHT_BROWSER is consumed by opencode/antigravity via env (see
# opencode.jsonc / mcp.json), so it must be loaded from .env on every shell.
echo "🌐 Detecting browser for playwright MCP..."
PLAYWRIGHT_BROWSER="chromium"
if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    PLAYWRIGHT_BROWSER="chrome"
elif command -v google-chrome >/dev/null 2>&1 \
    || command -v google-chrome-stable >/dev/null 2>&1 \
    || command -v google-chrome-beta >/dev/null 2>&1; then
    PLAYWRIGHT_BROWSER="chrome"
fi
echo "  • PLAYWRIGHT_BROWSER=${PLAYWRIGHT_BROWSER}"

if [ -f "${REPO_DIR}/.env" ]; then
    if grep -qE '^PLAYWRIGHT_BROWSER=' "${REPO_DIR}/.env"; then
        sed -i.bak "s/^PLAYWRIGHT_BROWSER=.*/PLAYWRIGHT_BROWSER=${PLAYWRIGHT_BROWSER}/" "${REPO_DIR}/.env"
        rm -f "${REPO_DIR}/.env.bak"
    else
        printf '\n# Resolved by setup.sh (chrome if installed, else chromium). Do not edit manually.\nPLAYWRIGHT_BROWSER=%s\n' "${PLAYWRIGHT_BROWSER}" >> "${REPO_DIR}/.env"
    fi
fi

# Antigravity MCP config: Antigravity does not expand ${VAR} in mcp_config.json
# env values, so generate the file with the machine-specific values resolved.
MCP_TARGET="${GEMINI_CONFIG_DIR}/mcp_config.json"
rm -f "${MCP_TARGET}"
MEM_PATH_RESOLVED=""
if [ -f "${REPO_DIR}/.env" ]; then
    MEM_PATH_RESOLVED="$(grep -E '^MEMORY_FILE_PATH=' "${REPO_DIR}/.env" | tail -n1 | cut -d= -f2- | tr -d '"')"
fi
python3 - "${REPO_DIR}/mcp.json" "${MCP_TARGET}" "${MEM_PATH_RESOLVED}" "${PLAYWRIGHT_BROWSER}" <<'PYEOF'
import json, sys

src, dst, mem_path, browser = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(src, encoding="utf-8") as f:
    data = json.load(f)

subs = {"${MEMORY_FILE_PATH}": mem_path, "${PLAYWRIGHT_BROWSER}": browser}
for server in data.get("mcpServers", {}).values():
    env = server.get("env")
    if isinstance(env, dict):
        for key, val in list(env.items()):
            if isinstance(val, str) and val in subs and subs[val]:
                env[key] = subs[val]

with open(dst, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  ✅ Antigravity MCP config generated (env resolved): {dst}")
PYEOF

# 4. Clean up legacy skill & temporary directories to prevent duplicate loading & save space
echo "🧹 Cleaning legacy paths (~/.agents, ~/.claude, ~/temp/antigravity-awesome-skills)..."
rm -rf "${HOME}/.agents"
rm -rf "${HOME}/.claude"
rm -rf "${HOME}/temp/antigravity-awesome-skills"

# Remove legacy ~/.gemini/skills (standalone dir outside ~/.gemini/config) that
# used to hold a duplicate context7-mcp skill colliding with the symlinked copy.
if [ -d "${HOME}/.gemini/skills" ]; then
    echo "🧹 Removing legacy ${HOME}/.gemini/skills (duplicate skill source)..."
    rm -rf "${HOME}/.gemini/skills"
fi

# 4b. Git credential helper fix (GITHUB_TOKEN vs gh OAuth token)
# gh auth git-credential prefers GITHUB_TOKEN/GH_TOKEN from the environment over
# the full OAuth token stored by `gh auth login`. A fine-grained PAT lacks the
# `Contents: write` permission needed to delete remote branches, breaking
# `git push --delete`. Force git to use gh's stored OAuth token.
# --replace-all: removes any previously configured helpers for these hosts so a
# single source of truth remains. Without it, `git config` fails with
# "multiple values" when duplicate helpers exist (e.g. after re-logins of gh or
# a leftover credential.helper), aborting the script under set -euo pipefail.
if command -v gh >/dev/null 2>&1; then
    GH_BIN="$(command -v gh)"
    echo "🔧 Configuring git to use gh OAuth token (ignoring GITHUB_TOKEN/GH_TOKEN)..."
    git config --global --replace-all credential.https://github.com.helper \
      "!env -u GITHUB_TOKEN -u GH_TOKEN ${GH_BIN} auth git-credential"
    git config --global --replace-all credential.https://gist.github.com.helper \
      "!env -u GITHUB_TOKEN -u GH_TOKEN ${GH_BIN} auth git-credential"
    echo "  ✅ git credential helper: ${GH_BIN}"
else
    echo "⚠️  gh CLI not found. Skipping git credential helper config."
fi

# 4c. Vendored planning skills (wayfinder suite + WBS) and custom skills.
# Vendored skills are committed to this repo under skills/, so a fresh clone
# already has them. This block (a) verifies presence, and (b) with
# `--refresh-vendored-skills` re-fetches the vendored copies from their upstream
# sources so they stay in sync. Custom skills (estimate-costs, to-tickets,
# ask-matt, plan-phases-create, plan-phases-implement) are NOT refreshed.
VENDOR_SOURCES=(
  "mattpocock|wayfinder|https://github.com/mattpocock/skills|skills/engineering/wayfinder"
  "mattpocock|setup-matt-pocock-skills|https://github.com/mattpocock/skills|skills/engineering/setup-matt-pocock-skills"
  "mattpocock|to-spec|https://github.com/mattpocock/skills|skills/engineering/to-spec"
  "mattpocock|grilling|https://github.com/mattpocock/skills|skills/productivity/grilling"
  "mattpocock|grill-with-docs|https://github.com/mattpocock/skills|skills/engineering/grill-with-docs"
  "mattpocock|research|https://github.com/mattpocock/skills|skills/engineering/research"
  "mattpocock|triage|https://github.com/mattpocock/skills|skills/engineering/triage"
  "agent-almanac|create-work-breakdown-structure|https://github.com/pjt222/agent-almanac|skills/create-work-breakdown-structure"
  "tt-a1i|archify|https://github.com/tt-a1i/archify|archify"
)

SKILL_SRC_DIR="${HOME}/.cache/agent-vendor-src"
VENDOR_OK=0
VENDOR_MISSING=0

if [ "${1:-}" = "--refresh-vendored-skills" ]; then
  echo "🔄 Refreshing vendored skills from upstream sources..."
  for entry in "${VENDOR_SOURCES[@]}"; do
    IFS='|' read -r ORIGIN NAME REPO SRC_PATH <<< "${entry}"
    TMP_REPO="${SKILL_SRC_DIR}/$(basename "${REPO}")"
    git clone --depth 1 --quiet "${REPO}" "${TMP_REPO}" 2>/dev/null || \
      git -C "${TMP_REPO}" pull --quiet 2>/dev/null || true
    if [ -f "${TMP_REPO}/${SRC_PATH}/SKILL.md" ]; then
      rm -rf "${REPO_DIR}/skills/${NAME}"
      mkdir -p "${REPO_DIR}/skills/${NAME}"
      cp -a "${TMP_REPO}/${SRC_PATH}/." "${REPO_DIR}/skills/${NAME}/"
      [ -d "${REPO_DIR}/skills/${NAME}/bin" ] && chmod +x "${REPO_DIR}/skills/${NAME}/bin"/*.mjs 2>/dev/null || true
      echo "  ✅ ${NAME} ← ${REPO} (${SRC_PATH})"
    else
      echo "  ❌ ${NAME}: source not found in ${REPO}"
    fi
  done
fi

echo "🔎 Verifying vendored skills..."
for entry in "${VENDOR_SOURCES[@]}"; do
  IFS='|' read -r ORIGIN NAME REPO SRC_PATH <<< "${entry}"
  if [ ! -f "${REPO_DIR}/skills/${NAME}/SKILL.md" ]; then
    echo "  📥 Installing missing vendored skill ${NAME} from ${REPO}..."
    mkdir -p "${SKILL_SRC_DIR}"
    TMP_REPO="${SKILL_SRC_DIR}/$(basename "${REPO}")"
    git clone --depth 1 --quiet "${REPO}" "${TMP_REPO}" 2>/dev/null || \
      git -C "${TMP_REPO}" pull --quiet 2>/dev/null || true
    if [ -f "${TMP_REPO}/${SRC_PATH}/SKILL.md" ]; then
      mkdir -p "${REPO_DIR}/skills/${NAME}"
      cp -a "${TMP_REPO}/${SRC_PATH}/." "${REPO_DIR}/skills/${NAME}/"
      [ -d "${REPO_DIR}/skills/${NAME}/bin" ] && chmod +x "${REPO_DIR}/skills/${NAME}/bin"/*.mjs 2>/dev/null || true
    fi
  fi
  if [ -f "${REPO_DIR}/skills/${NAME}/SKILL.md" ]; then
    VENDOR_OK=$((VENDOR_OK + 1))
  else
    echo "  ❌ MISSING ${NAME} (run: setup.sh --refresh-vendored-skills)"
    VENDOR_MISSING=$((VENDOR_MISSING + 1))
  fi
done
# Custom skills committed to this repo (no upstream source; never refreshed):
# estimate-costs, to-tickets (personalized with GitHub mechanics), ask-matt
# (personalized to reference /plan-phases-implement), plan-phases-create,
# plan-phases-implement, constitution/checklist/analyze/converge (adapted from
# github/spec-kit, standalone, no specify CLI). implement was removed
# (absorbed into plan-phases-implement).
CUSTOM_SKILLS=(
  "estimate-costs"
  "to-tickets"
  "ask-matt"
  "plan-phases-create"
  "plan-phases-implement"
  "constitution"
  "checklist"
  "analyze"
  "converge"
)
for skill in "${CUSTOM_SKILLS[@]}"; do
  if [ -f "${REPO_DIR}/skills/${skill}/SKILL.md" ]; then
    VENDOR_OK=$((VENDOR_OK + 1))
  else
    echo "  ❌ MISSING ${skill} (custom skill)"
    VENDOR_MISSING=$((VENDOR_MISSING + 1))
  fi
done
if [ "${VENDOR_MISSING}" -gt 0 ]; then
  echo "⚠️  ${VENDOR_MISSING} vendored skill(s) missing."
fi

# 5. Secret leak check on committed configs
echo "🔍 Scanning config files for hardcoded secrets..."
SECRET_PATTERNS=(
  "ctx7sk-"
  "github_pat_"
  "ghp_"
  "gho_"
  "sk-[A-Za-z0-9]"
  "Bearer [A-Za-z0-9]"
)
FOUND_SECRET=0
for cfg in "${REPO_DIR}/mcp.json" "${REPO_DIR}/opencode.jsonc"; do
  [ -f "${cfg}" ] || continue
  for pat in "${SECRET_PATTERNS[@]}"; do
    if grep -qE "${pat}" "${cfg}"; then
      echo "  ❌ Possible hardcoded secret '${pat}' in ${cfg}"
      FOUND_SECRET=1
    fi
  done
done
if [ "${FOUND_SECRET}" -eq 0 ]; then
  echo "  ✅ No hardcoded secrets in committed configs."
else
  echo "⚠️  Review and remove hardcoded secrets before committing."
fi

# 6. MCP runtime check: launch each server and require an MCP `initialize`
# handshake. Checking that the symlink exists is not enough: a launcher can be
# present and still fail (exit 127) when its interpreter is missing.
echo "🔎 Verifying MCP servers answer an MCP initialize handshake..."
MCP_BINS_VERIFY=(
  "codebase-memory-mcp"
  "codegraph-mcp"
  "context7-mcp"
  "mcp-server-github"
  "mcp-server-memory"
  "playwright-mcp"
)

# The GitHub server expects GITHUB_PERSONAL_ACCESS_TOKEN; .env only defines GITHUB_TOKEN.
export GITHUB_PERSONAL_ACCESS_TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN:-${GITHUB_TOKEN:-}}"

MCP_SMOKE_JS="${TMPDIR:-/tmp}/opencode-mcp-smoke-$$.cjs"
cat > "${MCP_SMOKE_JS}" <<'MCP_SMOKE_EOF'
const { spawn } = require("node:child_process");
const bin = process.argv[2];
const request =
  JSON.stringify({
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "setup-smoke", version: "1.0.0" },
    },
  }) + "\n";
const child = spawn(bin, [], { env: process.env, stdio: ["pipe", "pipe", "pipe"] });
let buf = "";
let stderr = "";
const fail = (reason) => {
  process.stderr.write(reason.split("\n")[0].slice(0, 160));
  process.exit(1);
};
const timer = setTimeout(() => fail("timeout waiting for initialize response"), 25000);
child.stdout.on("data", (chunk) => {
  buf += chunk.toString();
  const line = buf.split("\n").find((l) => l.includes('"result"') || l.includes('"error"'));
  if (!line) return;
  clearTimeout(timer);
  try {
    const msg = JSON.parse(line);
    if (msg.error) fail("rpc error: " + msg.error.message);
    else process.stdout.write((msg.result?.serverInfo?.name ?? "ok") + " " + (msg.result?.serverInfo?.version ?? ""));
  } catch {
    fail("unparseable response");
  }
  child.kill("SIGKILL");
  process.exit(0);
});
child.stderr.on("data", (chunk) => (stderr += chunk.toString()));
child.on("error", (err) => fail(err.message));
child.on("exit", (code) => {
  clearTimeout(timer);
  fail(stderr.trim() || "process exited with code " + code);
});
child.stdin.on("error", () => {});
child.stdin.write(request);
MCP_SMOKE_EOF
trap 'rm -f "${MCP_SMOKE_JS}"' EXIT

MCP_OK=0
MCP_FAIL=0
if [ "${NODE_AVAILABLE}" -eq 0 ]; then
  echo "  ⏭️  Skipped: no usable Node runtime (${NODE_REASON})."
  echo "     All ${#MCP_BINS_VERIFY[@]} MCP servers fail until Node is installed — follow the steps printed above."
  MCP_FAIL="${#MCP_BINS_VERIFY[@]}"
fi
for bin in "${MCP_BINS_VERIFY[@]}"; do
  if [ "${NODE_AVAILABLE}" -eq 0 ]; then
    break
  fi
  if [ ! -e "${HOME}/.local/bin/${bin}" ]; then
    echo "  ❌ FAIL  ${bin} (not installed; re-run setup.sh)"
    MCP_FAIL=$((MCP_FAIL + 1))
    continue
  fi
  if MCP_RESPONSE="$(node "${MCP_SMOKE_JS}" "${HOME}/.local/bin/${bin}" 2>&1)"; then
    echo "  ✅ OK    ${bin} (${MCP_RESPONSE})"
    MCP_OK=$((MCP_OK + 1))
  else
    echo "  ❌ FAIL  ${bin} (no MCP handshake)"
    [ -n "${MCP_RESPONSE}" ] && echo "       ↳ ${MCP_RESPONSE}"
    MCP_FAIL=$((MCP_FAIL + 1))
  fi
done
if [ "${MCP_FAIL}" -gt 0 ]; then
  echo "⚠️  ${MCP_FAIL} MCP server(s) failed to start. Fix the cause above and re-run setup.sh."
fi

# 7. Summary & Verification
SKILL_COUNT=$(ls -d "${REPO_DIR}/skills"/*/ 2>/dev/null | wc -l || echo "0")

echo ""
echo "======================================================================"
if [ "${NODE_AVAILABLE}" -eq 1 ]; then
  echo "🎉 Setup Complete!"
else
  echo "⚠️  Setup finished with errors — ACTION REQUIRED below"
fi
echo "----------------------------------------------------------------------"
echo "  • Total Curated Skills: ${SKILL_COUNT}"
echo "  • Vendored Planning Skills OK/MISSING: ${VENDOR_OK}/${VENDOR_MISSING}"
echo "  • MCP Bins OK/FAIL:     ${MCP_OK}/${MCP_FAIL}"
echo "  • OpenCode Config:      ${OPENCODE_CONFIG_DIR}/opencode.jsonc"
echo "  • OpenCode DCP:         ${OPENCODE_CONFIG_DIR}/dcp.jsonc"
echo "  • OpenCode TUI:         ${OPENCODE_CONFIG_DIR}/tui.json"
echo "  • Playwright Browser:   ${PLAYWRIGHT_BROWSER}"
echo "  • Memoria Local:        ${MEMORY_FILE_PATH:-~/.local/share/opencode/memory/<user>.jsonl}"
echo "  • OpenCode Directives:  ${OPENCODE_CONFIG_DIR}/AGENTS.md"
echo "  • Antigravity Skills:   ${GEMINI_CONFIG_DIR}/skills"
echo "  • Antigravity Rules:    ${GEMINI_CONFIG_DIR}/AGENTS.md"
echo "  • Antigravity MCPs:     ${GEMINI_CONFIG_DIR}/mcp_config.json"
echo "  • Antigravity Hooks:    ${GEMINI_CONFIG_DIR}/hooks.json"
echo "  • MCPs Configured:      context7, codegraph, codebase-memory, github, memory, playwright"
echo "----------------------------------------------------------------------"
echo "  💡 Planning pipeline: wayfinder → setup-matt-pocock-skills → to-spec →"
echo "     create-work-breakdown-structure → estimate-costs → to-tickets"
echo "  📐 Phase planning:    plan-phases-create → plan-phases-implement"
echo "  🔄 Update vendored skills:  setup.sh --refresh-vendored-skills"
echo "  🛠️  Per-repo init: run /setup-matt-pocock-skills once in each repo"
echo "======================================================================"

if [ "${NODE_AVAILABLE}" -eq 0 ]; then
  echo ""
  echo "⚠️  ACTION REQUIRED — setup is incomplete (${NODE_REASON})."
  echo "   Re-run setup.sh once these steps are done:"
  echo "     1) mise use -g node@lts   # install mise first: brew install mise | curl https://mise.run | sh"
  echo "     2) exec zsh && node -v      # must print a version, e.g. v26.13.0"
  echo "     3) cd ~/.agent && ./setup.sh"
  exit 1
fi

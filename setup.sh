#!/usr/bin/env bash

# ==============================================================================
# Lumusitech AI Workspace - Machine Setup Script
# ==============================================================================
# Idempotent setup script to link custom skills, MCP configurations, and global
# agent directives for OpenCode and Antigravity (TUI / IDE) across machines.
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Initializing AI Workspace Setup from: ${REPO_DIR}"

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
GEMINI_CONFIG_DIR="${HOME}/.gemini/config"
mkdir -p "${GEMINI_CONFIG_DIR}"

echo "🔗 Linking skills to Antigravity global config (${GEMINI_CONFIG_DIR}/skills)..."
ln -sfn "${REPO_DIR}/skills" "${GEMINI_CONFIG_DIR}/skills"

echo "🔗 Linking mcp.json to Antigravity global config (${GEMINI_CONFIG_DIR}/mcp.json)..."
ln -sfn "${REPO_DIR}/mcp.json" "${GEMINI_CONFIG_DIR}/mcp.json"

echo "🔗 Linking GEMINI.md to Antigravity global config (${GEMINI_CONFIG_DIR}/GEMINI.md)..."
ln -sfn "${REPO_DIR}/GEMINI.md" "${GEMINI_CONFIG_DIR}/GEMINI.md"

# Remove legacy hardcoded backup tokens if existing
if [ -f "${GEMINI_CONFIG_DIR}/mcp_config.json.backup" ]; then
    rm -f "${GEMINI_CONFIG_DIR}/mcp_config.json.backup"
fi

# Remove legacy hardcoded secrets from Antigravity config
if [ -f "${GEMINI_CONFIG_DIR}/mcp_config.json" ]; then
    echo "🧹 Removing legacy ${GEMINI_CONFIG_DIR}/mcp_config.json (hardcoded secrets)..."
    rm -f "${GEMINI_CONFIG_DIR}/mcp_config.json"
fi
if [ -f "${HOME}/.gemini/settings.json" ]; then
    echo "🧹 Cleaning hardcoded secrets from ${HOME}/.gemini/settings.json..."
    python3 - "${HOME}/.gemini/settings.json" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
changed = False
if "mcpServers" in data:
    for server in data["mcpServers"].values():
        if isinstance(server, dict) and "headers" in server:
            server["headers"] = {}
            changed = True
if changed:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print("  ✅ Secrets removed from settings.json")
else:
    print("  ℹ️  settings.json: no hardcoded MCP secrets found")
PYEOF
fi

# Link Antigravity/Gemini extension (best-effort; Antigravity bundles its own CLI)
GEMINI_EXT_DIR="${HOME}/.gemini/extensions"
mkdir -p "${GEMINI_EXT_DIR}"
ln -sfn "${REPO_DIR}/extensions/lumusitech" "${GEMINI_EXT_DIR}/lumusitech"
echo "🔗 Linked Antigravity/Gemini extension (${GEMINI_EXT_DIR}/lumusitech)"

# 3. OpenCode Configuration Links (~/.config/opencode)
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
mkdir -p "${OPENCODE_CONFIG_DIR}"

echo "🔗 Linking opencode.jsonc to OpenCode config (${OPENCODE_CONFIG_DIR}/opencode.jsonc)..."
ln -sfn "${REPO_DIR}/opencode.jsonc" "${OPENCODE_CONFIG_DIR}/opencode.jsonc"

echo "🔗 Linking AGENTS.md to OpenCode config (${OPENCODE_CONFIG_DIR}/AGENTS.md)..."
ln -sfn "${REPO_DIR}/AGENTS.md" "${OPENCODE_CONFIG_DIR}/AGENTS.md"

echo "🔗 Linking opencode agents to OpenCode config (${OPENCODE_CONFIG_DIR}/agents)..."
mkdir -p "${OPENCODE_CONFIG_DIR}/agents"
for agent in "${REPO_DIR}"/agents/*.md; do
  [ -f "${agent}" ] || continue
  ln -sfn "${agent}" "${OPENCODE_CONFIG_DIR}/agents/$(basename "${agent}")"
done

echo "🔗 Linking opencode plugins to OpenCode config (${OPENCODE_CONFIG_DIR}/plugins)..."
ln -sfn "${REPO_DIR}/plugins" "${OPENCODE_CONFIG_DIR}/plugins"

# 4. Clean up legacy skill & temporary directories to prevent duplicate loading & save space
echo "🧹 Cleaning legacy paths (~/.agents, ~/.claude, ~/temp/antigravity-awesome-skills)..."
rm -rf "${HOME}/.agents"
rm -rf "${HOME}/.claude"
rm -rf "${HOME}/temp/antigravity-awesome-skills"

# 4b. Git credential helper fix (GITHUB_TOKEN vs gh OAuth token)
# gh auth git-credential prefers GITHUB_TOKEN/GH_TOKEN from the environment over
# the full OAuth token stored by `gh auth login`. A fine-grained PAT lacks the
# `Contents: write` permission needed to delete remote branches, breaking
# `git push --delete`. Force git to use gh's stored OAuth token.
if command -v gh >/dev/null 2>&1; then
    GH_BIN="$(command -v gh)"
    echo "🔧 Configuring git to use gh OAuth token (ignoring GITHUB_TOKEN/GH_TOKEN)..."
    git config --global credential.https://github.com.helper \
      "!env -u GITHUB_TOKEN -u GH_TOKEN ${GH_BIN} auth git-credential"
    git config --global credential.https://gist.github.com.helper \
      "!env -u GITHUB_TOKEN -u GH_TOKEN ${GH_BIN} auth git-credential"
    echo "  ✅ git credential helper: ${GH_BIN}"
else
    echo "⚠️  gh CLI not found. Skipping git credential helper config."
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
for cfg in "${REPO_DIR}/mcp.json" "${REPO_DIR}/opencode.jsonc" "${REPO_DIR}/extensions/lumusitech/gemini-extension.json"; do
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

# 6. MCP package availability check
echo "🔎 Verifying MCP npm packages..."
MCP_PACKAGES=(
  "@astudioplus/codegraph-mcp"
  "@upstash/context7-mcp"
  "@modelcontextprotocol/server-github"
  "@modelcontextprotocol/server-memory"
  "@playwright/mcp"
)
MCP_OK=0
MCP_FAIL=0
for pkg in "${MCP_PACKAGES[@]}"; do
  if npm view "${pkg}" version >/dev/null 2>&1; then
    echo "  ✅ OK    ${pkg}"
    MCP_OK=$((MCP_OK + 1))
  else
    echo "  ❌ FAIL  ${pkg} (not found in npm registry)"
    MCP_FAIL=$((MCP_FAIL + 1))
  fi
done
if [ "${MCP_FAIL}" -gt 0 ]; then
  echo "⚠️  ${MCP_FAIL} MCP package(s) missing. Check your npm registry access."
fi

# 7. Summary & Verification
SKILL_COUNT=$(ls -d "${REPO_DIR}/skills"/*/ 2>/dev/null | wc -l || echo "0")

echo ""
echo "======================================================================"
echo "🎉 Setup Complete!"
echo "----------------------------------------------------------------------"
echo "  • Total Curated Skills: ${SKILL_COUNT}"
echo "  • MCP Packages OK/FAIL: ${MCP_OK}/${MCP_FAIL}"
echo "  • OpenCode Config:      ${OPENCODE_CONFIG_DIR}/opencode.jsonc"
echo "  • OpenCode Directives:  ${OPENCODE_CONFIG_DIR}/AGENTS.md"
echo "  • Antigravity Skills:   ${GEMINI_CONFIG_DIR}/skills"
echo "  • Antigravity MCPs:     ${GEMINI_CONFIG_DIR}/mcp.json"
echo "  • MCPs Configured:      context7, codegraph, github, memory, playwright"
echo "======================================================================"

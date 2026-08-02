# 🧠 Lumusitech AI Workspace

> Centralized AI workspace: Streamlined curated skills (~95), custom stack skills (Angular 22+, Spring Boot 4.x, Java 21/25, MercadoPago), and 5 core MCP integrations (`context7`, `codegraph`, `github`, `memory`, `playwright`) synced seamlessly across macOS, Linux, and WSL2.

This repository serves as the single source of truth for **OpenCode** and **Antigravity (TUI / IDE)**. It enforces strict architectural patterns, modern framework standards, zero-token security, and uncompromised code quality.

---

## 🏗️ Core Engineering Directives

All AI agents in this workspace operate under strict directives defined in [`AGENTS.md`](file:///home/carludev/.agent/AGENTS.md):

1. **Code Quality & Architecture:** Strict adherence to **SOLID**, **KISS**, **SoC**, and **DRY**.
2. **TypeScript (Strict Mode):** Zero `any` policy.
3. **Modern Angular (v22+):** Zoneless by default (`provideExperimentalZonelessChangeDetection()`), Signal-driven state (`signal()`, `computed()`, `linkedSignal()`), and `resource()` API.
4. **Spring Boot (v4.x / 3.5 LTS) & Java (21/25 LTS):** Virtual Threads enabled by default (`spring.threads.virtual.enabled=true`), Spring AI integration, Declarative HTTP clients (`@HttpExchange`), and modern Java idioms.

---

## 🛠️ MCP (Model Context Protocol) Integrations

The workspace configures 5 MCP servers for both OpenCode and Antigravity. Each runs via `npx -y <package>` (auto-downloads and always uses the latest version):

| Server | npm package | Requires |
|---|---|---|
| `codegraph` | `@astudioplus/codegraph-mcp` | — (native binary per platform) |
| `context7` | `@upstash/context7-mcp` | — |
| `github` | `@modelcontextprotocol/server-github` | `GITHUB_TOKEN` loaded from `~/.agent/.env` |
| `memory` | `@modelcontextprotocol/server-memory` | — |
| `playwright` | `@playwright/mcp` | Chromium browser (auto-downloaded on first use) |

- **`context7`**: Official documentation lookup for libraries, frameworks, and SDKs.
- **`codegraph`**: Graph-based repository symbol search and dependency tracking.
- **`github`**: PR, issue, and workflow management authenticated via `{env:GITHUB_TOKEN}`.
- **`memory`**: Long-term persistent memory across chat sessions.
- **`playwright`**: End-to-end browser testing and UI visual inspection.

### Prerequisites per machine

- **Node.js 18+ and npm** — required by `npx`. Install via `nvm`, your distro package manager, or https://nodejs.org.
- **Bun** — used by OpenCode to install npm plugins declared in `opencode.jsonc` (`"plugin": [...]`). Install via `curl -fsSL https://bun.sh/install | bash` or your package manager.
- **Playwright Chromium** — the `@playwright/mcp` server downloads Chromium to `~/.cache/ms-playwright/` automatically on first use. If it ever needs reinstalling: `npx playwright install chromium`.
- **GitHub token** — `github` MCP requires `GITHUB_TOKEN`; see [Loading Credentials](#-loading-credentials-for-mcp-servers) below.

`setup.sh` verifies all 5 npm packages exist on the machine after setup and reports any that are missing.

---

## 📂 Repository Structure

```text
~/.agent/
├── skills/                 # ~95 curated skills + 4 custom stack skills
├── skills.json             # Antigravity explicit skill discovery entry (~/.agent/skills)
├── hooks.json              # Antigravity lifecycle hooks (env-protection, notifications)
├── hooks/                  # Hook scripts (env-protection.sh, notify.sh)
├── agents/                 # OpenCode custom agents (arquitecto.md, ...)
├── plugins/                # OpenCode custom plugins (env-protection, notifications, ...)
├── extensions/lumusitech/  # Antigravity / Gemini CLI extension (gemini-extension.json)
├── memory.jsonl            # MCP memory knowledge graph (shared across machines via git)
├── AGENTS.md               # Global directives for OpenCode agents
├── GEMINI.md               # Global directives for Gemini CLI / Antigravity
├── opencode.jsonc          # OpenCode config: MCPs + npm plugins + skills paths
├── mcp.json                # Antigravity shared MCP declarations
├── .env.template           # Template for environment variables (GITHUB_TOKEN, etc.)
├── .env                    # Local credentials file (ignored by Git)
├── setup.sh                # Portable setup script for any machine
└── README.md               # You are here
```

---

## 🔌 Plugins & Extensions

### OpenCode plugins

Custom local plugins live in `~/.agent/plugins/` and are auto-loaded by OpenCode via symlink (`~/.config/opencode/plugins`). Each file is an ESM module exporting a plugin:

| Plugin | Hook | Purpose |
|---|---|---|
| `env-protection.js` | `tool.execute.before` | Blocks reads/writes of `.env` files to prevent secret leaks |
| `notifications.js` | `event` | Native desktop notification when a session goes idle |
| `inject-env.js` | `shell.env` | Loads `~/.agent/.env` into every agent shell |
| `context-compaction.js` | `experimental.session.compacting` | Preserves task state across session compaction |

Third-party npm plugins are declared in `opencode.jsonc` under `"plugin"`:
- `@tarquinen/opencode-dcp` — prunes obsolete tool outputs from context (saves tokens)
- `@cortexkit/opencode-magic-context` — cross-session memory and context management

### Antigravity / Gemini CLI extension

`extensions/lumusitech/gemini-extension.json` exposes the 5 shared MCP servers to Gemini CLI / Antigravity and points `contextFileName` at `GEMINI.md`. It is linked via `~/.gemini/extensions/lumusitech`. The MCP servers are also declared in `mcp.json` (linked to `~/.gemini/config/mcp.json`) for broad compatibility.

Antigravity discovers the shared skills through **two redundant mechanisms** (double safety net):

- The `skills` symlink at `~/.gemini/config/skills` → `~/.agent/skills`
- An explicit `skills.json` at `~/.gemini/config/skills.json` declaring `{ "entries": [{ "path": "~/.agent/skills" }] }`

### Antigravity lifecycle hooks

`hooks.json` (linked to `~/.gemini/config/hooks.json`) ports two of the OpenCode custom plugins to Antigravity's hook system. Hooks receive a JSON payload on stdin and must emit a JSON result on stdout.

| Hook | Event | Script | Behaviour |
|---|---|---|---|
| env-protection | `PreToolUse` (matcher `.*`) | `hooks/env-protection.sh` | Denies file tools (`view_file`, `edit_file`, ...) targeting `.env` paths and shell commands referencing `.env` |
| notifications | `Stop` | `hooks/notify.sh` | Sends a native desktop notification when the loop stops |

`inject-env` and `context-compaction` remain **OpenCode-only** — they rely on the OpenCode plugin API (`shell.env`, `experimental.session.compacting`) which has no Antigravity equivalent.

### Extension differences: OpenCode vs Antigravity

| Capability | OpenCode | Antigravity / Gemini |
|---|---|---|
| Skills discovery | `skills.paths` in `opencode.jsonc` | `~/.gemini/config/skills` symlink + `skills.json` |
| MCP servers | `mcp` in `opencode.jsonc` | `mcp.json` + `gemini-extension.json` |
| Global directives | `AGENTS.md` | `GEMINI.md` |
| Custom agents | `~/.config/opencode/agents/*.md` | Not supported (CLI/IDE rely on hooks + MCP) |
| Plugins | JS plugins (`plugins/`) + npm plugins | Not supported — use `hooks.json` |
| Lifecycle hooks | `tool.execute.*`, `event`, `shell.env`, ... | `hooks.json` (`PreToolUse`, `Stop`, ...) |

### MCP Memory sync across machines

`memory.jsonl` stores the MCP memory server's knowledge graph (entities, relations, observations). Both OpenCode and Antigravity are configured to use `~/.agent/memory.jsonl` via the `MEMORY_FILE_PATH` environment variable.

Since the file lives inside the repo, it is version-controlled and shared across machines via git:

```bash
# After a work session, commit memory changes
cd ~/.agent && git add memory.jsonl && git commit -m "chore: sync memory" && git push

# On the other machine, pull before starting work
cd ~/.agent && git pull
```

> **Note:** Only one machine should be active at a time to avoid merge conflicts. The JSONL format makes conflicts hard to resolve automatically.

### OpenCode custom agents

Files in `~/.agent/agents/` are symlinked into `~/.config/opencode/agents/`. Each agent is a Markdown file with frontmatter (`description`, `mode`, `permission`).

---

## 🚀 Machine Setup Guide

To sync this workspace to a new machine:

1. **Clone the repository:**
   ```bash
   git clone git@github.com:lumusitech/AI.join ~/.agent
   cd ~/.agent
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.template .env
   # Edit .env and set your GITHUB_TOKEN and tokens
   ```

3. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

This script will automatically configure OpenCode (`~/.config/opencode/opencode.jsonc`) and Antigravity (`~/.gemini/config/skills` & `~/.gemini/config/mcp.json`) and clean up legacy paths.

---

## 🔑 Loading Credentials for MCP Servers

MCP servers that require authentication (e.g. `github`) reference tokens through environment variables in `opencode.jsonc`, like `{env:GITHUB_TOKEN}`. OpenCode reads **process environment variables**, not the `.env` file directly — so merely having `GITHUB_TOKEN` in `~/.agent/.env` is **not enough** for the MCP server to pick it up.

`setup.sh` sources `.env` only within its own execution, so it never persists into your shell. You must load `~/.agent/.env` into your shell profile so every new terminal (and every app launched from it, including OpenCode) has the tokens.

### Add to your shell profile

**Zsh** (macOS default, Ubuntu/Debian with zsh, WSL2):

```bash
# Load ~/.agent/.env credentials (GITHUB_TOKEN, etc.) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    source "$HOME/.agent/.env"
    set +a
fi
```

Add the block above to `~/.zshrc`.

**Bash** (Ubuntu/Debian default, WSL2 default):

```bash
# Load ~/.agent/.env credentials (GITHUB_TOKEN, etc.) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    source "$HOME/.agent/.env"
    set +a
fi
```

Add the block above to `~/.bashrc`.

### Verify

After adding the block, open a **new terminal** and run:

```bash
echo "GITHUB_TOKEN: ${GITHUB_TOKEN:+set (len=${#GITHUB_TOKEN})}${GITHUB_TOKEN:-not set}"
```

If it prints `set`, your MCP servers will have access. **Important:** OpenCode must be restarted from a terminal where the variable is loaded for the MCP servers to use it.

### ⚠️ `GITHUB_TOKEN` vs `git push --delete` (important)

Once `GITHUB_TOKEN` is exported in your shell, the GitHub CLI credential helper **prefers it over the full OAuth token** stored by `gh auth login`. If your `.env` uses a **fine-grained PAT** (`github_pat_...`), that token often lacks the `Contents: write` permission required to delete remote branches, so `git push --delete origin <branch>` fails with:

```
remote: Permission to <user>/<repo>.git denied to <user>.
```

**Fix:** make git ignore `GITHUB_TOKEN`/`GH_TOKEN` and always use gh's stored OAuth token:

```bash
git config --global credential.https://github.com.helper \
  '!env -u GITHUB_TOKEN -u GH_TOKEN gh auth git-credential'
git config --global credential.https://gist.github.com.helper \
  '!env -u GITHUB_TOKEN -u GH_TOKEN gh auth git-credential'
```

> **Automatic:** `setup.sh` applies this fix for you on every machine (it resolves the real `gh` binary path and configures both `github.com` and `gist.github.com`). You only need the manual commands above if you're not running the setup script.

After applying, verify in a shell that loads `.env`:

```bash
# in a new terminal where GITHUB_TOKEN is set
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
# expect username=lumusitech and password=gho_... (NOT github_pat_...)
```

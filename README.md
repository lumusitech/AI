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
- **Playwright Chromium** — the `@playwright/mcp` server downloads Chromium to `~/.cache/ms-playwright/` automatically on first use. If it ever needs reinstalling: `npx playwright install chromium`.
- **GitHub token** — `github` MCP requires `GITHUB_TOKEN`; see [Loading Credentials](#-loading-credentials-for-mcp-servers) below.

`setup.sh` verifies all 5 npm packages exist on the machine after setup and reports any that are missing.

---

## 📂 Repository Structure

```text
~/.agent/
├── skills/                 # ~95 curated skills + 4 custom stack skills
├── AGENTS.md               # Global directives and behavioral rules for agents
├── opencode.jsonc          # OpenCode configuration and MCP declarations
├── mcp.json                # Antigravity shared MCP declarations
├── .env.template           # Template for environment variables (GITHUB_TOKEN, etc.)
├── .env                    # Local credentials file (ignored by Git)
├── setup.sh                # Portable setup script for any machine
└── README.md               # You are here
```

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

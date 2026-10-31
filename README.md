# 🧠 Lumusitech AI Workspace

> Centralized AI workspace: curated skills (count with `./scripts/skills-count.sh`), custom stack skills (Angular 22+, Spring Boot 4.x, Java 21/25, MercadoPago), planning skills (Wayfinder suite, WBS, estimate-costs, plan-phases), a `/tdd` test-first skill, `review` / `rdd` / `judgment-day` / `skill-creator` / `work-unit-commits` / `memory` / `conventional-commits` / `branch-pr` / `issue-creation` / `chained-pr` / `cognitive-doc-design` / `skill-improver` / `skill-registry`, and 6 core MCP integrations (`context7`, `codegraph`, `codebase-memory`, `github`, `memory`, `playwright`) synced seamlessly across macOS, Linux, WSL2, and Windows (PowerShell 7).

This repository serves as the single source of truth for **OpenCode** and **Antigravity (App / IDE / CLI)**. It enforces strict architectural patterns, modern framework standards, zero-token security, and uncompromised code quality.

### 🌐 Language convention

- **File and folder names:** always English, ASCII (`snake_case` or `kebab-case`). No accents, `ñ`, or spaces.
- **Code and technical configs** (skills, plugins, hooks, configs): English.
- **Docs and team-facing communication** (PR comments, commit messages, README sections aimed at the team): Spanish when the team reads Spanish.
- A new document picks one language for its whole content; do not mix within the same file.

Full directives in [`AGENTS.md`](file:///home/carludev/.agent/AGENTS.md).

---

## 🏗️ Core Engineering Directives

All AI agents in this workspace operate under strict directives defined in [`AGENTS.md`](file:///home/carludev/.agent/AGENTS.md):

1. **Code Quality & Architecture:** Strict adherence to **SOLID**, **KISS**, **SoC**, and **DRY**.
2. **TypeScript (Strict Mode):** Zero `any` policy.
3. **Modern Angular (v22+):** Zoneless by default (`provideExperimentalZonelessChangeDetection()`), Signal-driven state (`signal()`, `computed()`, `linkedSignal()`), and `resource()` API.
4. **Spring Boot (v4.x / 3.5 LTS) & Java (21/25 LTS):** Virtual Threads enabled by default (`spring.threads.virtual.enabled=true`), Spring AI integration, Declarative HTTP clients (`@HttpExchange`), and modern Java idioms.

---

## 🛠️ MCP (Model Context Protocol) Integrations

The workspace configures 6 MCP servers for OpenCode and Antigravity. They are **installed locally by `setup.sh` / `setup.ps1`** (from `package.json`, with `pnpm` → `corepack pnpm` → `npm` fallback) and exposed on `PATH` via `~/.local/bin`, so neither agent resolves or downloads packages from the registry at startup (no `npx -y`):

| Server | Binary | Package | Requires |
|---|---|---|---|
| `codegraph` | `codegraph-mcp` | `@astudioplus/codegraph-mcp` | — (native binary per platform) |
| `context7` | `context7-mcp` | `@upstash/context7-mcp` | — |
| `github` | `github-mcp-bridge` (wraps `mcp-server-github`) | `@modelcontextprotocol/server-github` | `gh auth login` (keyring); optional `GITHUB_MCP_TOKEN` |
| `memory` | `mcp-server-memory` | `@modelcontextprotocol/server-memory` | — |
| `playwright` | `playwright-mcp` | `@playwright/mcp` | Chrome (installed) **or** Chromium (auto-downloaded) |
| `codebase-memory-mcp` | `codebase-memory-mcp` | `codebase-memory-mcp` | — |

- **`context7`**: Official documentation lookup for libraries, frameworks, and SDKs.
- **`codegraph`**: Graph-based repository symbol search and dependency tracking.
- **`codebase-memory-mcp`**: Graph-based code intelligence for AI agents. Its native runtime is fetched by the package's own postinstall (same pattern as `codegraph`).
- **`github`**: PR, issue, and workflow management. Runs through `scripts/github-mcp-bridge.mjs`, which takes the token from the `gh` keyring (`gh auth token`) instead of a `.env` variable, so a stale PAT cannot break it.
- **`memory`**: Long-term persistent memory across chat sessions.
- **`playwright`**: End-to-end browser testing and UI visual inspection. Uses the **installed Chrome** when available, falling back to a downloaded **Chromium** otherwise (see below).

### Playwright browser (Chrome → Chromium fallback)

`setup.sh` / `setup.ps1` detect whether Google Chrome is installed and resolve the browser **automatically**, writing `PLAYWRIGHT_BROWSER` to `~/.agent/.env` (idempotent, re-resolved on every run):

- **macOS**: `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- **Linux**: `google-chrome`, `google-chrome-stable`, or `google-chrome-beta` on `PATH`
- **Windows**: `%ProgramFiles%\Google\Chrome\Application\chrome.exe`, the `(x86)` variant, or `%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe`

If Chrome is present the value is `chrome` (uses the system browser, no download); otherwise `chromium` (Playwright downloads Chromium to `~/.cache/ms-playwright/` on first use). The variable is consumed via `PLAYWRIGHT_MCP_BROWSER` (env var) in `opencode.jsonc` and `mcp.json`.

### Prerequisites per machine

- **Node.js 20+** — every MCP server is a Node process (the launchers in `node_modules/.bin` end in `exec node ...`). Install it with **mise**, the single toolchain manager for this workspace:
  ```bash
  mise use -g node@lts
  ```
  `setup.sh` links `node`, `npm` and `npx` into `~/.local/bin` (pointing at the mise shims), so the background service and GUI launches resolve the runtime even when they do not inherit your shell `PATH`, and upgrading with `mise use -g node@X` keeps working.
- **pnpm** (recommended) — used by `setup.sh` to install the local MCP packages. If absent, the setup falls back to `corepack enable pnpm`, then to `npm`.
- **Bun** — used by OpenCode to install the DCP plugin declared in `opencode.jsonc` (`"plugin": [...]`). Install via `curl -fsSL https://bun.sh/install | bash` or your package manager.
- **GitHub CLI (`gh`) logged in** — the `github` MCP runs through `scripts/github-mcp-bridge.mjs`, which resolves the token from `gh auth token` (system keyring) first, then falls back to `GITHUB_MCP_TOKEN`, then to `GITHUB_PERSONAL_ACCESS_TOKEN`/`GITHUB_TOKEN`. A token in `.env` is optional and a stale one no longer breaks the bridge. Check with `gh auth status`.

`setup.sh` installs the MCP packages and then **starts each server and requires a real MCP `initialize` handshake**, so a missing runtime or a broken launcher fails loudly instead of being reported as a generic success.

---

## 🧠 Gestión de contexto

Los modelos empiezan a degradarse a partir de ~40-44% de su ventana de contexto (en un modelo de 1M, ~400k tokens). Por debajo de ese punto comprimir es innecesario y degrada el contexto útil; por encima se trabaja en la zona de degradación.

Para gestionarlo se usa **DCP** (`@tarquinen/opencode-dcp`) como guardrail, con la auto-compactación nativa desactivada (`compaction.auto: false`):

- **~40% del contexto** (`maxContextLimit: "40%"` en `dcp.jsonc`): DCP empieza a *empujar suavemente* al modelo a comprimir (`nudgeForce: "soft"`).
- **Pregunta al usuario:** OpenCode V2 no soporta `permission: "ask"` en DCP, así que `compress` usa `permission: "allow"` y la política de **pedir permiso antes de comprimir** se mantiene como regla del agente. El usuario decide comprimir o continuar (asumiendo el riesgo de degradación).
- **Sin compactado automático:** ni OpenCode (`compaction.auto: false`) ni DCP comprimen por su cuenta. La decisión siempre es del usuario.
- **Notificación:** `pruneNotification: "detailed"` informa en el chat cuando se poda contenido.

> **Por qué no se compacta antes:** `magic-context` tenía un fallback de ~128k que compactaba prematuramente en modelos de 1M. Se eliminó; DCP con el umbral del 40% es la única fuente de verdad para el contexto.

---

## 💸 Economía de tokens y caché

El coste de una sesión se divide en **prompt fijo** (system prompt + `AGENTS.md` + los tools MCP + las skills) y **trabajo** (lo que el agente realmente hace). El prompt fijo es grande, pero con **caché de prompt** deja de ser el problema.

### Enrutado a un único provider (stickiness de caché)

`opencode.jsonc` fija `provider.order: ["sail-research"]` con `allow_fallbacks: true`. Motivo: la caché de prompt de OpenRouter **no cruza providers** y su *sticky routing* **se desactiva con un `order` manual**, así que repartir la carga entre varios providers garantiza miss. Se eligió `sail-research` como el provider más barato en **turno caliente** para `deepseek/deepseek-v4.1-flash`: caché a 0.1x (~860 µ$ vs ~3.380 µ$ en frío, para 32k input + 2k output).

### Medición (la única fuente de verdad)

- **Dashboard:** OpenRouter → Activity → Overview (`Cache hit rate`, `Blended $/1M`).
- **Por generación:** `./scripts/measure-openrouter-cache.sh <generation_id>` — consulta `/api/v1/generation` y muestra `cached_tokens`, `cache_hit_pct`, `cache_discount` y `total_cost`. Requiere `OPENROUTER_API_KEY` en `~/.agent/.env`.

### Hallazgo (2026-10-22): **no podar por coste**

Medido en Activity: **14 peticiones, 1.91M tokens, $0.11, cache hit rate 92.2%**, blended **$0.06/1M**.

La caché **amortiza el prompt fijo** (~90% se lee a 0.1x). Por eso **no se podan los servidores MCP ni las skills por motivo de coste**: ahorraría céntimos y añadiría riesgo. Solo se justificaría podar por **presión de ventana de contexto** o **ruido en la selección de tools** — no por dinero.

El ahorro real está en el **trabajo**, no en el prompt fijo: el **modo ODD** de `AGENTS.md` (inline-first, delegar solo con una razón nombrable, sin artefactos para tareas pequeñas) evita sobre-delegación y documentos innecesarios.

### Skills: ocultar del modelo (si algún día hace falta)

OpenCode **ignora** `disable-model-invocation` (convención de Claude/Antigravity). Para sacar una skill del inventario que ve el modelo **sin** dejar de poder invocarla por nombre exacto: `metadata: { opencode/autoinvoke: "false" }` en su `SKILL.md`.

---

## 📂 Repository Structure

```text
~/.agent/
├── skills/                 # curated skills + custom stack + planning skills
│   ├── wayfinder/          # 🗺️ Wayfinder suite (Matt Pocock): wayfinder, setup-matt-pocock-skills,
│   │                       #    to-spec, grilling, grill-with-docs, research, triage
│   ├── ask-matt/           # 🧭 Router de skills (custom, referencia /plan-phases-implement)
│   ├── to-tickets/         # 🎫 Tickets con blocking edges (custom, con mecánicas GitHub)
│   ├── plan-phases-create/ # 📐 Planificación por fases: plan + contratos públicos (custom)
│   ├── plan-phases-implement/ # 🛠️ Implementa 1 fase por invocación + STOP (custom)
│   ├── create-work-breakdown-structure/  # WBS + WBS Dictionary (agent-almanac)
│   ├── estimate-costs/     # 📊 CBS bottom-up con rate card (skill custom)
│   └── ...
├── .config/rates/          # Global rate card default para estimate-costs
├── agents/                 # OpenCode custom agents (arquitecto.md, ...)
├── plugins/                # OpenCode custom plugins (env-protection, notifications, ...)
├── hooks/                  # Antigravity lifecycle hooks (env-protection, notifications)
├── scripts/                # memory-setup.{sh,ps1}: per-user memory path written to .env
│                           # skills-count.sh: prints current skill totals (no hardcoded counts)
│                           # measure-openrouter-cache.sh: auditoría de caché (cached_tokens, cache_discount)
├── .gitattributes          # LF line endings + binary markers (cross-platform hardening)
├── .editorconfig           # UTF-8 / LF / trailing-newline for editors
├── .github/workflows/      # CI: validates JSON/JSONC + rejects BOM/CRLF on PRs
├── AGENTS.md               # Global directives for OpenCode + Antigravity (single source of truth)
├── opencode.jsonc          # OpenCode config: MCPs (local bins) + DCP plugin + skills paths
├── dcp.jsonc               # DCP plugin config: 40% threshold, permission "allow"
├── mcp.json                # MCP servers source (Antigravity mcp_config.json is generated from it)
├── hooks.json              # Antigravity lifecycle hooks (linked to ~/.gemini/config/hooks.json)
├── tui.json                # OpenCode TUI config (scroll acceleration)
├── package.json            # Local MCP packages installed by setup.sh (pnpm/npm)
├── .env.template           # Template for environment variables (optional tokens, MCP paths)
├── .env                    # Local credentials file (ignored by Git)
├── setup.sh                # Portable setup script for Unix (macOS, Linux, WSL2)
├── setup.ps1               # Windows setup script (PowerShell 7)
├── setup.cmd               # Windows launcher (ExecutionPolicy bypass + pwsh check)
└── README.md               # You are here
```

### Cross-platform hardening

Config files move between macOS, Linux, WSL2 and Windows through git. Three safeguards keep them valid everywhere:

- **`.gitattributes`** forces LF line endings on checkout (a Windows default of `core.autocrlf=true` would otherwise rewrite them to CRLF) and keeps `.cmd`/`.bat` on CRLF.
- **`.editorconfig`** pins `UTF-8` + `LF` + trailing newline in editors, avoiding BOM/encoding drift.
- **`.github/workflows/validate-config.yml`** validates every `.json`/`.jsonc` and rejects UTF-8 BOM and CRLF in config/scripts/docs on every PR, so invalid JSON never merges.

---

## 🔌 Plugins & Extensions

### OpenCode plugins

Custom local plugins live in `~/.agent/plugins/` and are auto-loaded by OpenCode via symlink (`~/.config/opencode/plugins`). Each file is an ESM module exporting a plugin:

| Plugin | Hook | Purpose |
|---|---|---|
| `env-protection.js` | `tool.execute.before` | Blocks file tools on sensitive paths — `.env*`, `*.pem`, `*.key`, `.netrc`, dirs `.ssh`/`.credentials`/`.gnupg`/`secrets`/`keychains`, `.aws/credentials`, `.config/gh/hosts.yml` — plus destructive `rm -rf /` `rm -rf ~` and shell assignments (`export`/`$env:`/`setx`). Ported from gentle-ai's security deny-list |
| `notifications.js` | `event` | Native desktop notification when a session goes idle |
| `inject-env.js` | `shell.env` | Loads `~/.agent/.env` into every agent shell |
| `context-compaction.js` | `experimental.session.compacting` | Preserves task state across session compaction |

Third-party npm plugins are declared in `opencode.jsonc` under `"plugin"`:

- `@tarquinen/opencode-dcp` (pinned `@3.2.0`) — dynamic context pruning. Its `compress` tool replaces stale, closed conversation spans with technical summaries. Configured (see `dcp.jsonc`) to **nudge softly at ~40% of the model context** and to **ask the user** before compressing (agent policy; `compress.permission: "allow"` because OpenCode V2 rejects `"ask"`).

> **Removed:** `@cortexkit/opencode-magic-context` was removed. Its hardcoded ~128k fallback triggered premature compaction in 1M-token models and its auto-update-checker failed at startup. Context management is now handled solely by DCP (see [Gestión de contexto](#-gestión-de-contexto)).

### MCP Memory (per-user, local)

The MCP memory server stores its knowledge graph (entities, relations, observations) in a **per-user local file** that is **never committed to the repo**. The location is injected via the `MEMORY_FILE_PATH` environment variable (see `opencode.jsonc`):

- Unix: `~/.local/share/opencode/memory/<user>.jsonl`
- Windows: `C:/Users/<user>/.local/share/opencode/memory/<user>.jsonl`

`scripts/memory-setup.{sh,ps1}` detects your identity, writes `MEMORY_FILE_PATH` into `~/.agent/.env`, and ensures your shell/PowerShell profile loads it.

> **Why forward slashes on Windows?** opencode substitutes `{env:MEMORY_FILE_PATH}` in `opencode.jsonc` **verbatim** (without JSON-escaping the value). A Windows path with backslashes (`C:\Users\...`) would inject invalid JSON escape sequences and make opencode fail with `opencode.jsonc is not valid JSON(C)`. `memory-setup.ps1` therefore normalizes the path to forward slashes (`/`), which Windows, PowerShell and Node all accept.

To move the graph to another machine, use the `/memory-export` and `/memory-import` skills (a Markdown document with an embedded JSONL block) — the file itself is never synced via git.

**Convention (`/memory` skill).** Because the graph is per-user and shared across repos, two disciplines keep it trustworthy (ideas adapted from [Engram](https://github.com/Gentleman-Programming/engram) without its binary):

- **Project scoping** — derive a **project key** from the git remote (`owner/repo`, else the repo basename) and prefix every entity (`<project-key>:<entity>`); recall filtered to the current project unless cross-project recall is explicitly requested.
- **Staleness** — every observation records a **date + reference** (commit/path/symbol). On recall, **verify against current evidence**; a memory whose reference no longer matches is **suspicious context, not fact**.

### OpenCode custom agents

Files in `~/.agent/agents/` are symlinked into `~/.config/opencode/agents/`. Each agent is a Markdown file with frontmatter (`description`, `mode`, `permission`).

---

## 🛰️ Antigravity (App / IDE / CLI)

Google Antigravity shares the **same open Agent Skills standard** ([agentskills.io](https://agentskills.io/home)) as OpenCode, so this repo's skills, rules, MCP servers and hooks are reused as-is — no duplication. `setup.sh` / `setup.ps1` link everything into Antigravity's global config directory (`~/.gemini/config`), which the App and the standalone IDE read:

| Repo artifact | Antigravity link | Consumed by |
|---|---|---|
| `skills/` | `~/.gemini/config/skills` | App / IDE (global skills) |
| `AGENTS.md` | `~/.gemini/config/AGENTS.md` | App / IDE (global `always_on` rule) |
| `mcp.json` | `~/.gemini/config/mcp_config.json` *(generado)* | App / IDE (MCP servers) |
| `hooks.json` | `~/.gemini/config/hooks.json` | App / IDE (lifecycle hooks) |

Key points:

- **Skills** are auto-discovered and each one is exposed as a slash command (`/<skill-name>`). Antigravity frontmatter only needs `name` + `description`; `disable-model-invocation` is not part of its schema.
- **Rules:** instead of a duplicated `GEMINI.md`, the repo links `AGENTS.md` (the same file OpenCode reads) as an always-on global rule. Antigravity also supports modular rules in `~/.gemini/config/rules/*.md` (with a `trigger` frontmatter) and per-directory `AGENTS.md`.
- **MCP** uses the standard `mcpServers` schema. `setup.sh` / `setup.ps1` **generate** `mcp_config.json` from `mcp.json` with `MEMORY_FILE_PATH` and `PLAYWRIGHT_BROWSER` resolved, because Antigravity does not expand `${VAR}` placeholders.
- **Hooks** use Antigravity's native lifecycle events: `env-protection` runs on `PreToolUse` and `notifications` on `Stop`. On Windows, `setup.ps1` generates `hooks.json` from `hooks.windows.json` with absolute paths (Antigravity's hook shell cannot expand `~`).
- **CLI:** the Antigravity CLI (`agy`) reads global skills from `~/.gemini/antigravity-cli/skills` and plugins from `~/.gemini/antigravity-cli/plugins`; it can also install the repo as a plugin bundle (`agy plugin install <path>`).
- **Plugins:** the repo's own `plugins/` are OpenCode JS plugins (not portable). For a one-command install across Antigravity surfaces, the same skills/rules/MCP/hooks can be packaged as an Antigravity plugin (`plugin.json` + `skills/` + `rules/` + `mcp_config.json` + `hooks.json`).

> **Legacy removed:** `GEMINI.md`, `skills.json` (explicit discovery) and the `extensions/lumusitech` Gemini CLI extension are no longer used — Antigravity now auto-discovers skills, reads `AGENTS.md` as a rule, and takes MCP from `mcp_config.json`.

---

## 🚀 Machine Setup Guide

### Unix (macOS / Linux / WSL2)

To sync this workspace to a new machine:

1. **Clone the repository:**
   ```bash
   git clone git@github.com:lumusitech/AI.join ~/.agent
   cd ~/.agent
   ```

2. **Install the toolchain (Node via mise):**
   ```bash
   # Linux / WSL2: curl https://mise.run | sh     |     macOS: brew install mise
   mise use -g node@lts
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.template .env
   # Edit .env and set your tokens
   ```

4. **Authenticate the GitHub CLI** (the `github` MCP reads its token from the keyring):
   ```bash
   gh auth login
   gh auth status
   ```

5. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

This script will automatically configure OpenCode (`~/.config/opencode/opencode.jsonc`) and Antigravity (`~/.gemini/config/{skills,AGENTS.md,mcp_config.json,hooks.json}`) and clean up legacy paths.

> **WSL2 note:** a fresh WSL2 install usually does not put `~/.local/bin` on `PATH`, and that is where the MCP launchers and the `node`/`npm`/`npx` links live. `setup.sh` warns when it is missing — add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile and re-run it.
>
> **Reloading without restarting:** after fixing a runtime or token, reload MCP servers in the running service with `opencode api post /api/location/reload --data '{}'`.

### Updating an existing machine (macOS / Linux / WSL2)

```bash
cd ~/.agent
git pull --ff-only
mise install                                        # applies the versions pinned in ~/.config/mise/config.toml
./setup.sh                                          # re-links configs and verifies every MCP server end to end
opencode api post /api/location/reload --data '{}'   # reload MCP servers without restarting the service
```

`./setup.sh` exits with status `1` and prints a numbered `ACTION REQUIRED` block when Node cannot be found, instead of reporting a false success. On WSL2, confirm `~/.local/bin` is on `PATH` first (see the note above): the `node`/`npm`/`npx` links live there, and the background service resolves them from its inherited `PATH`.

GitHub authentication is read from the `gh` keyring, so `gh auth status` must show a logged-in account (`gh auth login` if not). If an older `.env` still defines `GITHUB_TOKEN`, remove that line: it shadows the keyring for `gh` and for git's credential helper (see [Why `GITHUB_TOKEN` must stay out of `.env`](#why-github_token-must-stay-out-of-env)). A stale PAT there no longer breaks the `github` MCP, because the bridge strips it from the environment it hands to `gh`.

### Windows (PowerShell 7)

> ⚠️ **PowerShell 7 (`pwsh`) is required** — the setup script does NOT run on Windows PowerShell 5.1. Install it from https://aka.ms/powershell or `winget install --id Microsoft.PowerShell --exact`.

Prerequisites: PowerShell 7, Git for Windows, Node.js 18+ (npm), Bun, GitHub CLI (`gh`). Missing pieces can be installed automatically by the setup with `-InstallPrerequisites`.

1. **Clone the repository:**
   ```powershell
   git clone git@github.com:lumusitech/AI.join "$HOME\.agent"
   cd "$HOME\.agent"
   ```

2. **Configure environment variables:**
   ```powershell
   Copy-Item .env.template .env
   # Edit .env (MEMORY_FILE_PATH, optional tokens)
   ```

3. **Run the setup script:**
   ```cmd
   setup.cmd
   ```
   (or directly: `pwsh -NoProfile -ExecutionPolicy Bypass -File setup.ps1`)

   Optional flags:
   - `setup.cmd -InstallPrerequisites` — installs missing Git/gh/Node/Bun via winget (idempotent: skips anything already installed).
   - `setup.cmd -ConfigureWindowsTerminal` — adds an "AI Workspace (pwsh 7)" profile to Windows Terminal and sets it as default (backs up `settings.json` first).
   - `setup.cmd --refresh-vendored-skills` — re-fetches vendored planning skills from upstream.

The script configures the same links as on Unix (`~/.config/opencode` and `~/.gemini/config`) and generates `~/.gemini/config/hooks.json` from `hooks.windows.json` with absolute paths.

**Links on Windows:** creating symbolic links requires Developer Mode (Settings → For developers) or an admin shell. `setup.ps1` detects the capability at startup: with symlink permission everything is linked live (a `git pull` propagates instantly); without it, directories use **junctions** (no admin needed) and files are **copied** — in that case re-run `setup.cmd` after every `git pull` to propagate updates.

**PowerShell profile:** the script adds a block to your pwsh profile (`$PROFILE`) that loads `~/.agent/.env` into every new terminal session, so OpenCode MCP servers see `MEMORY_FILE_PATH` and any optional tokens (the `github` MCP authenticates through the `gh` keyring, not this file):

```powershell
# >>> lumusitech agent env >>>
# Load ~/.agent/.env credentials (MEMORY_FILE_PATH, optional tokens) for opencode MCP servers
if (Test-Path "$HOME\.agent\.env") {
    Get-Content "$HOME\.agent\.env" | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim().Trim('"'), 'Process')
        }
    }
}
# <<< lumusitech agent env <<<
```

**Verify:** open a new terminal and run:

```powershell
if ($env:MEMORY_FILE_PATH) { "MEMORY_FILE_PATH: set" } else { "MEMORY_FILE_PATH: not set" }
gh auth status   # the github MCP takes its token from here
```

### Verify vendored skills (both platforms)

The setup also verifies the **13 planning skills** are present (8 vendored + 5 custom) and can re-fetch the vendored ones from upstream:

```bash
./setup.sh                          # verify + configure
./setup.sh --refresh-vendored-skills # re-clone mattpocock/skills + agent-almanac and copy updates
```

```powershell
setup.cmd                          # verify + configure
setup.cmd --refresh-vendored-skills # re-clone mattpocock/skills + agent-almanac and copy updates
```

Planning skills come from two upstream sources (MIT) plus custom skills committed to this repo:

| Source | Skills |
|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | wayfinder, setup-matt-pocock-skills, to-spec, grilling, grill-with-docs, research, triage |
| [pjt222/agent-almanac](https://github.com/pjt222/agent-almanac) | create-work-breakdown-structure |
| Custom (never refreshed) | estimate-costs (rate card CBS), to-tickets (con mecánicas GitHub), ask-matt (referencia `/plan-phases-implement`), plan-phases-create, plan-phases-implement |

> **Note:** `to-tickets` and `ask-matt` are vendored upstream but are **customized here**. They were removed from the refresh list so `--refresh-vendored-skills` never overwrites our adaptations.

---

## 🧭 Método de trabajo (ODD + review)

El flujo por defecto es **ODD** (ver la sección *Modo Operativo ODD* en `AGENTS.md`): read-only hasta que se pide un cambio, **inline-first**, delegar solo con una razón nombrable, y sin artefactos para trabajo pequeño. Este pipeline pesado queda **reservado** a esfuerzos multisesión.

Piezas de método (skills portadas de [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai), adaptadas a nuestro modelo skill-céntrico, sin su binario Go):

- **`/tdd`** — test-first: RED → GREEN → PRESERVE → REFACTOR, con un RED por regla y no-regresión por comando tocado.
- **`/work-unit-commits`** — commits por unidad de comportamiento (tests+docs con el código), listos para PRs encadenadas.
- **`/review`** — review **read-only** con lentes por riesgo: R1 risk, R2 readability, R3 reliability, R4 resilience. Reporta, nunca corrige.
- **`/rdd`** — Receipt-Driven Development: **congela el candidato** antes de revisarlo, profundidad por **riesgo** del candidato, y resultado **informacional** (no autoriza commit/push/PR/release).
- **`/judgment-day`** — review **adversarial doble ciego**: dos jueces read-only en paralelo sobre un objetivo congelado; solo se corrige lo confirmado por **ambos**; terminal `APPROVED | ESCALATED`.
- **`/skill-creator`** — autorar skills LLM-first.
- **`/chained-pr`** — partir cambios **>400 líneas** en stacked PRs o feature-branch chain, con diagrama de dependencias.
- **`/cognitive-doc-design`** — escribir docs que reducen carga cognitiva (lead with the answer, progressive disclosure, chunking, signposting).
- **`/skill-improver`** — auditar/refactorizar skills existentes (frontmatter, presupuesto de cuerpo, prosa → tablas de decisión).
- **`/skill-registry`** — índice compacto de skills (trigger → ruta) para delegación.

Git/PR, ancladas a **estándares abiertos y neutrales** (no a la taxonomía de un vendor):

- **`/conventional-commits`** — mensajes de commit según **Conventional Commits v1.0.0** (compatible con commitlint/semantic-release/changelog).
- **`/branch-pr`** — nombres de rama (**Conventional Branch**) y flujo de PR (**GitHub Flow**, título Conventional Commits, keywords estándar de GitHub `Closes/Fixes/Resolves #N` / `Refs #N`); comentarios de review con **Conventional Comments**.
- **`/issue-creation`** — issues con **GitHub Issue Forms/templates** como autoridad de formato, vocabulario de **labels por defecto de GitHub**, y triaje con Conventional Comments.

> Review y delivery son decisiones **separadas**: un review/veredicto **nunca** autoriza commit, push, PR o release. Eso sigue la política ordinaria del repo.

### Seguridad por defecto (deny-list)

El plugin `env-protection.js` no solo bloquea `.env`: bloquea el acceso a **claves y credenciales** (`.ssh`, `.credentials`, `.gnupg`, `secrets/`, `keychains`, `.aws/credentials`, `.config/gh/hosts.yml`, `*.pem`, `*.key`, `.netrc`) y comandos **destructivos** (`rm -rf /`, `rm -rf ~`). Portado de la deny-list de gentle-ai, ampliando nuestra protección previa (que solo cubría `.env`).

---

## 🗺️ Planning Workflow (Wayfinding + WBS + Costs)

> **Uso reservado** a esfuerzos multisesión genuinos (ver *Método de trabajo* arriba).

For work larger than one agent session, the pipeline goes **document → decisions → WBS → costs → tickets**:

1. **`/grill-with-docs`** — interview the functional document, leaving `CONTEXT.md` + ADRs.
2. **`/to-spec`** — conversation → spec in the tracker.
3. **`/create-work-breakdown-structure`** — deliverables → WBS + `WBS-DICTIONARY.md` (person-days per work package).
4. **`/estimate-costs`** — Cost Breakdown Structure using a **rate card**. The agent **never invents rates**: it resolves `<repo>/.config/rates/rate-card.json` → global `~/.agent/.config/rates/rate-card.json`, and flags `RATE MISSING` for unknown roles.
5. **`/to-tickets`** — executable tickets with blocking edges.

Before using the Wayfinder suite in a repo, run **`/setup-matt-pocock-skills`** once per repo to pick the issue tracker (GitHub by default, or local files) — it writes the *Wayfinding operations* section into the repo's `AGENTS.md`.

Wayfinder rules: **1 ticket per session**, tickets resolve **decisions** (not build slices), and refer to maps/tickets **by name**. See `AGENTS.md` for the full operating rules.

### 📐 Phase planning (Research → Plan → Implement)

For a single large task, once the plan/tickets exist, execute it phase by phase:

1. **`/plan-phases-create`** — interviews you, explores the codebase (delegated to subagents), and defines **vertical-slice phases with public contracts**. Optionally produces a `research.md` for large tasks. Writes `.agents/plans/{plan-name}/{plan-name}-plan.md` only after your approval.
2. **`/plan-phases-implement`** — implements **exactly one phase per invocation**, verifies (typecheck/lint/tests), updates the plan file, and **STOPs** suggesting 3 Spanish commit messages. Never commits or pushes automatically. If a step doesn't fit the plan, it returns to `/plan-phases-create` instead of forcing it.

---

## 🔑 Loading Credentials for MCP Servers

MCP servers that need values from your environment declare them in `opencode.jsonc` with the `{env:VAR}` syntax (see `memory` → `MEMORY_FILE_PATH` and `playwright` → `PLAYWRIGHT_BROWSER`). OpenCode reads **process environment variables**, not the `.env` file directly — so merely having a variable in `~/.agent/.env` is **not enough** for the MCP server to pick it up.

> The `github` server is the exception: it runs through `scripts/github-mcp-bridge.mjs` and takes its token from the `gh` keyring (`gh auth token`), falling back to `GITHUB_MCP_TOKEN` only when the keyring has no entry. Keep `GITHUB_TOKEN` **out** of `.env` (see below). The rest of the credentials (`MEMORY_FILE_PATH`, `PLAYWRIGHT_BROWSER`, other tokens) still need to be exported.

### Why `GITHUB_TOKEN` must stay out of `.env`

Sourcing `.env` with `set -a` exports every value to the whole session, and the GitHub CLI gives `GITHUB_TOKEN`/`GH_TOKEN` precedence over the OAuth token stored by `gh auth login`. A stale or fine-grained PAT there produces a confusing chain of failures:

| Symptom | Cause |
| --- | --- |
| `gh auth status` → `Failed to log in to github.com ... token` | `gh` validates the exported PAT instead of the keyring |
| `gh auth login` refuses, claiming you are already logged in | the exported variable wins, so it never offers a re-login |
| `git push` / `git push --delete` fail with `403` or `Bad credentials` | git's credential helper inherits the same PAT |
| `github` MCP tools returned `Bad credentials` (before the bridge) | the server was started with `GITHUB_PERSONAL_ACCESS_TOKEN={env:GITHUB_TOKEN}` |

How the current setup avoids all of it:

1. No GitHub token in `.env`; run `gh auth login` once per machine (the keyring is per machine, so WSL2 needs its own login).
2. `opencode.jsonc` runs `github-mcp-bridge`, which calls `gh auth token` with `GITHUB_TOKEN`, `GH_TOKEN` and `GITHUB_PERSONAL_ACCESS_TOKEN` stripped from the child environment, so a leftover PAT cannot poison it.
3. `setup.sh` points git at `gh auth git-credential` under `env -u GITHUB_TOKEN -u GH_TOKEN`, and warns at startup when either variable is exported.
4. `GITHUB_MCP_TOKEN` is the explicit override when you really need to force a specific token (CI, automation).

If a machine still has the line in `.env`, delete it and open a new terminal: existing shells keep the exported value until they are restarted.

`setup.sh` sources `.env` only within its own execution, so it never persists into your shell. You must load `~/.agent/.env` into your shell profile so every new terminal (and every app launched from it, including OpenCode) has the tokens.

### Add to your shell profile

**Zsh** (macOS default, Ubuntu/Debian with zsh, WSL2):

```bash
# Load ~/.agent/.env credentials (MEMORY_FILE_PATH, optional tokens) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    source "$HOME/.agent/.env"
    set +a
fi
```

Add the block above to `~/.zshrc`.

**Bash** (Ubuntu/Debian default, WSL2 default):

```bash
# Load ~/.agent/.env credentials (MEMORY_FILE_PATH, optional tokens) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    source "$HOME/.agent/.env"
    set +a
fi
```

Add the block above to `~/.bashrc`.

**PowerShell 7** (Windows):

```powershell
# >>> lumusitech agent env >>>
# Load ~/.agent/.env credentials (MEMORY_FILE_PATH, optional tokens) for opencode MCP servers
if (Test-Path "$HOME\.agent\.env") {
    Get-Content "$HOME\.agent\.env" | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim().Trim('"'), 'Process')
        }
    }
}
# <<< lumusitech agent env <<<
```

Add the block above to your PowerShell profile (run `notepad $PROFILE` in pwsh). `setup.ps1` does this automatically.

### Verify

After adding the block, open a **new terminal** and run:

```bash
echo "MEMORY_FILE_PATH: ${MEMORY_FILE_PATH:-not set}"
gh auth status   # the github MCP takes its token from here
```

```powershell
# PowerShell 7
if ($env:MEMORY_FILE_PATH) { "MEMORY_FILE_PATH: set" } else { "MEMORY_FILE_PATH: not set" }
gh auth status
```

If `MEMORY_FILE_PATH` is set and `gh auth status` shows a logged-in account, every MCP server has what it needs. **Important:** the background service inherits the environment it was started with, so start OpenCode from a terminal where these variables are loaded, or reload with `opencode api post /api/location/reload --data '{}'`.

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

> **Automatic:** `setup.sh` applies this fix for you on every machine (it resolves the real `gh` binary path and configures both `github.com` and `gist.github.com`). On Windows, `setup.ps1` applies the equivalent fix (an `unset`-based sh helper, since Git for Windows ships no `env`). You only need the manual commands above if you're not running the setup script.

After applying, verify in a shell that loads `.env`:

```bash
# in a new terminal where GITHUB_TOKEN is set
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
# expect username=lumusitech and password=gho_... (NOT github_pat_...)
```

#Requires -Version 7.0

# ==============================================================================
# Lumusitech AI Workspace - Machine Setup Script (Windows / PowerShell 7)
# ==============================================================================
# Idempotent setup script to link custom skills, MCP configurations, and global
# agent directives for OpenCode and Antigravity (TUI / IDE) on Windows.
# Mirrors ./setup.sh (Unix). Run with:
#   setup.cmd                              (recommended wrapper)
#   pwsh -NoProfile -ExecutionPolicy Bypass -File setup.ps1
# ==============================================================================

[CmdletBinding()]
param(
    # Optional: install missing prerequisites (git, gh, node, bun, pwsh) via winget.
    [switch]$InstallPrerequisites,
    # Optional: add/update the "AI Workspace (pwsh 7)" Windows Terminal profile.
    [switch]$ConfigureWindowsTerminal,
    # Optional: re-fetch vendored planning skills from upstream sources.
    [switch]$RefreshVendoredSkills
)

$ErrorActionPreference = 'Stop'

if (-not $IsWindows) {
    Write-Error "setup.ps1 is for native Windows PowerShell 7. In WSL2/Linux/macOS use ./setup.sh instead."
    exit 1
}

$REPO_DIR = $PSScriptRoot
Write-Host "🚀 Initializing AI Workspace Setup from: ${REPO_DIR}"

# Support both setup.ps1 --flag and -Flag style args
$RefreshVendored = $RefreshVendoredSkills -or
                   ($args -contains '--refresh-vendored-skills') -or
                   ($args -contains '-RefreshVendoredSkills')
$DoInstallPrereqs = $InstallPrerequisites -or
                    ($args -contains '-InstallPrerequisites') -or
                    ($args -contains '--install-prerequisites')
$DoConfigureWT = $ConfigureWindowsTerminal -or
                 ($args -contains '-ConfigureWindowsTerminal') -or
                 ($args -contains '--configure-windows-terminal')

# ==============================================================================
# Helpers
# ==============================================================================
$script:SymlinkCapable = $false

function Test-SymlinkCapability {
    # Creating symlinks on Windows requires Developer Mode or an elevated
    # process. Probe once with a throwaway link; remember the result.
    $testDir   = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-link-test-" + [guid]::NewGuid().ToString('N'))
    $targetDir = "${testDir}-target"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    try {
        New-Item -ItemType SymbolicLink -Path $testDir -Target $targetDir -Force -ErrorAction Stop | Out-Null
        $ok = Test-Path -LiteralPath $testDir
    } catch {
        $ok = $false
    } finally {
        Remove-Item -Path $testDir -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $targetDir -Force -Recurse -ErrorAction SilentlyContinue
    }
    return $ok
}

function Link-Dir {
    # Link-Dir -Path <link location> -Target <repo dir>
    # Symlink when permitted; Junction otherwise (works without admin).
    param([string]$Path, [string]$Target)

    $parent = Split-Path -Path $Path -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    $existing = Get-Item -Path $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        if ($existing.LinkType -in @('SymbolicLink', 'Junction')) {
            $resolved = $existing.Target
            if ($resolved -eq $Target) {
                Write-Host "✅ Already linked: ${Path}"
                return
            }
            Remove-Item -Path $Path -Force
        } else {
            Write-Warning "Replacing existing directory '${Path}' with link to repo (repo is source of truth)."
            Remove-Item -Path $Path -Force -Recurse
        }
    }

    if ($script:SymlinkCapable) {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null
        Write-Host "🔗 Linked (symlink): ${Path}"
    } else {
        New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null
        Write-Host "🔗 Linked (junction): ${Path}"
    }
}

function Link-File {
    # Link-File -Path <link location> -Source <repo file>
    # Symlink when permitted; plain copy otherwise (overwrites from the repo,
    # so a git pull propagates on the next run).
    param([string]$Path, [string]$Source)

    $parent = Split-Path -Path $Path -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    $existing = Get-Item -Path $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        if ($existing.LinkType) {
            $resolved = $existing.Target
            if ($resolved -eq $Source) {
                Write-Host "✅ Already linked: ${Path}"
                return
            }
            Remove-Item -Path $Path -Force
        } else {
            Write-Warning "Replacing existing file '${Path}' with repo copy (repo is source of truth)."
            Remove-Item -Path $Path -Force
        }
    }

    if ($script:SymlinkCapable) {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Source -Force | Out-Null
        Write-Host "🔗 Linked (symlink): ${Path}"
    } else {
        Copy-Item -Path $Source -Destination $Path -Force
        Write-Host "🔗 Copied (no symlink permission): ${Path}"
        Write-Warning "Re-run setup.ps1 after git pull to propagate repo updates into ${Path}."
    }
}

$script:SymlinkCapable = Test-SymlinkCapability
if ($script:SymlinkCapable) {
    Write-Host "🔗 Symlink support detected (Developer Mode / admin)."
} else {
    Write-Host "ℹ️  Symlinks not permitted: using junctions (dirs) and copies (files)."
    Write-Host "   Enable Developer Mode (Settings > For developers) for live links."
}

# ==============================================================================
# 0b. Optional: install missing prerequisites via winget (-InstallPrerequisites)
# ==============================================================================
function Install-WingetPackage {
    # Idempotent gate: skip when the tool is already on PATH, or already
    # registered in winget; install otherwise (user scope, silent).
    param([string]$Id, [string]$CommandName, [string]$DisplayName)

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "✅ ${DisplayName} already installed (${CommandName} in PATH)."
        return
    }
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        Write-Warning "winget not available; skipping ${DisplayName}."
        return
    }
    & winget list --id $Id --exact *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ${DisplayName} already installed (winget)."
        return
    }
    Write-Host "📦 Installing ${DisplayName} via winget..."
    & winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --scope user
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget failed to install ${Id} (exit ${LASTEXITCODE}). Install it manually and re-run setup."
    } else {
        Write-Host "  ✅ ${DisplayName} installed. Restart your terminal to refresh PATH."
    }
}

if ($DoInstallPrereqs) {
    Write-Host "📦 Checking prerequisites (winget)..."
    Install-WingetPackage -Id 'Git.Git' -CommandName 'git' -DisplayName 'Git for Windows'
    Install-WingetPackage -Id 'GitHub.cli' -CommandName 'gh' -DisplayName 'GitHub CLI'
    Install-WingetPackage -Id 'OpenJS.NodeJS.LTS' -CommandName 'node' -DisplayName 'Node.js LTS'
    Install-WingetPackage -Id 'Oven-sh.Bun' -CommandName 'bun' -DisplayName 'Bun'
    Install-WingetPackage -Id 'Microsoft.PowerShell' -CommandName 'pwsh' -DisplayName 'PowerShell 7'
}

# ==============================================================================
# 1. Environment & Credentials Setup
# ==============================================================================
$ENV_FILE = Join-Path $REPO_DIR '.env'
if (-not (Test-Path -LiteralPath $ENV_FILE)) {
    Write-Host "⚠️  .env file missing. Creating from .env.template..."
    Copy-Item -Path (Join-Path $REPO_DIR '.env.template') -Destination $ENV_FILE
    Write-Host "🔑 Please edit ${ENV_FILE} with your actual tokens (e.g., GITHUB_TOKEN)."
} else {
    Write-Host "✅ .env configuration file exists."
}

# ==============================================================================
# 2. Antigravity Configuration Links (~/.gemini/config)
# ==============================================================================
$GEMINI_CONFIG_DIR = Join-Path $HOME '.gemini\config'

Link-Dir -Path (Join-Path $GEMINI_CONFIG_DIR 'skills')     -Target (Join-Path $REPO_DIR 'skills')
Link-File -Path (Join-Path $GEMINI_CONFIG_DIR 'skills.json') -Source (Join-Path $REPO_DIR 'skills.json')
Link-File -Path (Join-Path $GEMINI_CONFIG_DIR 'GEMINI.md')   -Source (Join-Path $REPO_DIR 'GEMINI.md')
Link-File -Path (Join-Path $GEMINI_CONFIG_DIR 'mcp.json')    -Source (Join-Path $REPO_DIR 'mcp.json')

# hooks.json: generated with absolute Windows paths (Antigravity runs hook
# commands through a shell that cannot expand `~`). Written only when content
# changes so re-runs stay quiet.
$HOOKS_TEMPLATE = Join-Path $REPO_DIR 'hooks.windows.json'
$HOOKS_TARGET = Join-Path $GEMINI_CONFIG_DIR 'hooks.json'
if (Test-Path -LiteralPath $HOOKS_TEMPLATE) {
    $templateText = [System.IO.File]::ReadAllText($HOOKS_TEMPLATE)
    $escapedRepoDir = $REPO_DIR.Replace('\', '\\')
    $generated = $templateText.Replace('__REPO_DIR__', $escapedRepoDir)
    $existingText = if (Test-Path -LiteralPath $HOOKS_TARGET) {
        [System.IO.File]::ReadAllText($HOOKS_TARGET)
    } else { '' }
    if ($generated -ne $existingText) {
        New-Item -ItemType Directory -Path $GEMINI_CONFIG_DIR -Force | Out-Null
        [System.IO.File]::WriteAllText($HOOKS_TARGET, $generated, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "🔗 Generated ${HOOKS_TARGET} (pwsh hooks, absolute paths)"
    } else {
        Write-Host "✅ Already configured: ${HOOKS_TARGET}"
    }
} else {
    Write-Warning "hooks.windows.json not found; skipping hooks.json generation."
}

# Remove legacy hardcoded backup tokens if existing
Remove-Item -Path (Join-Path $GEMINI_CONFIG_DIR 'mcp_config.json.backup') -Force -ErrorAction SilentlyContinue

# Remove legacy hardcoded secrets from Antigravity config
if (Test-Path -LiteralPath (Join-Path $GEMINI_CONFIG_DIR 'mcp_config.json')) {
    Write-Host "🧹 Removing legacy $GEMINI_CONFIG_DIR\mcp_config.json (hardcoded secrets)..."
    Remove-Item -Path (Join-Path $GEMINI_CONFIG_DIR 'mcp_config.json') -Force
}

$SETTINGS_PATH = Join-Path $HOME '.gemini\settings.json'
if (Test-Path -LiteralPath $SETTINGS_PATH) {
    Write-Host "🧹 Cleaning hardcoded secrets from ${SETTINGS_PATH}..."
    try {
        $settings = Get-Content -LiteralPath $SETTINGS_PATH -Raw | ConvertFrom-Json
        $changed = $false
        $serversProp = $settings.PSObject.Properties['mcpServers']
        if ($null -ne $serversProp) {
            foreach ($server in $serversProp.Value.PSObject.Properties) {
                if ($server.Value -is [PSCustomObject]) {
                    $headersProp = $server.Value.PSObject.Properties['headers']
                    if ($null -ne $headersProp) {
                        $server.Value.headers = @{}
                        $changed = $true
                    }
                }
            }
        }
        if ($changed) {
            $settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SETTINGS_PATH -Encoding utf8NoBOM
            Write-Host "  ✅ Secrets removed from settings.json"
        } else {
            Write-Host "  ℹ️  settings.json: no hardcoded MCP secrets found"
        }
    } catch {
        Write-Warning "  Could not parse ${SETTINGS_PATH}; skipping secret cleanup."
    }
}

# Link Antigravity/Gemini extension (best-effort; Antigravity bundles its own CLI)
$GEMINI_EXT_DIR = Join-Path $HOME '.gemini\extensions'
Link-Dir -Path (Join-Path $GEMINI_EXT_DIR 'lumusitech') -Target (Join-Path $REPO_DIR 'extensions\lumusitech')

# ==============================================================================
# 3. OpenCode Configuration Links (~/.config/opencode)
# ==============================================================================
$OPENCODE_CONFIG_DIR = Join-Path $HOME '.config\opencode'

Link-File -Path (Join-Path $OPENCODE_CONFIG_DIR 'opencode.jsonc') -Source (Join-Path $REPO_DIR 'opencode.jsonc')
Link-File -Path (Join-Path $OPENCODE_CONFIG_DIR 'dcp.jsonc')      -Source (Join-Path $REPO_DIR 'dcp.jsonc')
Link-File -Path (Join-Path $OPENCODE_CONFIG_DIR 'tui.json')      -Source (Join-Path $REPO_DIR 'tui.json')
Link-File -Path (Join-Path $OPENCODE_CONFIG_DIR 'AGENTS.md')      -Source (Join-Path $REPO_DIR 'AGENTS.md')
Link-Dir  -Path (Join-Path $OPENCODE_CONFIG_DIR 'plugins')        -Target (Join-Path $REPO_DIR 'plugins')

$AGENTS_DIR = Join-Path $OPENCODE_CONFIG_DIR 'agents'
New-Item -ItemType Directory -Path $AGENTS_DIR -Force | Out-Null

# Clean orphan links pointing at agents no longer in the repo
Get-ChildItem -LiteralPath $AGENTS_DIR -Force | Where-Object { $_.LinkType } | ForEach-Object {
    $targetPath = $_.Target
    if ($targetPath -and -not (Test-Path -LiteralPath $targetPath)) {
        Write-Host "🧹 Removing orphan agent link $($_.Name)..."
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }
}

# Link each agent from the repo
$AGENTS_SRC_DIR = Join-Path $REPO_DIR 'agents'
if (Test-Path -LiteralPath $AGENTS_SRC_DIR) {
    Get-ChildItem -LiteralPath $AGENTS_SRC_DIR -Filter '*.md' -File | ForEach-Object {
        Link-File -Path (Join-Path $AGENTS_DIR $_.Name) -Source $_.FullName
    }
}

# 3b. Per-user local memory database (never committed to the repo)
Write-Host "🧠 Setting up per-user local memory database..."
& (Join-Path $REPO_DIR 'scripts\memory-setup.ps1')

# 3c. Install MCP servers locally and expose their binaries on PATH.
# Removes `npx -y <pkg>` from opencode.jsonc/mcp.json so opencode and Antigravity
# no longer resolve/download packages from the registry at startup.
Write-Host "📦 Installing local MCP servers (package.json)..."
$LOCAL_BIN_DIR = Join-Path $HOME '.local\bin'
New-Item -ItemType Directory -Path $LOCAL_BIN_DIR -Force | Out-Null

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $PM = 'pnpm'
} elseif (Get-Command corepack -ErrorAction SilentlyContinue) {
    & corepack enable pnpm *> $null
    if (Get-Command pnpm -ErrorAction SilentlyContinue) { $PM = 'pnpm' } else { $PM = 'npm' }
} else {
    $PM = 'npm'
}
Write-Host "  • Package manager: ${PM}"
Push-Location $REPO_DIR
& $PM install --loglevel=error
Pop-Location

# codegraph-mcp fetches its native engine in postinstall; pnpm 10+ blocks build
# scripts by default, so run it explicitly (idempotent: skips when engine present).
$codegraphPostinstall = Join-Path $REPO_DIR 'node_modules\@astudioplus\codegraph-mcp\bin\postinstall.js'
if (Test-Path -LiteralPath $codegraphPostinstall) {
    Write-Host "  • Ensuring codegraph-mcp native engine..."
    & node $codegraphPostinstall *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ⚠️ codegraph-mcp engine fetch failed (network required on first install)"
    }
}

# Windows: npm/pnpm produce `.cmd` shims whose internals are relative to their
# own directory, so we generate forwarding wrappers (stable absolute path)
# rather than copying/symlinking the shims directly.
$MCP_BINS = @(
    'codegraph-mcp',
    'context7-mcp',
    'mcp-server-github',
    'mcp-server-memory',
    'playwright-mcp'
)
foreach ($bin in $MCP_BINS) {
    $realShim = Join-Path $REPO_DIR "node_modules\.bin\${bin}.cmd"
    $wrapper   = Join-Path $LOCAL_BIN_DIR "${bin}.cmd"
    if (Test-Path -LiteralPath $realShim) {
        $content = "@echo off`r`ncall `"$realShim`" %*`r`n"
        $existing = if (Test-Path -LiteralPath $wrapper) { [System.IO.File]::ReadAllText($wrapper) } else { '' }
        if ($content -ne $existing) {
            [System.IO.File]::WriteAllText($wrapper, $content, (New-Object System.Text.UTF8Encoding($false)))
        }
        Write-Host "  ✅ MCP bin on PATH: ${bin}"
    } else {
        Write-Host "  ❌ MCP bin missing after install: ${bin}"
    }
}

# Ensure the local bin dir is on the user PATH (idempotent).
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*${LOCAL_BIN_DIR}*") {
    [Environment]::SetEnvironmentVariable('Path', "${LOCAL_BIN_DIR};${userPath}", 'User')
    Write-Host "  • Added ${LOCAL_BIN_DIR} to user PATH (restart terminal to apply)."
}

# Detect Chrome for playwright; fall back to chromium when absent.
Write-Host "🌐 Detecting browser for playwright MCP..."
$PLAYWRIGHT_BROWSER = 'chromium'
$chromeCandidates = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
foreach ($c in $chromeCandidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { $PLAYWRIGHT_BROWSER = 'chrome'; break }
}
Write-Host "  • PLAYWRIGHT_BROWSER=${PLAYWRIGHT_BROWSER}"

$envFile = Join-Path $REPO_DIR '.env'
if (Test-Path -LiteralPath $envFile) {
    $lines = [System.IO.File]::ReadAllLines($envFile)
    $newLine = "PLAYWRIGHT_BROWSER=${PLAYWRIGHT_BROWSER}"
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^PLAYWRIGHT_BROWSER=') { $lines[$i] = $newLine; $found = $true; break }
    }
    if (-not $found) {
        $lines = $lines + @('', '# Resolved by setup.ps1 (chrome if installed, else chromium). Do not edit manually.', $newLine)
    }
    [System.IO.File]::WriteAllLines($envFile, $lines, (New-Object System.Text.UTF8Encoding($false)))
}

# ==============================================================================
# 4. Clean up legacy skill & temporary directories to prevent duplicate loading
# ==============================================================================
Write-Host "🧹 Cleaning legacy paths (~/.agents, ~/.claude, ~/temp/antigravity-awesome-skills)..."
Remove-Item -Path (Join-Path $HOME '.agents') -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $HOME '.claude') -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $HOME 'temp\antigravity-awesome-skills') -Force -Recurse -ErrorAction SilentlyContinue

# Remove legacy ~/.gemini/skills (standalone dir outside ~/.gemini/config) that
# used to hold a duplicate context7-mcp skill colliding with the linked copy.
$LEGACY_SKILLS = Join-Path $HOME '.gemini\skills'
if (Test-Path -LiteralPath $LEGACY_SKILLS) {
    Write-Host "🧹 Removing legacy ${LEGACY_SKILLS} (duplicate skill source)..."
    Remove-Item -Path $LEGACY_SKILLS -Force -Recurse
}

# ==============================================================================
# 4b. Git credential helper fix (GITHUB_TOKEN vs gh OAuth token)
# ==============================================================================
# gh auth git-credential prefers GITHUB_TOKEN/GH_TOKEN from the environment over
# the full OAuth token stored by `gh auth login`. A fine-grained PAT lacks the
# `Contents: write` permission needed to delete remote branches, breaking
# `git push --delete`. Force git to use gh's stored OAuth token.
# Git for Windows ships no `env`, so we use a sh function with `unset` instead.
$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCmd) {
    $ghShPath = ($ghCmd.Source) -replace '\\', '/'
    Write-Host "🔧 Configuring git to use gh OAuth token (ignoring GITHUB_TOKEN/GH_TOKEN)..."
    git config --global credential.https://github.com.helper "!f(){ unset GITHUB_TOKEN GH_TOKEN; '${ghShPath}' auth git-credential; }; f"
    git config --global credential.https://gist.github.com.helper "!f(){ unset GITHUB_TOKEN GH_TOKEN; '${ghShPath}' auth git-credential; }; f"
    Write-Host "  ✅ git credential helper: $($ghCmd.Source)"
} else {
    Write-Host "⚠️  gh CLI not found. Skipping git credential helper config."
}

# ==============================================================================
# 4c. Vendored planning skills (wayfinder suite + WBS) and custom skills.
# ==============================================================================
$VENDOR_SOURCES = @(
    'mattpocock|wayfinder|https://github.com/mattpocock/skills|skills/engineering/wayfinder',
    'mattpocock|setup-matt-pocock-skills|https://github.com/mattpocock/skills|skills/engineering/setup-matt-pocock-skills',
    'mattpocock|to-spec|https://github.com/mattpocock/skills|skills/engineering/to-spec',
    'mattpocock|grilling|https://github.com/mattpocock/skills|skills/productivity/grilling',
    'mattpocock|grill-with-docs|https://github.com/mattpocock/skills|skills/engineering/grill-with-docs',
    'mattpocock|research|https://github.com/mattpocock/skills|skills/engineering/research',
    'mattpocock|triage|https://github.com/mattpocock/skills|skills/engineering/triage',
    'agent-almanac|create-work-breakdown-structure|https://github.com/pjt222/agent-almanac|skills/create-work-breakdown-structure'
)

$SKILL_SRC_DIR = Join-Path $HOME '.cache\agent-vendor-src'
$VENDOR_OK = 0
$VENDOR_MISSING = 0

if ($RefreshVendored) {
    Write-Host "🔄 Refreshing vendored skills from upstream sources..."
    foreach ($entry in $VENDOR_SOURCES) {
        $parts = $entry -split '\|'
        $origin  = $parts[0]
        $name    = $parts[1]
        $repo    = $parts[2]
        $srcPath = $parts[3]
        $tmpRepo = Join-Path $SKILL_SRC_DIR (Split-Path -Leaf $repo)

        New-Item -ItemType Directory -Path $SKILL_SRC_DIR -Force | Out-Null
        if (Test-Path -LiteralPath (Join-Path $tmpRepo '.git')) {
            git -C $tmpRepo pull --quiet *> $null
        } else {
            git clone --depth 1 --quiet $repo $tmpRepo *> $null
        }

        $srcSkill = Join-Path $tmpRepo ($srcPath -replace '/', '\') + '\SKILL.md'
        if (Test-Path -LiteralPath $srcSkill) {
            $destDir = Join-Path $REPO_DIR "skills\$name"
            Remove-Item -Path $destDir -Force -Recurse -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Copy-Item -Path $srcSkill -Destination (Join-Path $destDir 'SKILL.md') -Force
            Get-ChildItem -LiteralPath (Split-Path -Path $srcSkill -Parent) -Filter '*.md' -File |
                Where-Object { $_.Name -ne 'SKILL.md' } |
                ForEach-Object { Copy-Item -Path $_.FullName -Destination $destDir -Force }
            Write-Host "  ✅ ${name} ← ${repo} (${srcPath})"
        } else {
            Write-Host "  ❌ ${name}: source not found in ${repo}"
        }
    }
}

Write-Host "🔎 Verifying vendored planning skills..."
foreach ($entry in $VENDOR_SOURCES) {
    $name = ($entry -split '\|')[1]
    if (Test-Path -LiteralPath (Join-Path $REPO_DIR "skills\$name\SKILL.md")) {
        $VENDOR_OK++
    } else {
        Write-Host "  ❌ MISSING ${name} (run: setup.ps1 --refresh-vendored-skills)"
        $VENDOR_MISSING++
    }
}

# Custom skills committed to this repo (no upstream source; never refreshed):
# estimate-costs, to-tickets (personalized with GitHub mechanics), ask-matt
# (personalized to reference /plan-phases-implement), plan-phases-create,
# plan-phases-implement, constitution/checklist/analyze/converge (adapted from
# github/spec-kit, standalone, no specify CLI).
$CUSTOM_SKILLS = @(
    'estimate-costs', 'to-tickets', 'ask-matt', 'plan-phases-create',
    'plan-phases-implement', 'constitution', 'checklist', 'analyze', 'converge'
)
foreach ($skill in $CUSTOM_SKILLS) {
    if (Test-Path -LiteralPath (Join-Path $REPO_DIR "skills\$skill\SKILL.md")) {
        $VENDOR_OK++
    } else {
        Write-Host "  ❌ MISSING ${skill} (custom skill)"
        $VENDOR_MISSING++
    }
}
if ($VENDOR_MISSING -gt 0) {
    Write-Host "⚠️  ${VENDOR_MISSING} vendored skill(s) missing."
}

# ==============================================================================
# 5. Secret leak check on committed configs
# ==============================================================================
Write-Host "🔍 Scanning config files for hardcoded secrets..."
$SECRET_PATTERNS = @(
    'ctx7sk-',
    'github_pat_',
    'ghp_',
    'gho_',
    'sk-[A-Za-z0-9]',
    'Bearer [A-Za-z0-9]'
)
$FOUND_SECRET = $false
$CONFIG_FILES = @(
    (Join-Path $REPO_DIR 'mcp.json'),
    (Join-Path $REPO_DIR 'opencode.jsonc'),
    (Join-Path $REPO_DIR 'extensions\lumusitech\gemini-extension.json')
)
foreach ($cfg in $CONFIG_FILES) {
    if (-not (Test-Path -LiteralPath $cfg)) { continue }
    foreach ($pat in $SECRET_PATTERNS) {
        if (Select-String -LiteralPath $cfg -Pattern $pat -Quiet) {
            Write-Host "  ❌ Possible hardcoded secret '${pat}' in ${cfg}"
            $FOUND_SECRET = $true
        }
    }
}
if ($FOUND_SECRET) {
    Write-Host "⚠️  Review and remove hardcoded secrets before committing."
} else {
    Write-Host "  ✅ No hardcoded secrets in committed configs."
}

# ==============================================================================
# 6. MCP binary availability check (installed locally, exposed on PATH)
# ==============================================================================
Write-Host "🔎 Verifying MCP binaries on PATH..."
$MCP_BINS_VERIFY = @(
    'codegraph-mcp',
    'context7-mcp',
    'mcp-server-github',
    'mcp-server-memory',
    'playwright-mcp'
)
$MCP_OK = 0
$MCP_FAIL = 0
foreach ($bin in $MCP_BINS_VERIFY) {
    if (Test-Path -LiteralPath (Join-Path $HOME ".local\bin\${bin}.cmd")) {
        Write-Host "  ✅ OK    ${bin}"
        $MCP_OK++
    } else {
        Write-Host "  ❌ FAIL  ${bin} (not installed; re-run setup.ps1)"
        $MCP_FAIL++
    }
}
if ($MCP_FAIL -gt 0) {
    Write-Host "⚠️  ${MCP_FAIL} MCP binary(ies) missing. Re-run setup.ps1 to install."
}

# ==============================================================================
# 6b. Optional: Windows Terminal profile (-ConfigureWindowsTerminal)
# ==============================================================================
function Update-WindowsTerminalProfile {
    # Idempotent merge: adds/updates a dedicated "AI Workspace (pwsh 7)" profile
    # and sets it as the default. Never touches other profiles. Backs up
    # settings.json only when something actually changes.
    $WT_GUID = '{A1B2C3D4-1111-4222-8333-9F4E5D6C7B8A}'
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d9bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
    $settingsPath = $null
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { $settingsPath = $candidate; break }
    }
    if (-not $settingsPath) {
        Write-Host "ℹ️  Windows Terminal settings.json not found; skipping profile setup."
        return
    }
    try {
        $wt = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Could not parse ${settingsPath}; skipping Windows Terminal profile setup."
        return
    }
    $changed = $false
    if (-not $wt.PSObject.Properties['profiles']) {
        $wt | Add-Member -NotePropertyName profiles -NotePropertyValue ([PSCustomObject]@{ list = @() })
        $changed = $true
    }
    if (-not $wt.profiles.PSObject.Properties['list']) {
        $wt.profiles | Add-Member -NotePropertyName list -NotePropertyValue @()
        $changed = $true
    }
    $existing = @($wt.profiles.list | Where-Object { $_.PSObject.Properties['guid'] -and $_.guid -eq $WT_GUID })
    if ($existing.Count -gt 0) {
        foreach ($profile in $existing) {
            if ($profile.commandline -ne 'pwsh -NoLogo') { $profile.commandline = 'pwsh -NoLogo'; $changed = $true }
            if ($profile.startingDirectory -ne $REPO_DIR) { $profile.startingDirectory = $REPO_DIR; $changed = $true }
            if ($profile.name -ne 'AI Workspace (pwsh 7)') { $profile.name = 'AI Workspace (pwsh 7)'; $changed = $true }
        }
    } else {
        $profileObj = [PSCustomObject]@{
            guid             = $WT_GUID
            name             = 'AI Workspace (pwsh 7)'
            commandline      = 'pwsh -NoLogo'
            startingDirectory = $REPO_DIR
            hidden           = $false
        }
        $wt.profiles.list = @($wt.profiles.list) + $profileObj
        $changed = $true
    }
    if ($wt.defaultProfile -ne $WT_GUID) {
        $wt.defaultProfile = $WT_GUID
        $changed = $true
    }
    if ($changed) {
        Copy-Item -LiteralPath $settingsPath -Destination "${settingsPath}.bak" -Force
        $wt | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $settingsPath -Encoding utf8NoBOM
        Write-Host "✅ Windows Terminal profile configured (backup: ${settingsPath}.bak). Close and reopen Windows Terminal to apply."
    } else {
        Write-Host "✅ Windows Terminal profile already configured."
    }
}

if ($DoConfigureWT) {
    Write-Host "🪟 Configuring Windows Terminal profile..."
    Update-WindowsTerminalProfile
}

# ==============================================================================
# 7. Summary & Verification
# ==============================================================================
$SKILL_COUNT = @(Get-ChildItem -LiteralPath (Join-Path $REPO_DIR 'skills') -Directory -ErrorAction SilentlyContinue).Count

Write-Host ""
Write-Host "======================================================================"
Write-Host "🎉 Setup Complete!"
Write-Host "----------------------------------------------------------------------"
Write-Host "  • Total Curated Skills: ${SKILL_COUNT}"
Write-Host "  • Vendored Planning Skills OK/MISSING: ${VENDOR_OK}/${VENDOR_MISSING}"
Write-Host "  • MCP Bins OK/FAIL:     ${MCP_OK}/${MCP_FAIL}"
Write-Host "  • OpenCode Config:      ${OPENCODE_CONFIG_DIR}\opencode.jsonc"
Write-Host "  • OpenCode DCP:         ${OPENCODE_CONFIG_DIR}\dcp.jsonc"
Write-Host "  • OpenCode TUI:         ${OPENCODE_CONFIG_DIR}\tui.json"
Write-Host "  • Playwright Browser:   ${PLAYWRIGHT_BROWSER}"
Write-Host "  • Memoria Local:        $env:MEMORY_FILE_PATH (o ~\.local\share\opencode\memory\<user>.jsonl)"
Write-Host "  • OpenCode Directives:  ${OPENCODE_CONFIG_DIR}\AGENTS.md"
Write-Host "  • Antigravity Skills:   ${GEMINI_CONFIG_DIR}\skills"
Write-Host "  • Antigravity MCPs:     ${GEMINI_CONFIG_DIR}\mcp.json"
Write-Host "  • MCPs Configured:      context7, codegraph, codebase-memory, github, memory, playwright"
Write-Host "----------------------------------------------------------------------"
Write-Host "  💡 Planning pipeline: wayfinder → setup-matt-pocock-skills → to-spec →"
Write-Host "     create-work-breakdown-structure → estimate-costs → to-tickets"
Write-Host "  📐 Phase planning:    plan-phases-create → plan-phases-implement"
Write-Host "  🔄 Update vendored skills:  setup.ps1 --refresh-vendored-skills"
Write-Host "  🛠️  Per-repo init: run /setup-matt-pocock-skills once in each repo"
Write-Host "======================================================================"

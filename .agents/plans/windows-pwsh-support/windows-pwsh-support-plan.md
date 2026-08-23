---
plan_name: windows-pwsh-support
title: Soporte Windows con PowerShell 7 + garantía de idempotencia en Unix
created_at: 2026-08-23
approved_by: user
implemented_by:
  tool: opencode
  model:
    name: deepseek-v4-pro
    version: latest
last_implementation_at: 2026-08-23T18:45:00Z
has_completed_all_phases: true
---

# Plan: Soporte Windows (PowerShell 7) + Idempotencia Unix

## Decisiones confirmadas

- Antigravity en Windows: soporte completo con hooks `.ps1` + `hooks.windows.json` generado con rutas absolutas.
- Memoria: `~/.local/share/opencode/memory/<user>.jsonl` (misma ruta XDG que Unix).
- Links: symlink → fallback Junction (dirs) / copia (archivos) con sobreescritura desde el repo.
- winget + Windows Terminal: pasos opcionales (flag `-InstallPrerequisites`), idempotentes.
- Backport a `setup.sh` / `scripts/memory-setup.sh`: misma garantía de idempotencia y limpieza.

## Contrato de idempotencia (ambos scripts)

1. **Gate winget**: `Get-Command` en PATH → skip; si no, `winget list --id --exact` antes de `install`. `--scope user --accept-package-agreements`.
2. **Links**: recrear con `-Force`; dir real viejo → eliminar y linkar (el script es la fuente de la verdad).
3. **Copy fallback**: siempre sobreescribir desde el repo (git pull se propaga en la siguiente corrida).
4. **`.env`**: nunca tocar credenciales existentes; reemplazo quirúrgico de la línea `MEMORY_FILE_PATH` (LF y CRLF).
5. **Profile**: marker único `# >>> lumusitech agent env >>>` → skip si existe.
6. **hooks.json (Win)**: escribir solo si contenido difiere.
7. **Windows Terminal settings.json**: merge por GUID, backup `.bak` solo si hay cambio, skip si WT no instalado.
8. **Credential fix / limpieza legacy / verificaciones**: idempotentes por naturaleza.

## Fases

### Fase 1 — `setup.ps1` core

- [x] `Test-SymlinkCapability` (prueba con symlink temporal; detecta Developer Mode/admin)
- [x] `Link-Dir` y `Link-File` (symlink → fallback Junction/Copy + reemplazo de dirs reales viejos)
- [x] `.env` create-if-absent desde `.env.template`
- [x] Links Antigravity: `~/.gemini/config/{skills,skills.json,GEMINI.md,mcp.json}` + `~/.gemini/extensions/lumusitech`
- [x] Links OpenCode: `~/.config/opencode/{opencode.jsonc,dcp.jsonc,AGENTS.md,plugins}` + `agents/*.md`
- [x] Limpieza de symlinks huérfanos en `~/.config/opencode/agents`
- [x] Limpieza legacy (`~/.agents`, `~/.claude`, `~/.gemini/skills`, `temp/antigravity-awesome-skills`)
- [x] Git credential fix Windows (`unset` sh-variant, sin `env -u`)
- [x] Verificación skills vendored + custom + `--refresh-vendored-skills`
- [x] Scan de secretos (`Select-String` con 6 patrones)
- [x] Verificación `npm view` de 5 paquetes MCP
- [x] Resumen final idéntico al de setup.sh
- [x] Parse-check con PSParser (pwsh portable en /tmp/opencode)

**Contratos públicos:**
- Archivo: `setup.ps1` (UTF-8 sin BOM, LF).
- `Link-Dir -Path <target> -Target <source>`: deja `<target>` como symlink (o Junction si no hay permiso) apuntando a `<source>`; si `<target>` es dir real → lo elimina antes.
- `Link-File -Path <target> -Source <source>`: symlink si hay permiso; si no, `Copy-Item -Force` (siempre sobreescribe).
- Flags: `--refresh-vendored-skills` (switch), `-InstallPrerequisites` (reservado para Fase 7).
- NO genera hooks.json (Fase 3) ni invoca memory-setup.ps1 (Fase 2).
- Salida: emojis y mensajes equivalentes a setup.sh; segunda corrida ≈ "✅ ya configurado".

### Fase 2 — `scripts/memory-setup.ps1` + bloque de profile

- [x] Detección de usuario: `gh api user -q .login` → `git config user.name` → `$env:USERNAME`
- [x] Sanitización slug `[a-z0-9-]`
- [x] Prompts `Read-Host` (interactive si TTY)
- [x] Escritura `MEMORY_FILE_PATH` en `.env` (UTF-8 sin BOM, LF/CRLF, reemplazo quirúrgico)
- [x] Bloque de profile pwsh (`$PROFILE`) con marker `# >>> lumusitech agent env >>>`
- [x] Migración legacy `memory.jsonl` (confirm con `Read-Host`)
- [x] Wire: invocación `& "$PSScriptRoot\scripts\memory-setup.ps1"` desde setup.ps1

**Contratos públicos:**
- Archivo: `scripts/memory-setup.ps1`. Parámetros: `-NonInteractive` (switch).
- Bloque de profile:
  ```powershell
  # >>> lumusitech agent env >>>
  # Load ~/.agent/.env credentials (GITHUB_TOKEN, MEMORY_FILE_PATH, ...) for opencode MCP servers
  if (Test-Path "$HOME\.agent\.env") {
      Get-Content "$HOME\.agent\.env" | ForEach-Object {
          if ($_ -match '^\s*([^#=]+)=(.*)$') {
              [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim().Trim('"'), 'Process')
          }
      }
  }
  # <<< lumusitech agent env <<<
  ```
- No sobreescribe credenciales existentes en `.env`.

### Fase 3 — Hooks PS1 + `hooks.windows.json`

- [x] `hooks/env-protection.ps1` (JSON stdin → decisión; bloquea `.env`, `export VAR=`, `$env:VAR=`, `setx`)
- [x] `hooks/notify.ps1` (JSON stdin → `stop`; BurntToast best-effort)
- [x] `hooks.windows.json` (contrato igual a hooks.json, comandos `pwsh -NoProfile -File "<abs>"`)
- [x] Wire: setup.ps1 genera `~/.gemini/config/hooks.json` desde `hooks.windows.json` con rutas absolutas, escribe solo si difiere

**Contratos públicos:**
- Ambos hooks: stdin JSON (protojson/camelCase), stdout JSON `{"decision": "allow"|"deny"|"stop"}`.
- `hooks.windows.json`: placeholders de ruta reemplazados por setup.ps1.

### Fase 4 — Plugins multiplataforma

- [x] `plugins/env-protection.js`: `filePath.split(/[\\/]/)` (detecta `.env` en rutas Windows); bloquea `$env:VAR=` y `setx` en tool bash
- [x] `plugins/notifications.js`: rama `win32` (BurntToast vía `pwsh -NoProfile`, try/catch)
- [x] `node --check` en ambos archivos

**Contratos públicos:**
- Sin cambios de API. Comportamiento Unix intacto.

### Fase 5 — `setup.cmd` + README

- [x] `setup.cmd`: `pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*` + error claro si falta pwsh
- [x] README: sección Windows (prerequisitos, instalación, Developer Mode vs Junction/Copy, bloque profile, verificación `$env:GITHUB_TOKEN`, `-InstallPrerequisites`)

### Fase 6 — Backport idempotencia a Unix

- [x] `setup.sh`: limpieza de symlinks huérfanos en `~/.config/opencode/agents`; mensajes "✅ ya configurado"; reemplazo explícito de dirs reales antes de linkar
- [x] `scripts/memory-setup.sh`: marker único en bloque de profile + deduplicación de bloques legacy
- [x] Doble corrida de `setup.sh` en esta máquina: 2ª ≈ silenciosa, `git status` limpio

### Fase 7 — Opcionales winget + Windows Terminal

- [x] Flag `-InstallPrerequisites`: instala pwsh/gh/bun/node con gate `Get-Command` + `winget list --exact`
- [x] Detección PS 5.1 → aviso/relanzamiento (via `#Requires 7.0` + error claro en setup.cmd con comando winget sugerido)
- [x] Merge idempotente de perfil en Windows Terminal `settings.json` (GUID estable, backup solo si cambia, skip si no instalado)

### Fase 8 — Verificación final

- [x] Checklist manual Windows documentado (links, .env, profile, MCP, hooks JSON válido, refresh skills) — documentado en README "Windows (PowerShell 7)"; verificación en máquina Windows real pendiente del usuario
- [x] Actualizar frontmatter del plan (`has_completed_all_phases: true`)

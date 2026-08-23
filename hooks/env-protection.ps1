#Requires -Version 7.0
# Environment protection hook for Antigravity / Gemini CLI (Windows).
#
# Blocks file tools (view_file, edit_file, write_file, create_file, patch_file)
# from touching any path that contains a `.env` segment, blocks shell commands
# that reference `.env` secrets, and blocks environment-variable assignments
# (`export VAR=...`, `$env:VAR=...`, `setx VAR ...`, SetEnvironmentVariable),
# mirroring the behaviour of the OpenCode `env-protection` plugin and the
# Unix `env-protection.sh` hook.
#
# Contract: reads a JSON payload from stdin (protojson/camelCase) and writes a
# JSON decision to stdout. Exit code is always 0.
$ErrorActionPreference = 'Stop'

$raw = [Console]::In.ReadToEnd()

try {
    if ([string]::IsNullOrWhiteSpace($raw)) { throw 'empty payload' }
    $payload = $raw | ConvertFrom-Json
} catch {
    Write-Output '{"decision": "allow", "reason": "Invalid hook payload"}'
    exit 0
}

$toolCall = $payload.toolCall
$name = if ($toolCall) { $toolCall.name } else { '' }
$argsObj = if ($toolCall) { $toolCall.args } else { $null }

$script:collected = [System.Collections.Generic.List[string]]::new()

function Collect-Values($obj) {
    if ($null -eq $obj) { return }
    if ($obj -is [string]) { $script:collected.Add($obj); return }
    if ($obj -is [System.Collections.IDictionary]) {
        foreach ($v in $obj.Values) { Collect-Values $v }
        return
    }
    if ($obj -is [System.Collections.IEnumerable]) {
        foreach ($v in $obj) { Collect-Values $v }
        return
    }
    if ($obj -is [psobject]) {
        foreach ($p in $obj.PSObject.Properties) { Collect-Values $p.Value }
    }
}

Collect-Values $argsObj

function Test-SensitivePath([string]$value) {
    # Normalize separators so both C:\...\.env and /home/u/.env match.
    $norm = $value.ToLowerInvariant() -replace '\\', '/'
    if ($norm.Contains('/.env')) { return $true }
    if ($norm.TrimEnd('/').EndsWith('/.env')) { return $true }
    if ($norm.TrimEnd('/') -eq '.env') { return $true }
    return $false
}

$FILE_TOOLS = @('view_file', 'edit_file', 'write_file', 'create_file', 'patch_file')

if ($FILE_TOOLS -contains $name) {
    foreach ($v in $script:collected) {
        if (Test-SensitivePath $v) {
            Write-Output '{"decision": "deny", "reason": "Access to .env files is blocked by the env-protection hook."}'
            exit 0
        }
    }
}

if ($name -eq 'run_command') {
    $commandLine = ''
    if ($argsObj) {
        $commandLine = [string]($argsObj.CommandLine ?? $argsObj.commandLine ?? $argsObj.command ?? '')
    }
    if (-not [string]::IsNullOrWhiteSpace($commandLine)) {
        $lowered = $commandLine.ToLowerInvariant()
        $normalized = $lowered -replace '\\', '/'
        if ($normalized.Contains('/.env') -or $normalized.Contains('~/.env')) {
            Write-Output '{"decision": "deny", "reason": "Shell command referencing .env is blocked by the env-protection hook."}'
            exit 0
        }
        if ($commandLine -match '\bexport\s+[A-Za-z_][A-Za-z0-9_]*\s*=') {
            Write-Output '{"decision": "deny", "reason": "The export command is blocked by the env-protection hook."}'
            exit 0
        }
        if ($commandLine -match '\$env:[A-Za-z_][A-Za-z0-9_]*\s*=') {
            Write-Output '{"decision": "deny", "reason": "The `$env: assignment is blocked by the env-protection hook."}'
            exit 0
        }
        if ($commandLine -match '\bsetx\s+[A-Za-z_][A-Za-z0-9_]*\s*(\s\S|$)') {
            Write-Output '{"decision": "deny", "reason": "The setx command is blocked by the env-protection hook."}'
            exit 0
        }
        if ($lowered.Contains('[environment]::setenvironmentvariable')) {
            Write-Output '{"decision": "deny", "reason": "SetEnvironmentVariable is blocked by the env-protection hook."}'
            exit 0
        }
    }
}

Write-Output '{"decision": "allow"}'

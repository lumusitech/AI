#Requires -Version 7.0
# Session notification hook for Antigravity / Gemini CLI (Windows).
#
# Sends a native desktop notification when the execution loop stops, mirroring
# the behaviour of the OpenCode `notifications` plugin and the Unix
# `notify.sh` hook. Uses BurntToast when available (best-effort; never fails
# the hook).
#
# Contract: reads a JSON payload from stdin (protojson/camelCase) and writes a
# JSON decision to stdout. Returns a stop decision so the agent is allowed to
# finish.
$ErrorActionPreference = 'Stop'

$raw = [Console]::In.ReadToEnd()

try {
    if ([string]::IsNullOrWhiteSpace($raw)) { throw 'empty payload' }
    $payload = $raw | ConvertFrom-Json
} catch {
    $payload = $null
}

$title = 'Antigravity session finished'
$message = 'Your Antigravity session has stopped.'
$reason = if ($payload) { [string]$payload.terminationReason } else { '' }
if ($reason) {
    $message = "Your Antigravity session stopped (${reason})."
}

try {
    if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
        Import-Module BurntToast -ErrorAction SilentlyContinue
        New-BurntToastNotification -Text $title, $message -ErrorAction SilentlyContinue | Out-Null
    }
} catch {
    # Notifications are best-effort; never crash the hook.
}

Write-Output '{"decision": "stop", "reason": "Session finished."}'

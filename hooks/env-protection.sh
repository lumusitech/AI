#!/usr/bin/env bash
# Environment protection hook for Antigravity / Gemini CLI.
#
# Blocks file tools (view_file, edit_file, write_file, create_file) from
# touching any path that contains a `.env` segment, blocks shell commands
# that reference `.env` secrets, and blocks `export VAR=...` assignments
# (but allows commands that merely reference the word "export", e.g. grep),
# mirroring the behaviour of the OpenCode `env-protection` plugin.
#
# Contract: reads a JSON payload from stdin (protojson/camelCase) and writes a
# JSON decision to stdout.
set -euo pipefail

PAYLOAD="$(cat)"

python3 - "${PAYLOAD}" <<'PYEOF'
import json, re, sys

raw = sys.argv[1]
try:
    payload = json.loads(raw)
except Exception:
    print(json.dumps({"decision": "allow", "reason": "Invalid hook payload"}))
    sys.exit(0)

tool_call = payload.get("toolCall") or {}
name = tool_call.get("name") or ""
args = tool_call.get("args") or {}

FILE_TOOLS = {"view_file", "edit_file", "write_file", "create_file", "patch_file"}

values = []

def collect(obj):
    if isinstance(obj, str):
        values.append(obj)
    elif isinstance(obj, dict):
        for v in obj.values():
            collect(v)
    elif isinstance(obj, list):
        for v in obj:
            collect(v)

collect(args)

def looks_sensitive(value: str) -> bool:
    lowered = value.lower()
    if "/.env" in lowered or "\\\\.env" in lowered:
        return True
    if lowered.rstrip("/").endswith("/.env") or lowered.rstrip("/") == ".env":
        return True
    return False

sensitive = [v for v in values if looks_sensitive(v)]

if name in FILE_TOOLS and sensitive:
    print(json.dumps({
        "decision": "deny",
        "reason": "Access to .env files is blocked by the env-protection hook.",
    }))
    sys.exit(0)

if name == "run_command":
    command_line = args.get("CommandLine") or args.get("commandLine") or args.get("command") or ""
    lowered = command_line.lower()
    if "/.env" in lowered or "~/.env" in lowered:
        print(json.dumps({
            "decision": "deny",
            "reason": "Shell command referencing .env is blocked by the env-protection hook.",
        }))
        sys.exit(0)
    if re.search(r"\bexport\s+[A-Za-z_][A-Za-z0-9_]*\s*=", lowered):
        print(json.dumps({
            "decision": "deny",
            "reason": "The export command is blocked by the env-protection hook.",
        }))
        sys.exit(0)

print(json.dumps({"decision": "allow"}))
PYEOF

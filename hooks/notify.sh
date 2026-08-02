#!/usr/bin/env bash
# Session notification hook for Antigravity / Gemini CLI.
#
# Sends a native desktop notification when the execution loop stops, mirroring
# the behaviour of the OpenCode `notifications` plugin.
#
# Contract: reads a JSON payload from stdin (protojson/camelCase) and writes a
# JSON decision to stdout. Returns a stop decision so the agent is allowed to
# finish.
set -euo pipefail

PAYLOAD="$(cat)"

python3 - "${PAYLOAD}" <<'PYEOF'
import json, os, subprocess, sys

raw = sys.argv[1]
try:
    payload = json.loads(raw)
except Exception:
    payload = {}

title = "Antigravity session finished"
message = "Your Antigravity session has stopped."
reason = payload.get("terminationReason") or ""
if reason:
    message = f"Your Antigravity session stopped ({reason})."

try:
    if sys.platform == "darwin":
        subprocess.run(
            ["osascript", "-e", f'display notification "{message}" with title "{title}"'],
            check=False, capture_output=True,
        )
    elif sys.platform.startswith("linux") and os.environ.get("DISPLAY"):
        subprocess.run(
            ["notify-send", title, message],
            check=False, capture_output=True,
        )
except Exception:
    pass

print(json.dumps({"decision": "stop", "reason": "Session finished."}))
PYEOF

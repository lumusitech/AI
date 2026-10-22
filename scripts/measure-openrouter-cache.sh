#!/usr/bin/env bash
# Report prompt-cache usage for a single OpenRouter generation.
# Usage: measure-openrouter-cache.sh <generation_id>
# The generation id comes from OpenRouter Activity or the X-Generation-Id response header.
set -euo pipefail

ID="${1:-}"
if [ -z "$ID" ]; then
  echo "Usage: $0 <generation_id>"
  echo "Find the id in https://openrouter.ai/activity (detail view) or in the X-Generation-Id header."
  exit 1
fi

if [ -z "${OPENROUTER_API_KEY:-}" ]; then
  echo "OPENROUTER_API_KEY is not set in this shell." >&2
  echo "It is read from ~/.agent/.env by the inject-env plugin at OpenCode startup." >&2
  echo "Restart OpenCode (or run this from a terminal whose profile loads ~/.agent/.env)." >&2
  exit 1
fi

curl -fsS -H "Authorization: Bearer ${OPENROUTER_API_KEY}" \
  "https://openrouter.ai/api/v1/generation?id=${ID}" \
| node -e '
let s = "";
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  let j;
  try { j = JSON.parse(s); } catch { console.error("Invalid JSON response"); process.exit(1); }
  const d = j.data || j;
  const pick = (...keys) => keys.map((k) => d[k]).find((v) => v !== undefined && v !== null);
  const prompt = pick("tokens_prompt", "native_tokens_prompt");
  const cached = pick("native_tokens_cached", "cached_tokens", "tokens_cached");
  console.log("id:              ", d.id);
  console.log("model:           ", d.model);
  console.log("provider:        ", d.provider_name);
  console.log("prompt_tokens:   ", prompt);
  console.log("cached_tokens:   ", cached);
  if (prompt && cached != null) console.log("cache_hit_pct:   ", ((100 * cached) / prompt).toFixed(1) + "%");
  console.log("completion_tokens:", pick("tokens_completion", "native_tokens_completion"));
  console.log("cache_discount:  ", d.cache_discount);
  console.log("total_cost:      ", d.total_cost);
  console.log("--- raw ---");
  console.log(JSON.stringify(d, null, 2));
});
'

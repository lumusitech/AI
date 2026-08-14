---
name: memory-import
description: Replace the local per-user memory knowledge graph with the contents of a pasted Memory Graph Export (Markdown with embedded JSONL block). Use when the user pastes or provides a memory-export document to establish memory on this machine.
disable-model-invocation: true
---

# Memory Import

Replace the local memory graph with the graph carried by a Memory Graph Export document (produced by `/memory-export`). **Replaces**, it does not merge.

## Process

### 1. Get the document

- If the user pasted the Markdown, work from the conversation content.
- If a path or file is provided, read it.
- Locate the fenced `jsonl` block. It is the authoritative payload. If it is missing, fall back to parsing the human-readable sections — but warn the user that the import is best-effort and may be lossy.

### 2. Parse and validate

Parse each line of the `jsonl` block:

- `{"type":"entity","name":...,"entityType":...,"observations":[...]}` → entity
- `{"type":"relation","from":...,"to":...,"relationType":...}` → relation

Validation checks:
- Every entity has a non-empty `name` and `observations` is an array of strings.
- Every relation references known `from`/`to` entity names (warn if not, but keep it).
- Reject malformed JSON lines — abort the import and report the offending line instead of writing partial data.

### 3. Replace the local graph

Replace semantics — the destination graph becomes exactly what the document carries:

1. List current entities via `memory_read_graph` (or read the file directly from `$MEMORY_FILE_PATH`, fallback `~/.local/share/opencode/memory/<user>.jsonl`).
2. Delete every current entity with `delete_entities` (this also removes relations touching them).
3. Create the new entities with `create_entities`, then the relations with `create_relations`.
   - If writing the file directly instead: write the parsed records back in canonical order (entities first, then relations), replacing the file contents entirely.

### 4. Verify and report

- Re-read the graph and compare counts (`entities`, `relations`) against the document.
- Report before → after counts, e.g. `23 entities / 56 relations` → `31 entities / 64 relations`.
- Confirm the import is complete and matches the source document.

## Guardrails

- **Replacement is destructive**: the current local graph is lost. Always show the "before" count and confirm with the user before deleting anything.
- Never push the imported graph to git, never commit it, and never merge it with another graph unless the user explicitly asks.
- Idempotent for the same document: re-importing the identical document yields the same result.

---
name: memory-export
description: Export the local per-user memory knowledge graph as a Markdown document with an embedded JSONL block, ready to copy and import on another machine. Use when the user wants to transfer their MCP memory graph to another machine, or when memory was updated and they want to export it.
disable-model-invocation: true
---

# Memory Export

Export the local memory graph to a portable Markdown document. The machine destination can import it with `/memory-import`.

## Deterministic format

The document MUST contain:

1. A short human-readable preamble (user, generated date, counts).
2. A fenced `jsonl` block that is the **single source of truth** — one line per record, exactly as stored by the MCP memory server. Structure:

```jsonl
{"type":"entity","name":"<name>","entityType":"<type>","observations":["<obs1>","<obs2>"]}
{"type":"relation","from":"<from>","to":"<to>","relationType":"<type>"}
```

## Process

### 1. Read the graph

Read the memory graph via the `memory` MCP (`read_graph` tool) to get all entities and relations. If the MCP is unavailable, read the file directly from `$MEMORY_FILE_PATH` (fallback `~/.local/share/opencode/memory/<user>.jsonl`).

### 2. Build the document

Produce a Markdown document with this exact structure:

```markdown
# Memory Graph Export

> user: <github-user>
> generated: <ISO-8601 timestamp>
> entities: <count> | relations: <count>

## Entities

<for each entity, in stable order:>
### <name>
- **Type:** <entityType>
- <observation 1>
- <observation 2>

## Relations

- `<from>` --<relationType>--> `<to>`

## Machine-readable (source of truth)

```jsonl
<one JSON line per entity, then one per relation>
```
```

Rules:
- **Stable ordering**: sort entities by `name`; sort relations by `from`, then `relationType`, then `to`. The document is deterministic for the same graph.
- The embedded `jsonl` block must contain the **complete** graph — it is the authoritative payload that `/memory-import` consumes.
- Never redact or reorder content in the `jsonl` block.

### 3. Deliver

- If the user asks for a file, write it to `memory-export.md` in the current directory.
- Otherwise print the full document in the response so the user can copy it.

## Out of scope

- Do not commit the export, do not push it, and do not send it anywhere unless the user explicitly asks.
- `/memory-import` on the destination machine performs the actual write; this skill only produces the document.

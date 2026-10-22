---
name: memory
description: Convention for the MCP memory knowledge graph — namespace entities by project key, record a date+reference on every observation, and verify staleness before trusting a recalled memory. Use when saving or recalling long-term memory, or consolidating the graph. Adapted from Engram's project-scoping and staleness ideas.
---

# Memory (knowledge-graph convention)

The MCP `memory` server is a per-user graph (entities → observations → relations) in a local JSONL file, **shared across all repos** and **never committed**. These conventions keep it trustworthy and project-scoped.

## Project key (scoping)

Derive the **project key** once per session:

- with a git remote → `owner/repo` (e.g. `lumusitech/AI`);
- without a remote → the repo directory basename.

**Prefix every entity name** with `<project-key>:<entity>` (e.g. `lumusitech/AI:cache-strategy`) and include the project key in observations. When recalling, **filter to the current project** unless the user explicitly asks for cross-project recall.

## Observation shape

Every observation records:

- **what** — the decision, convention, discovery, or ADR;
- **date** — when it was recorded;
- **reference** — the commit sha, path, or symbol it was derived from.

## Staleness (verify before trusting)

Never silently trust an old memory. On recall, **verify against current evidence**: if the referenced code or message no longer matches, the memory is **stale → suspicious context, not fact**. Surface it, then re-save or delete it once confirmed.

Lifecycle: treat memories as `active` unless disproven; a disproven one becomes `needs-review` until re-validated. Do **not** auto-promote a `needs-review` memory back to `active` without checking current evidence.

## Maintenance

- **Save proactively** after architecture/design decisions, established conventions, workflow changes, and tool/library choices with tradeoffs.
- **Consolidate duplicates**: if the same topic appears under different names, merge into one canonical `<project>:<topic>` entity.
- **Transfer**: to move the graph to another machine, `/memory-export` (Markdown + embedded JSONL) then `/memory-import` on the target (**replaces**, does not merge).
- **Never** store secrets, tokens, or personal data.

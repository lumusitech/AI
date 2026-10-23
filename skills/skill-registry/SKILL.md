---
name: skill-registry
description: Build a compact index of available skills (trigger + exact path) for delegation, so subagents receive exact SKILL.md paths instead of rediscovering the registry. Use after installing, removing, creating, moving, or renaming skills, or when a delegator needs a fresh index. Adapted from gentle-ai's skill-registry.
---

# Skill Registry

Use after installing, removing, creating, moving, or renaming skills, or when a delegator needs a fresh index.

## Hard rules

- The registry is an **index**, not a compiler or summary. `SKILL.md` remains the source of truth.
- **Do not inject compact rules**; preserve author intent by passing **exact skill paths** to subagents.
- Deduplicate by skill **name**, preferring **project-level** over **user-level** skills.
- Skip `_shared` (if present) and `skill-registry` itself.
- Write the index to a stable path (default `.atl/skill-registry.md`); add `.atl/` to `.gitignore` when the repo has one.
- No skills found → still write an empty registry so agents stop searching blindly.

## Scan order

1. Project: `.opencode/skills/*/SKILL.md`, `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`.
2. User/global: `~/.agent/skills/*/SKILL.md` (this workspace), `~/.config/opencode/skills/*/SKILL.md`, `~/.claude/skills/*/SKILL.md`.

Read frontmatter only as needed to extract `name` and `description` (the trigger text).

## Index format

```markdown
# Skill Registry

| Skill | Trigger (description) | Scope | Path |
|-------|----------------------|-------|------|
| tdd | Apply test-first development ... | user | ~/.agent/skills/tdd/SKILL.md |
```

## Decision gates

| Situation | Action |
|---|---|
| Same skill globally and in project | Keep the **project-level** skill. |
| Same skill in multiple global locations | Keep the first source in scan order. |
| No skills found | Write an empty registry. |
| Agent will delegate work | Select matching rows and pass their **exact** `SKILL.md` paths. |

> In this workspace `skills/README.md` is the **human catalog** (with categories); this registry is the **delegation index** (trigger → path). Keep them consistent when skills change.

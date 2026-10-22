---
name: skill-creator
description: Create LLM-first skills with valid frontmatter, a concise body, and local references. Use when authoring a new SKILL.md, documenting an AI usage pattern, or when project conventions differ from generic best practices. Adapted from gentle-ai's skill-creator.
---

# Skill Creator

Create a **runtime instruction contract for an LLM**, not human documentation.

## Activation contract

Create a skill when:
- A pattern is used repeatedly and the agent needs guidance.
- Project-specific conventions differ from generic best practices.
- A complex workflow needs step-by-step instructions.
- A decision tree helps the agent choose the right approach.

**Do not** create a skill when the pattern is trivial, one-off, or better served by normal documentation.

## Hard rules

- **No `Keywords` section.** Preserve the essential trigger words in `description` (that is what the model sees in `<available_skills>`).
- **References must point to local files** (never external URLs in the body).
- **Keep the body concise:** target 180–450 tokens, recommended max 700, hard max 1000.
- **Frontmatter:** only `name` + `description` are required; both must be present for discovery. `name` must match the directory and be lowercase alphanumeric with single hyphens.
- `disable-model-invocation` is **ignored by OpenCode** (Claude/Antigravity convention). To hide a skill from the model inventory but keep it loadable by exact name, use `metadata: { opencode/autoinvoke: "false" }`.

## Decision gates

| Need | Action |
|---|---|
| Code templates, schemas, fixtures, generated examples | Put them in `assets/` |
| Conceptual detail, edge cases, existing docs | Put local links in `references/` |
| Long explanation in `SKILL.md` | Move it to a supporting file |
| Multiple meaningful paths | Add a compact decision table |

## Execution steps

1. If the repo has a skill style guide, apply it first; otherwise use these inline rules.
2. Confirm the pattern is worth a skill (see Activation contract).
3. Write `SKILL.md` with `name` + `description`, a short "When to use", and the concrete rules.
4. Move long detail to `references/` or `assets/`.
5. Verify discovery: the skill should appear in `<available_skills>`; Antigravity auto-exposes it as `/<skill-name>`.

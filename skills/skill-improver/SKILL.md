---
name: skill-improver
description: Audit and upgrade existing SKILL.md files — fix frontmatter, trim to the body budget, convert tutorial prose to runtime instructions and decision tables. Use when asked to audit, refactor, normalize, or improve a skill. Use skill-creator to author brand-new skills. Adapted from gentle-ai's skill-improver.
---

# Skill Improver

Use when asked to **audit, refactor, normalize, or improve existing** `SKILL.md` files. Use `/skill-creator` instead when creating a brand-new skill.

## Hard rules

- If the repo has a skill style guide, treat it as the normative contract; otherwise use `/skill-creator`'s inline rules.
- `SKILL.md` is the **source of truth** — preserve the author's intent, critical rules, activation semantics, and output requirements.
- **Audit-only by default.** Modify files only when the user explicitly asks to apply improvements.
- **Never silently delete meaningful content** — move long explanation, examples, templates, or schemas into local `references/` or `assets/`.
- Do **not** invent triggers, policies, or domain rules; mark ambiguous cases for human review.
- Vocabulary: trigger vocabulary lives in `description` (that is what the model sees); do not add a `Keywords` section.

## Decision gates

| Situation | Action |
|---|---|
| Missing/invalid frontmatter | Fix `name` and one-line `description`. |
| Reads like tutorial docs | Convert to runtime instructions; move background to `references/`. |
| Body exceeds budget | Preserve rules; move examples/background to supporting files. |
| Branching logic hidden in prose | Convert to a compact decision table. |
| Rules conflict or intent unclear | Report it; do not auto-rewrite that rule. |
| `disable-model-invocation` used | Flag: ignored by OpenCode; the real switch is `metadata.opencode/autoinvoke: "false"`. |

## Execution steps

1. Read the style guide (or `/skill-creator`'s inline rules).
2. Enumerate target skills (`skills/*/SKILL.md` or paths given).
3. For each, audit: `name` matches directory; one-line `description`; body budget (target 180–450 tokens, max 700/1000); section order (when to use → rules → decision gates → steps → output); no `Keywords`; references are local files.
4. Report findings per skill (what and why). **Apply only if the user asked.**

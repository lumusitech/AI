---
name: plan-phases-implement
description: Implement exactly ONE phase of a plan created by /plan-phases-create, then stop. Never commits or pushes automatically. Use when a plan file exists in .agents/plans and you are asked to implement the next pending phase.
disable-model-invocation: true
user-invocable: true
---

# Plan Phases Implement

Implement **exactly one phase** of an existing plan, then STOP. This skill is the "Implement" half of the Research-Plan-Implement loop.

## Rules

- Implement **ONE phase per invocation**, then STOP.
- **Never commit or push automatically.** Only suggest commit messages.
- Detect the current phase: the first phase with at least one unchecked `- [ ]` checkbox.
- If a step does not fit the plan, **do not force it**: mark it for iteration and return to `/plan-phases-create` (the "Research" or "Plan" loop) before continuing.

## Process

### 1. Locate the plan and current phase

Read the plan file(s) under `.agents/plans/`. Find the plan for the current work. The **current phase** is the first phase with at least one unchecked `- [ ]` checkbox.

### 2. Implement the phase

Implement exactly that phase, following the plan's description and its public contracts. Use the project's conventions and AGENTS.md.

### 3. RPI loop (fit check)

While implementing, if a step does not fit the plan — a contract changes, an assumption is wrong, or the plan is unclear — **do not force it**. Instead:

1. Stop implementing that step.
2. Note the discrepancy for the user.
3. Return to `/plan-phases-create` to revise the plan (or run research first if the gap is an unknown).
4. Resume only once the plan is updated.

Do not silently deviate from the approved plan.

### 4. Verify

Run typecheck, lint, and tests for the phase. Run single test files regularly, and the full test suite once at the end. Fix anything that fails.

### 5. Update the plan file

After the phase passes verification:

- Tick the phase's checkboxes `- [ ]` → `- [x]`.
- Update the frontmatter with implementation metadata:

```yaml
implemented_by:
  tool: opencode
  model:
    name: deepseek-v4-flash
    version: latest
last_implementation_at: 2026-01-16T12:00:00Z
has_completed_all_phases: false
```

Set `has_completed_all_phases: true` if all phases are now checked.

### 6. STOP and suggest commit messages

STOP. Present the changes for review and suggest **3 alternative commit messages** in Spanish, each with a different type (e.g. `feat:`, `fix:`, `refactor:`, `docs:`), following conventional commits. Make them easy to answer, e.g. "commit with message 1".

If this was the last phase, suggest exporting the conversation as a `.md` file next to the plan.

## Commit message rules (Spanish)

- Format: `type: resumen imperativo` (type in English, summary in Spanish)
- Summary: imperative present, lowercase, no trailing period
- Types: feat, fix, docs, style, refactor, perf, build, ci, chore, revert, test

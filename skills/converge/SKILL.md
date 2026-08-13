---
name: converge
description: >
  Assess the current codebase against a feature's spec, plan, and tasks, then append
  any remaining unbuilt work as new tasks so implementation can be completed.
  Post-implementation gap analysis. Adapted from github/spec-kit (speckit-converge)
  to run standalone, without the specify CLI. Use after a phase or feature has been
  implemented and you want to close the remaining gaps.
---

# Converge

After implementation, compare what was actually built against what the spec, plan,
and tasks said should be built, and append the remaining work to the task list. The
intent artifacts (spec, plan, tasks) are the single source of truth; the constitution
is the governing constraint.

## Hard rules

- **Append-only.** The ONLY write is appending a `## Phase N: Convergence` section to
  the end of `tasks.md`. Never modify the spec, plan, or code. Never renumber or
  rewrite existing tasks.
- **Not a diff tool.** Do not use `git diff`, branch compare, or VCS history. Assess
  the current files on disk against the intent artifacts.
- **Require the artifacts.** If `spec.md` / `plan.md` / `tasks.md` (or equivalents)
  are missing, stop and report what is missing.
- **Constitution `MUST` violations are `CRITICAL`.**

## Inputs

- `ARTIFACTS` (optional): paths to the intent artifacts. Discover defaults:
  `spec.md`, `plan.md`, `tasks.md`, `.agents/plans/*/*-plan.md`.
- `CONSTITUTION` (optional): `.agents/constitution.md`; fallback `AGENTS.md`.
- `TASKS_FILE` (optional): where to append, default `tasks.md` next to the plan.

## Gap types

- `missing` — intended work with no implementation found.
- `partial` — implemented but incomplete against the acceptance criteria.
- `contradicts` — implemented differently than specified.
- `unrequested` — code exists that no artifact requested (surface for awareness,
  never delete).

## Severity

- `CRITICAL` — violates a constitution `MUST`, or missing/contradicts work that
  blocks the baseline of a priority-1 user story.
- `HIGH` — gap in a core requirement or success criterion.
- `MEDIUM` — secondary gap, or ambiguous `unrequested`.
- `LOW` — polish.

## Procedure

1. **Build the intent inventory.** Extract stable keys from the artifacts:
   `FR-###`, `SC-###`, `AC#`, user-story IDs, plan decisions, constitution principles.

2. **Map the code scope.** Collect the files referenced by the plan and tasks; scan
   them (plus keyword search) to see what exists.

3. **Assess.** For each requirement and task, classify the finding:
   `missing` / `partial` / `contradicts` / `unrequested`, with a severity.

4. **Present findings first.** Show the table, then append — never the reverse:

   ```
   ## Convergence Findings
   | ID | Gap Type | Severity | Source | Evidence | Remaining Work |
   |----|----------|----------|--------|----------|----------------|
   | C1 | missing  | HIGH     | FR-002 | no files | Implement login flow |
   ```

   Include metrics (requirements assessed, tasks complete, findings by severity).

5. **Append remaining work** to the end of `tasks.md`:

   ```
   ## Phase N: Convergence

   - [ ] T042 <imperative description> per <source-ref> (<gap-type>)
   ```

   - `<source-ref>` examples: `FR-003`, `SC-002`, `US1`, `AC2`,
     `plan: decision`, `Constitution II`.
   - New task IDs continue from the highest existing task ID (`T042` after `T041`),
     zero-padded to three digits. Constitution-derived tasks go FIRST.
   - If a `## Phase N: Convergence` section already exists, create the next numbered
     phase below it instead of merging.

6. **If everything is complete:** leave `tasks.md` byte-for-byte unchanged and
   report `✅ Converged — the implementation satisfies the spec, plan, and tasks.`

## Output

The findings table and (when gaps exist) the appended `## Phase N: Convergence`
section. Never modify any file other than appending to `tasks.md`.

## Related skills

- analyze — cross-artifact consistency analysis, run before implementation.
- plan-phases-create — produces the plan whose gaps converge closes.
- plan-phases-implement — executes phases; converge feeds it new pending tasks.

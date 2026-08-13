---
name: analyze
description: >
  Perform a non-destructive cross-artifact consistency and quality analysis across a
  project's spec, plan, and tasks (or the equivalent artifacts that exist: CONTEXT.md,
  plans under .agents/plans/, spec.md, tasks.md). READ-ONLY — emits a report only.
  Adapted from github/spec-kit (speckit-analyze) to run standalone, without the
  specify CLI. Use after tasks/plan generation and before implementation starts.
---

# Analyze

Cross-check the project's intent artifacts (spec, plan, tasks) against each other and
against the constitution, and report consistency and quality findings. This skill is
strictly read-only: it never edits artifacts.

## Hard rules

- **Read-only.** Never modify `spec`, `plan`, `tasks`, or any code. Only produce a
  report in the conversation.
- **Require at least two artifacts.** Analyze needs the intent surface: at minimum a
  plan and its tasks, or a spec and a plan. If only one artifact exists, say so and
  analyze just it.
- **Constitution is non-negotiable.** Any conflict with a constitution `MUST` is
  `CRITICAL` automatically.
- **Cap at 50 findings.** Beyond that, note the overflow count and stop.
- **Remediation is opt-in.** Offer concrete remediation edits only after the user
  explicitly approves.

## Inputs

- `ARTIFACTS` (optional): paths to analyze. By default discover what exists:
  `spec.md`, `CONTEXT.md`, `.agents/plans/*/*-plan.md`, `tasks.md`, `plan.md`.
- `CONSTITUTION` (optional): path to `.agents/constitution.md`. If absent, use
  `AGENTS.md` as the governing constraint.

## Detection passes

- **A. Duplication** — near-duplicate requirements or tasks.
- **B. Ambiguity** — vague adjectives without a measurable criterion
  (`fast`, `scalable`, `secure`, `intuitive`, `robust`), placeholder tokens
  (`TODO`, `TKTK`).
- **C. Underspecification** — verbs without a measurable outcome, user stories
  without acceptance criteria, tasks referencing undefined files.
- **D. Constitution alignment** — conflicts with `MUST` rules (`CRITICAL`),
  missing mandated sections.
- **E. Coverage gaps** — requirements without tasks, tasks without requirements,
  buildable success criteria not reflected in tasks.
- **F. Inconsistency** — terminology drift, data entities in the plan absent from
  the spec, contradictory task ordering, mutually exclusive requirements.

## Severity

`CRITICAL` > `HIGH` > `MEDIUM` > `LOW`:
- `CRITICAL` — violates a constitution `MUST`, or blocks a core requirement.
- `HIGH` — core requirement/acceptance-criteria gap.
- `MEDIUM` — secondary gap or ambiguous-but-harmless wording.
- `LOW` — polish, minor inconsistency.

Assign stable IDs per category (`A1`, `B1`, `C1`, ...).

## Report format

```
## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| B1 | Ambiguity | HIGH | spec.md §2 | "fast" has no criterion | Add a measurable SLO |

## Coverage Summary

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|

## Constitution Alignment Issues
- ...

## Metrics
- Total Requirements: N
- Total Tasks: M
- Coverage: NN%
- Ambiguity Count: N
- Duplication Count: N
- Critical Count: N
```

## Procedure

1. **Inventory artifacts.** Read every artifact present; record stable keys
   (`FR-###`, `SC-###`, `AC#`, plan decisions, constitution principles).
2. **Map coverage.** Build a requirement→task map; compute coverage %.
3. **Run the six passes.** Cap at 50 findings total.
4. **Emit the report.** Include findings, coverage table, alignment issues, metrics.
5. **Next actions.**
   - `CRITICAL` → resolve before implementing.
   - `HIGH` → resolve or get explicit user sign-off before implementing.
   - `MEDIUM`/`LOW` → can proceed; list suggestions.
6. **Offer remediation** only with explicit approval (`Would you like me to suggest
   concrete remediation edits?`).

## Output

The markdown report in the conversation. No files written.

## Related skills

- checklist — validates requirements quality; run it before or after analyze.
- to-spec — produces the spec under analysis.
- plan-phases-create — produces the plan; a plan that contradicts its spec surfaces
  here as F/C findings.

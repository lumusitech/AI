---
name: checklist
description: >
  Generate a custom review checklist for a feature, spec, or plan. Checklists are
  "unit tests for requirements writing" — they validate the QUALITY of requirements
  (completeness, clarity, consistency, measurability, coverage, edge cases), not the
  implementation. Adapted from github/spec-kit (speckit-checklist) to run standalone,
  without the specify CLI. Use after writing a spec or plan and before implementing.
---

# Checklist

Create a checklist that a reviewer uses to judge whether the requirements behind a
feature are well-formed enough to build. If the spec is code written in English, this
checklist is its unit-test suite.

## Hard rules

- **Validate requirements, not behavior.** Checklist items NEVER start with
  `Verify`, `Test`, `Confirm`, or `Check` followed by behavior, and never reference
  execution or UX ("displays correctly", "click", "render").
- **Write items as questions.** Correct shape:
  `Are [requirement type] defined/specified for [scenario]?`
  tagged with `[Completeness]` / `[Clarity]` / `[Consistency]` / `[Gap]` /
  `[Ambiguity]` / `[Conflict]` / `[Assumption]` / `[Traceability]` and a
  reference like `[Spec §X.Y]`.
- **Append, never rewrite.** If the target checklist file exists, append new items;
  never delete or renumber existing ones.
- **The reviewer checks the boxes, never the agent.** New items are written
  unchecked (`- [ ]`) and stay that way.
- **At least 80% of items must carry a reference or marker.**
- **Max 5 clarification questions** to the user (3 first, 2 follow-ups only if
  needed).

## Inputs

- `TARGET` (required): the artifact to checklist — a spec, a plan, or a feature
  description. Detect from the repo: `spec.md`, `CONTEXT.md`, a plan under
  `.agents/plans/`, or the current conversation. Ask which one if ambiguous.
- `DOMAIN` (optional): filename domain — `ux`, `api`, `security`, `performance`,
  or `requirements`. Default `requirements`.
- `OUT_DIR` (optional): where to write the checklist, default
  `checklists/<domain>.md` next to the target artifact (or in the repo root).

## Procedure

1. **Identify the target.** Read the artifact fully. If none exists, summarize the
   requirements from the conversation and confirm with the user.

2. **Set the next ID.** If the target checklist file exists, find the highest
   `CHK###` and continue from `CHK###+1`. Otherwise start at `CHK001`.

3. **Collect domain context.** Up to 5 dynamic clarification questions across:
   scope refinement, risk prioritization, depth calibration, audience framing,
   boundary exclusion, scenario-class gaps. Ask at most 3 up front.

4. **Draft items** across the quality categories:
   - Requirement Completeness / Clarity / Consistency
   - Acceptance Criteria Quality
   - Scenario Coverage / Edge Case Coverage
   - Non-Functional Requirements
   - Dependencies & Assumptions / Ambiguities & Conflicts

5. **Prioritize.** If more than ~40 items, sort by risk and drop the tail; merge
   duplicates. Each item keeps an `ID | Marker | Question | Ref` shape.

6. **Write the file** (append-only). Present the checklist to the user after
   writing; only the user/reviewer marks items `[x]`.

## Output

`checklists/<domain>.md` appended with the new unchecked items, plus a short summary
of how many items were added and what the coverage markers look like.

## Related skills

- analyze — cross-artifact consistency analysis; use it after the checklist passes.
- to-spec — produces the spec this checklist reviews.
- plan-phases-create — scopes phases; a plan should satisfy the checklist too.

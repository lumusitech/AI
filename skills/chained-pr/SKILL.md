---
name: chained-pr
description: Split oversized changes (over ~400 changed lines) into chained or stacked PRs that protect review focus. Use when a PR may exceed ~400 changed lines, when work-unit commits grow past that, or when the user asks for chained/stacked PRs or review slices.
---

# Chained PR

Load when a planned PR may exceed **400 changed lines**, a work-unit commit count grows past ~400, or the user asks for chained/stacked PRs or review slices.

## Hard rules

- Split PRs over **400 changed lines** unless a maintainer explicitly accepts a size exception.
- The budget constrains how work is **sliced**, never the code itself: never delete comments, blank lines, docs, or tests, and never compress or restyle code to fit.
- Slicing is bounded: make **one** honest slicing pass. If no cohesive split brings every slice within budget, stop, keep the best split, and report the line count.
- Keep each PR reviewable in about **≤60 minutes**.
- One deliverable work unit per PR; keep tests/docs with the unit they verify (see `/work-unit-commits`).
- State start, end, prior dependencies, follow-up, and out-of-scope items in every chained PR.
- Every child PR includes a dependency diagram marking the current PR with `📍`.
- Treat a polluted diff as a base bug: retarget or rebase until only the current work unit appears.
- Do not mix chain strategies once one is chosen.

## Decision gates

| Condition | Action |
|---|---|
| PR ≤400 changed lines and focused | Keep a single PR. |
| >400, each slice lands independently | Stacked PRs to `main`. |
| >400, feature must integrate before `main` | Feature-branch chain with a tracker PR. |
| Generated/vendor/migration diff cannot split cleanly | Ask the maintainer for a size exception. |
| No cohesive split fits after one pass | Stop; deliver the best split, report the overage, recommend the exception. |

## Chain strategies

- **Stacked PRs** — each PR targets `main`; slice N+1 branches off slice N.
- **Feature-branch chain** — a draft/no-merge **tracker PR**; child #1 targets the tracker branch, later children target their immediate parent branch.

Combine with `/branch-pr` for naming, the PR title, and issue linking.

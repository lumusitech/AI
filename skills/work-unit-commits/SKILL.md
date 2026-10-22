---
name: work-unit-commits
description: Plan commits as reviewable work units, not by file type. Use when splitting a feature into commits, preparing commits before a PR, keeping tests and docs with the code they explain, or turning a large change into chained/stacked PRs. Adapted from gentle-ai's work-unit-commits.
---

# Work Unit Commits

A commit represents a **deliverable behavior, fix, migration, or docs unit** — a reviewable slice a reader can understand from its diff and message alone.

## Critical rules

| Rule | Requirement |
|---|---|
| Commit by work unit | A commit is a deliverable behavior, fix, migration, or docs unit. |
| Do not commit by file type | Avoid `models`, then `services`, then `tests` if none works alone. |
| Keep tests with code | Tests belong in the same commit as the behavior they verify. |
| Keep docs with the change | Docs belong with the feature or workflow they explain. |
| Tell a story | A reviewer should understand why each commit exists from its diff and message. |
| Future PR-ready | Each commit should be a candidate chained PR when the change grows. |
| Budget is not code-golf | Never shrink a diff by deleting comments, blank lines, docs, or tests, or by compressing code, to fit a review budget. Slice by work unit or report the overage. |

## Work unit checklist

Before committing, confirm:

- [ ] The commit has one clear purpose.
- [ ] The repo still makes sense after applying only this commit.
- [ ] Tests or docs for this unit are included when relevant.
- [ ] Rollback is reasonable without reverting unrelated work.
- [ ] Focused test command and exact result are recorded.
- [ ] Runtime harness command/scenario and exact result are recorded, or explicit `N/A` explains why no runtime boundary exists.
- [ ] Rollback boundary names the exact files/behavior removable without unrelated work.
- [ ] The commit message explains the **outcome**, not the file list.

## Split examples

| Weak split | Better work-unit split |
|---|---|
| `feat: models`, then `feat: services`, then `feat: tests` | `feat: add <feature> end-to-end` (behavior + its tests + docs) |
| `refactor: rename X across repo` | Expand–contract: `refactor: add new form beside old`, then migrate call sites in batches, then `refactor: remove old form` |
| `chore: fix lint` mixed with feature work | Fix lint in the commit that introduces the offending code, or as its own unit before the feature |

## Chained / stacked PRs

When a change grows beyond one reviewable commit, sequence commits so each is a candidate chained PR (each blocked by the previous). Keep CI green commit to commit; green is promised only at the integrate-and-verify boundary when batches cannot stay green alone.

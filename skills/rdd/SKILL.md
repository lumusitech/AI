---
name: rdd
description: Receipt-Driven Development — freeze the exact candidate before review, set review depth from the candidate's risk tier, and treat review as a separate choice whose result is informational (never authorizes commit/push/release). Use when you want a review whose evidence belongs to the exact version you will rely on.
---

# RDD (Receipt-Driven Development)

RDD makes a review **not drift**: the candidate is **frozen before anything reads it**, so the evidence belongs to the exact version you are about to rely on — not to whatever the worktree looked like a moment later.

## Rules

- **Separate choice.** RDD is opt-in. Its result is **informational**: it never authorizes commit, push, PR, or release — ordinary repository policy decides delivery.
- **Freeze first.** Snapshot the exact candidate and hash it **before** any reviewer reads it. Review only the frozen artifact.
- **Depth from the candidate, not the model.** The frozen candidate's **risk tier** sets review depth — never the model's judgment, a checkbox, or an estimate.
- **Fixes create a new candidate.** Any change invalidates the frozen candidate; re-freeze and re-review. Never resume stale authority.
- **Fail closed.** If the candidate cannot be frozen, do not fabricate approval; report `disabled/unmanaged` and follow ordinary policy.

## Risk tiers

- **High** — auth, update, security, payments paths; shared contracts; concurrency; delivery; or **>400 changed lines**: full review, all four lenses via `/review` (R1 risk, R2 readability, R3 reliability, R4 resilience).
- **Standard** — the lenses that match the change's surface.
- **Low** — docs, comments, formatting, no behavior change: exempt; run ordinary checks only.

## Flow

1. **Freeze** — record the candidate identity as a hash of the exact change (e.g. `git diff HEAD | sha256sum` plus the list of untracked files). Do not mutate the worktree to freeze.
2. **Tier** — classify the **frozen** diff by paths and line count; pick depth.
3. **Review** — run `/review` against the frozen candidate only (one lens per pass).
4. **Receipt** — record candidate hash, tier, findings, and verdict. The receipt carries **no** delivery authority.
5. **Deliver** — under ordinary repository policy (commit/push/PR are separate human decisions).

## Output

Return the candidate hash/identity, the assigned tier, the findings, and the verdict — clearly marked as **informational, not a delivery gate**.

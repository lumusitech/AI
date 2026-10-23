---
name: judgment-day
description: Dual blind adversarial review — two independent read-only judges on one frozen target, corroborated findings, fix only what both confirm, at most two rounds. Use when explicitly asked for adversarial/dual review of a concrete target. Adapted from gentle-ai's judgment-day.
---

# Judgment Day (dual blind adversarial review)

Load **only** when explicitly requested (Judgment Day, dual review, adversarial review) for a concrete target. It **replaces** an ordinary single-lens pass for that target — **never run both**.

## Hard rules

- **Freeze one immutable target**, then launch **two blind read-only judges in parallel** with identical scope and criteria. They must not coordinate before returning.
- Each judge returns **one neutral findings result** and terminates. **Wait for both**; never accept a partial judgment.
- The **parent** merges findings into a **frozen ledger**; only the parent launches fixes and re-judgment.
- **Fix only severe findings confirmed by both judges.** WARNING and SUGGESTION rows stay informational.
- **At most two fix rounds and two scoped re-judgments.** Re-judgment sees only the frozen ledger plus the fix delta, and may record fix-caused defects.
- Terminal verdicts: **`APPROVED` | `ESCALATED`**. Never reset or extend the round budget.
- A judgment issues **no receipt** and carries **no delivery authority** — commit, push, PR, and release remain under ordinary repository policy.
- **Two-judge agreement is the corroboration mechanism.** Never add a third refuter.

## Judges

Both judges run read-only through the four lenses (`/review` R1–R4), independently:

- **Judge A** — correctness, regressions, missing tests, unsafe behavior, and mismatches with the user's request.
- **Judge B** — the same scope, **blind to A**, with emphasis on edge cases, error paths, and hidden coupling.

Dispatch as **two separate read-only passes** (e.g. `subagent` with a generic agent, or two standalone `/review` runs), giving each the **same frozen target** and criteria. Do not let the second see the first's output.

## Decision gates

| Condition | Action |
|---|---|
| Target unclear | Ask one scope question; stop. |
| Both judges confirm a severe finding | Ask before round-one correction; then fix only the confirmed IDs. |
| One judge reports it | Record as `suspect`; do **not** auto-fix. |
| Judges contradict | Escalate for an explicit human decision. |
| Scoped re-judgment fails before round two | Parent may launch the final bounded fix round. |
| Any issue remains after round two | **Escalate** and stop. |

## Output

Return: **target identity**, **round**, and counts of **confirmed / suspect / contradiction / info**, plus the terminal verdict (`APPROVED` | `ESCALATED`) and any remaining risks.

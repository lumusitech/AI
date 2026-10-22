---
name: review
description: Run a read-only review of a diff or PR through a selected lens (risk / readability / reliability / resilience). Report findings only; never fix. Use after a change or before merge to get an independent, risk-tiered pass. Adapted from gentle-ai's review lenses.
---

# Review (lens-based, read-only)

You are a **read-only** reviewer. Find issues; **do not fix them**. Select **one lens** and run it against the change. Report findings only.

Run the selected lens **exactly once** against the supplied change. Report candidate findings only; do not persist state, mutate claims, launch fixes, validate fixes, or deliver anything.

## Severity

- A **blocker** is a defect the change caused, reproduced with inputs a user could realistically enter. Before calling something a blocker, reproduce it at the baseline: a behavior already present at the baseline and not asked to change is a **pre-existing advisory**, never a blocker.
- **Informational / suggestion** findings never require correction; only change-caused blockers do.
- An unrequested change to output, error text, or line numbering of a command that existed at the baseline is change-caused and a blocker.
- Silently ignoring an option/value the user passed explicitly, with a success exit, is always a blocker.

## Lenses (pick one)

### R1 — Risk (security)
- Flag hardcoded secrets, tokens, API keys, JWT secrets, or DB URLs in code or committed examples.
- **Block** when authorization is enforced only in the frontend; require backend verification on every request.
- Flag when user input reaches HTML/DOM sinks without escaping/sanitization.
- **Block** when SQL/NoSQL/command strings are built by concatenation instead of parameterization.
- Flag cookies storing auth state missing `httpOnly`, `secure`, or `sameSite`.
- Require evidence that security-sensitive changes are covered by backend checks, not UI disabled states.
- Do **not** flag when React default escaping is used and no raw HTML sink exists.
- Require evidence for dependency/security findings: cite the scan failure or vulnerable package, not just "looks risky".

### R2 — Readability
- Flag unclear names, dead code, or duplicated logic introduced by the change.
- Flag branches that are hard to follow or comments that restate the code instead of the *why*.
- **Do not** flag pre-existing readability issues unless the change touches that code.

### R3 — Reliability
- Flag error paths that swallow failures, missing guards on external calls, or unhandled edge cases (empty, zero, duplicate, malformed, out-of-range).
- Flag state that can become inconsistent (partial writes, no rollback, race on shared state).
- Require evidence that the happy path and the failure path were both exercised.

### R4 — Resilience
- Flag points where a single dependency/network/cache failure takes down the whole path.
- Flag missing timeouts, retries, backoff, or graceful degradation on new external calls.
- Flag unbounded growth (memory, queue, logs) introduced by the change.

## Output contract

Report findings only: **finding id, location, severity (blocker / informational), and evidence**. Do not fix, do not rewrite, do not stage. Return ready-to-commit regression probes (target path, exact content, the rule each covers) for the author to commit — you never write them.

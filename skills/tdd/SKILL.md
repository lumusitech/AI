---
name: tdd
description: Apply test-first development (RED → GREEN → PRESERVE → REFACTOR) to a behavior change with a runnable deterministic test and a clear expected outcome. Use when implementing a requested rule or touching an existing command/option that shares changed code, and a relevant test exists. Adapted from gentle-ai's ODD test-first policy.
---

# TDD (Test-First Development)

Apply the ODD **test-first** policy by default for **behavior changes** with an applicable runnable deterministic test and a clear expected outcome. **Test presence alone does not establish applicability** — a test is applicable when it is runnable, deterministic, and has a clearly expected outcome.

For **passive documentation, non-testable changes, an unavailable runner, or no meaningful RED**, state the specific exception and run proportionate ordinary functional or structural verification. **Never claim RED/GREEN evidence you did not observe**, and never skip checks because test-first was "inapplicable".

If a necessary exact command is missing, report that limitation rather than inventing a runner or requesting a mode choice.

## The cycle

### 1. RED
For **each requested rule**, add **one** behavior-level test that captures the observed failure before implementation. Each test asserts **every observable effect** of the rule it covers:

- exit code,
- exact stdout and stderr,
- and that rejected input leaves stored data and counters unchanged.

Cover the cases the rule itself names: its examples, boundaries, and errors. Check through the **public interface**, never internal storage.

### 2. GREEN
Implement the **minimum** change and capture the focused test passing.

### 3. PRESERVE
For **every existing command or option the change touches**, add **one** test proving its previous behavior still holds; **add no other cases**. An existing behavior counts as touched when it shares the code you changed (options, parsers, helpers, validation). These are expected to pass, so they need **no RED run**.

Before finishing, run a **differential check**: for each existing command that shares the code you changed, run it with the new/changed input against the previous code (a copy of the base commit in a `mktemp -d` scratch directory — never committed as a test) and against your change, and compare stdout, stderr, and exit code. Any difference nobody asked for is a regression to fix and pin with a test.

### 4. REFACTOR
Improve clarity **only while focused tests remain green**.

## Rules

- **One focused write thread.** Change only the files the change requires; preserve existing architecture and conventions; avoid drive-by refactors and dependency changes.
- **Prefer the highest seam; reuse existing seams.** Before creating or changing shared state, find the existing function that already does it and reuse it, keeping every invariant it enforces.
- **Test through the public interface**, never internal storage.
- When you add or change a command, option, or message, **update the help text and docs** that describe it.
- **One correction attempt** per failing check; a second only if the same check still fails after a real fix; then stop and report — never loop.
- Do not claim completion while required validation is failing.

## Test hygiene

- Keep test scratch state (temp dirs, `HOME`, `TMPDIR`, tool caches) **outside the worktree** in a `mktemp -d` directory. If it must live inside the worktree, use a path git excludes and remove it through the test's own cleanup.
- Tests delete the temp directories they create in teardown; name any scratch directory created outside the worktree so the caller can remove it.
- Run **focused tests first**. Broad suites, builds, formatters, or linters run only when explicitly authorized.
- Before returning, run `git status --short` and confirm it lists **no** tool cache or scratch path; report any that remains instead of deleting it outside the allowed edit surface.

## Framework details

For the framework-specific mechanics (assertions, mocks, setup, snapshots), defer to the dedicated skill rather than duplicating here:

- JavaScript/TypeScript → `jest-skill`
- Java → `junit-5-skill`
- E2E / browser → `cypress-skill` / `e2e-testing`
- API → `api-security-testing`

## Independent verification (optional)

For a high-risk change (data, security, shared contracts, concurrency, delivery, or no test that would catch a regression), delegate a **read-only** verifier that **derives its own probes** from the spec — it does **not** trust the writer's tests (a writer's test can lock a bug in):

- Derive probes from the verbatim request and every numbered rule: positive, negative and boundary cases (empty, zero, duplicate, malformed, out-of-range), and the exact error messages and exit codes the request states.
- Check invariants: stored data stays byte-identical after every rejected/failing command (hash before/after on the isolated data file).
- Check interactions: new data flowing through existing reports, totals, exports, filters, imports.
- Run the typecheck/build when the project has one; flag every changed file outside the request's scope.
- Observe RED before implementation and GREEN afterward; **do not infer RED from a test file existing or claim GREEN without observed execution**.

The verifier is **read-only**: it never edits, writes, or fixes findings; it returns evidence and ready-to-commit regression probes (target path, exact content, the rule each covers) for the writer to commit.

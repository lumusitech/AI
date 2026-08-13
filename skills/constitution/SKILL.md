---
name: constitution
description: >
  Create or update the project constitution — a versioned, semver-tracked set of
  non-negotiable principles and governance rules — written to .agents/constitution.md.
  Adapted from github/spec-kit (speckit-constitution) to run standalone, without the
  specify CLI. Use when starting a project, when governance rules change, or when the
  project needs an enforceable decision record that the agent must treat as binding.
---

# Constitution

Maintain a versioned **constitution** for the current project: a small set of
non-negotiable principles plus the governance rules that keep them enforceable.

## Hard rules

- **Governance only.** This skill NEVER executes features, writes application code,
  or runs build/test commands. If the request is not about the constitution, answer
  under a `Next actions` section suggesting the right command instead.
- **Every constitution change bumps the version.** No silent edits.
- **Never leave `[ALL_CAPS]` placeholder tokens in the file.**
- **A principle is not a rule until it is testable.** Write declarative statements,
  prefer `MUST` / `SHOULD` / `MUST NOT` over vague `should` phrasing.

## Inputs

- `PATH` (optional): target file, default `.agents/constitution.md` at the repo root.
  Falls back to the project root if `.agents/` does not exist.
- `CONTENT` (optional): principles supplied by the user. If empty, prompt for them.
- `INITIATIVE` (optional): free-text description of what changed, used for the
  commit message and the Sync Impact Report.

## Procedure

1. **Locate the current state.** If `.agents/constitution.md` exists, read it fully
   to extract the current version and existing principles. Otherwise, treat the
   project `AGENTS.md` / `README.md` as context to derive the first draft.

2. **Resolve the intended changes.** Collect new principles, amendments, or
   removals from the user. Restate them back before writing when anything is ambiguous.

3. **Classify the version bump** (semver):
   - `MAJOR` — a principle was removed or redefined incompatibly.
   - `MINOR` — a new principle or section was added.
   - `PATCH` — a clarification, wording fix, or governance detail.

4. **Update the file.**
   - Keep `RATIFICATION_DATE` at its original ISO date; set `LAST_AMENDED_DATE`
     to today (ISO) whenever content changes.
   - Replace every `[ALL_CAPS_IDENTIFIER]` placeholder with concrete values.
   - Each principle: one concise name line, one paragraph of non-negotiable rules,
     and (when useful) a short rationale.
   - Keep a short `## Governance` section: amendment procedure, versioning policy,
     and compliance expectations.

5. **Write the Sync Impact Report** as an HTML comment at the very top of the file:
   - version `vOld → vNew`
   - principles added / modified / removed
   - open `TODO`s
   - ratify / amend dates

6. **Validate.**
   - No `[ALL_CAPS]` tokens remain.
   - Every principle is declarative and testable; no ambiguous `should` where a
     `MUST`/`SHOULD` level exists.
   - Version and dates are consistent with the changes made.

7. **Suggest a commit.** Print the exact command, never run it:
   `git commit -m "docs: amend constitution to vX.Y.Z - <short summary>"`

## Output

The updated constitution file. After writing, present a short summary of the bump,
the count of principles (added / modified / removed), and the suggested commit message.

## Related skills

- plan-phases-create — uses the constitution as a constraint when scoping phases.
- to-spec — a spec should never contradict the constitution; run analyze first.
- analyze — flags constitution-alignment violations as CRITICAL.

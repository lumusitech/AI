---
name: conventional-commits
description: Write commit messages per the Conventional Commits v1.0.0 open standard, so tools (changelog, semantic-release, commitlint) work across any vendor. Use when writing or reviewing a commit message, splitting work into commits, or mapping commits to a SemVer release.
---

# Conventional Commits

Open standard: <https://www.conventionalcommits.org/en/v1.0.0/>. Vendor-neutral, tool-supported (commitlint, semantic-release, changelog generators). Language-agnostic — the description may be written in Spanish.

## Format

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

- **type** — required, from the list below.
- **scope** — optional, a noun in parentheses: `feat(auth): ...`.
- **`!`** before the colon marks a breaking change: `feat(api)!: ...`.
- **description** — imperative, no trailing period.

## Types

| Type | Meaning | SemVer |
|---|---|---|
| `feat` | A new feature | **MINOR** |
| `fix` | A bug fix | **PATCH** |
| `docs` | Documentation only | — |
| `style` | Formatting, no behavior change | — |
| `refactor` | Neither a fix nor a feature | — |
| `perf` | Performance improvement | — |
| `test` | Adding or fixing tests | — |
| `build` | Build system or dependencies | — |
| `ci` | CI configuration | — |
| `chore` | Maintenance, no source/test change | — |
| `revert` | Reverts a previous commit | — |

`feat` → MINOR, `fix` → PATCH; **any breaking change → MAJOR** (via `!` and/or a `BREAKING CHANGE:` footer).

## Breaking changes

Either `!` in the type/scope, or a footer:

```
BREAKING CHANGE: the request body now requires `session_id`
```

## Revert

```
revert: feat(api): add rate limiting

This reverts commit 1234abcd.
```

## Rules

- One logical change per commit; keep tests and docs with the code they belong to (see `/work-unit-commits`).
- Never shrink a diff by dropping comments, docs, or tests.
- A commit message explains the **outcome**, not the file list.

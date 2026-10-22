---
name: branch-pr
description: Branch naming and pull-request flow anchored on open standards — Conventional Branch names, a Conventional Commits PR title, GitHub Flow, and GitHub's standard issue-linking keywords. Use when creating a branch, opening or preparing a PR, or reviewing a diff. No vendor-specific labels or taxonomies.
---

# Branch & PR (standards-based)

Anchored on open, vendor-neutral standards so nothing breaks if a team, an individual, or a company changes its opinion.

## Branch naming — Conventional Branch

Standard: <https://conventional-branch.github.io/>. Use the same type set as Conventional Commits (1:1 with `commitlint`/`semantic-release`); lowercase; no spaces.

```
^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)/[a-z0-9._-]+$
```

Examples: `feat/user-login`, `fix/zsh-glob-error`, `docs/install-guide`. Optionally `<type>/<issue>-<desc>`: `feat/142-rate-limit`.

> Never branch work directly to the default branch — every change goes through a PR.

## PR title

A valid **Conventional Commits** subject (see `/conventional-commits`), e.g. `feat(api): add rate limiting`. Squash-merge keeps the changelog/semver correct.

## PR body

Use the repo's `.github/PULL_REQUEST_TEMPLATE.md` if present; otherwise these standard sections:

- **Summary** — 1–3 bullets of what and why.
- **Linked issue** — GitHub-standard keyword (below).
- **Changes** — table of files → change.
- **Test plan** — check boxes **only** for steps actually run and observed.
- **Notes / risks** — anything a reviewer must know.

### Linking issues (GitHub standard keywords)

- **Closing**: `Closes #N`, `Fixes #N`, `Resolves #N` — closes the issue **on merge**. Case-insensitive.
- **Non-closing**: `Refs #N`.
- Use well-formed references to issues in the **base** repository. An empty PR with no link and no description is not reviewable.

## Flow (GitHub Flow)

1. Branch from up-to-date default branch with a Conventional Branch name.
2. Commit in **work units** (`/work-unit-commits`) with Conventional Commits messages.
3. Push and open a PR; keep it small and single-purpose.
4. **Required CI** comes from the target branch's rulesets/branch protection — read it; do not infer requiredness from an optional pending check.
5. Review feedback uses **Conventional Comments** (below). Merge under ordinary repo policy.

## Review comments — Conventional Comments

Standard: <https://conventionalcomments.org/>. Form: `<label> [decorations]: <subject>`.

Labels: `praise`, `nitpick`, `suggestion`, `issue`, `todo`, `question`, `thought`, `chore`.
Example: `suggestion (non-blocking): extract this into a helper`.

## Human-owned decisions

**Commit, push, PR, and merge remain human decisions.** A review or a passing check never authorizes delivery — ordinary repository policy decides.

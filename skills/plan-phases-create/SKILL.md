---
name: plan-phases-create
description: Create a phased implementation plan for a large task. Interviews the user, explores the codebase, defines vertical-slice phases with public contracts, and writes the plan file only after user approval. Use when a task is too big for a single session or needs clear phases before implementing.
disable-model-invocation: true
user-invocable: true
---

# Plan Phases Create

Create a **phased implementation plan** for a large task. The plan splits the work into vertical slices (phases), each with its **public contracts**, so a later `/plan-phases-implement` invocation can execute exactly one phase per session.

## Rules

- **Ask for the task** if none was given.
- **Research first (optional):** for large tasks, unknown territory, or external APIs, run a research pass first and write the findings to `research.md` next to the plan. Reuse `/research` or delegate to subagents. Skip for small tasks where the codebase already answers the open questions.
- **Delegate exploration to subagents** (max 4, in parallel, cheap models). They report file paths + public contracts + conventions, NOT code dumps.
- **Let the user choose the number of phases** using the guidelines below (minimal / intermediate / very granular).
- **Specify public contracts per phase** (see `resources/plan-guidelines.md`).
- **Never write the plan file until the user approves** the phases and their contracts.
- Plan written in English (conversation can be in any language). Commit/PR messages suggested later are in Spanish.

## Phase-count guidelines (from resources/plan-guidelines.md)

- **Minimal**: 1 phase
- **Intermediate**: 1-3 phases
- **Very granular**: 3+ phases

## Process

### 1. Ask for the task

If the user did not provide a task, ask for it. Ask clarifying questions until scope is clear. If there are big unknowns, propose the optional research step.

### 2. Research (optional)

For **large tasks** (or when external systems / APIs are involved), produce a `research.md` before planning:

- Delegate to background subagents (`/research` or parallel subagents with cheap models).
- It must cite primary sources (docs, official SDKs) and report decisions — not dumps.
- Save it as `research.md` next to the plan file.

For small tasks, skip this step entirely.

### 3. Explore the codebase (delegated)

Delegate exploration to up to **4 subagents in parallel** (cheap models). Each subagent must report, for its area:

- File paths of the relevant modules
- Public contracts: app service signatures, domain events, test suites, DB schemas, UI copy
- Conventions and ADRs in the area

Ask for a concise report with file paths, not code dumps.

### 4. Define phases with the user

Present the proposed phase breakdown. Use the phase-count guidelines. Each phase must be a **vertical slice** (not a horizontal layer):

- Cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed phase is demoable / verifiable on its own
- Each phase compiles and passes its tests on its own
- Phase 1 always produces something visible / executable
- Prefer early feedback loops

### 5. Specify public contracts per phase

For each phase, list the public contracts it changes, omitting contract types that don't change (see `resources/plan-guidelines.md`):

- Application services: signatures
- Domain events: attributes
- Test suites: cases
- Database schemas: tables
- UI copy: user-facing strings

### 6. Approve before writing

Present phases + contracts and **stop**. Only write the plan file after the user approves.

### 7. Write the plan file

Save to `.agents/plans/{plan-name}/{plan-name}-plan.md`, where `{plan-name}` uses the format `YYYY_MM_DD-descriptive_slug` (e.g. `2026_01_16-create_embeddable_changelog_widget`).

Frontmatter (YAML):

```yaml
---
name: {plan-name}
description: One-line summary of the goal
created_at: 2026-01-16T10:00:00Z
created_by:
  tool: opencode
  model:
    name: deepseek-v4-flash
    version: latest
    reasoning_effort: high
---
```

Sections (per resources/plan-guidelines.md):

- **Goal**: 1-3 sentences
- **Context**: important file paths, real links, AGENTS.md, relevant docs
- **Phases**: numbered phases. Each phase ends with two tasks, in order:
  1. Run typecheck/lint/tests for that phase
  2. STOP, present the changes for review, and suggest commit/PR messages (in Spanish)
- **Next step**: one sentence

Use '-' or ':' in lists, never the em-dash '—'.

### 8. Suggest next steps

After writing the plan, offer:

- Do nothing
- Commit the plan as docs
- Implement with `/plan-phases-implement`
- Commit the plan and implement only phase 1

# Plan Guidelines

Guidelines for writing an implementation plan used by `/plan-phases-create`.

## Number of phases

Let the user choose the granularity:

- **Minimal**: 1 phase
- **Intermediate**: 1-3 phases
- **Very granular**: 3+ phases

## Public contracts

Per phase, specify the public contracts that the phase changes. **Omit any contract type that does not change**:

- Application services: signatures
- Domain events: attributes
- Test suites: cases
- Database schemas: tables
- UI copy: user-facing strings

## Plan sections

- **Goal**: 1-3 sentences.
- **Context**: important files (with real paths), real links, AGENTS.md, and relevant docs.
- **Phases**: vertical slices, NOT horizontal layer slices. Each phase compiles and passes its tests on its own. Phase 1 always produces something visible/executable. Prefer early feedback loops.
  - Each phase ends with two tasks, in order:
    1. Run typecheck/lint/tests for that phase.
    2. STOP, present the changes for review, and suggest commit/PR messages (in Spanish).
- **Next step**: one sentence.

## Style

- The plan file is written in English (the conversation can be in any language).
- Use '-' or ':' in lists, never the em-dash '—'.
- Commit and PR messages are suggested in Spanish.

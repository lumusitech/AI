---
name: cognitive-doc-design
description: Design docs that reduce cognitive load — lead with the answer, progressive disclosure, chunking, signposting, recognition over recall. Use when writing or editing guides, READMEs, RFCs, PR descriptions, architecture or onboarding docs.
---

# Cognitive Doc Design

Load when creating or editing documentation people must understand quickly: PR descriptions and review notes, contributor/maintainer guides, architecture/workflow/onboarding docs, or any doc that feels long, dense, or hard to scan.

## Patterns

| Pattern | Rule |
|---|---|
| Lead with the answer | Put the decision, action, or outcome first; context after. |
| Progressive disclosure | Start with the happy path, then details, edge cases, references. |
| Chunking | Group related information; keep flat lists short. |
| Signposting | Use headings, labels, callouts, and summaries so readers know where they are. |
| Recognition over recall | Prefer tables, checklists, examples, templates over prose to remember. |
| Review empathy | Design docs so reviewers verify intent without reconstructing the story. |

## Default shape

```markdown
# <Outcome-oriented title>

<One paragraph: what changed, who it helps, why it matters.>

## Quick path
1. <First action>
2. <Second action>
3. <Verification / expected result>

## Details
| Topic | Decision |
|-------|----------|
| <area> | <concise explanation> |

## Checklist
- [ ] <Reader can confirm this>

## Next step
<Link or action that continues the workflow.>
```

## PR & review docs

- State what to review **first**.
- State what is intentionally **out of scope**.
- Link the previous/next PR when work is chained.
- Keep each section on one decision or work unit.
- Use checklists for acceptance criteria and verification.

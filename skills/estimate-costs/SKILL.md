---
name: estimate-costs
description: >
  Estimate the monetary cost of a WBS using a rate card. Takes a WBS Dictionary
  (effort in person-days per work package, with Responsible role) and produces a
  Cost Breakdown Structure (CBS) with per-package cost, rollups by WBS branch,
  contingency ranges, and totals. Use after create-work-breakdown-structure,
  when a project has effort estimates and you need a bottom-up budget, or when
  pricing out a quote for a client.
---

# Estimate Costs (CBS)

Turn effort estimates into money. This skill consumes a **WBS Dictionary** (or
any work-package list with effort and an owner role) and applies a **rate card**
to produce a **Cost Breakdown Structure (CBS)** — the PMBOK *Estimate Costs*
process, bottom-up.

## Hard rule

**Never invent rates.** The rate card is a business parameter, not something the
agent guesses. If a role has no rate, mark that package `RATE MISSING` and ask
the user for the rate before producing a total.

## Inputs

- **Required**: WBS Dictionary with per work package: WBS Code, effort
  (person-days), Responsible (role). Output of `create-work-breakdown-structure`
  satisfies this.
- **Required**: Rate card. Resolution order:
  1. `<project>/.config/rates/rate-card.json`
  2. `<project>/rate-card.json`
  3. `~/.agent/.config/rates/rate-card.json` (global default)
- **Optional**: Contingency percentage per package or branch (default: 10%).
- **Optional**: Three-point estimates (optimistic/most-likely/pessimistic) for a
  cost range instead of a single point.

## Rate card format

```json
{
  "currency": "USD",
  "roles": {
    "tech_lead":  { "rate_per_day": 800, "overhead_pct": 0.15 },
    "backend":    { "rate_per_day": 600, "overhead_pct": 0.15 },
    "frontend":   { "rate_per_day": 600, "overhead_pct": 0.15 },
    "qa":         { "rate_per_day": 450, "overhead_pct": 0.10 },
    "pm":         { "rate_per_day": 550, "overhead_pct": 0.10 }
  }
}
```

- `overhead_pct` covers benefits/tools/etc. — applied as a multiplier on the
  labor cost.
- A role may also specify `rate_per_hour` (ignored when `rate_per_day` present).

## Procedure

### Step 1: Load and validate the rate card
Read the rate card in resolution order. Fail loudly (ask the user) if none
exists. Collect the set of roles referenced by the WBS and the roles in the rate
card; any role in the WBS missing from the card → `RATE MISSING`.

### Step 2: Compute per-package cost
For each work package `p`:

```
labor_cost(p)     = effort_days(p) × rate_per_day(role(p))
cost(p)           = labor_cost(p) × (1 + overhead_pct(role(p)))
contingency(p)    = cost(p) × contingency_pct
total(p)          = cost(p) + contingency(p)
```

If three-point estimates are supplied, also compute optimistic/pessimistic totals
using the same formula on those day values.

### Step 3: Roll up by WBS branch (CBS)
Aggregate bottom-up along the WBS hierarchy. Every Level-1 category becomes a
top-level line with subtotal = Σ its work packages. Preserve the WBS codes.

### Step 4: Validate
- Every package counted exactly once (no double counting).
- `RATE MISSING` count = 0 before presenting a total; otherwise present the
  subtotal of priced packages and list the gaps.

### Step 5: Output `COST-SUMMARY.md`

```markdown
# Cost Summary: [Project Name]
## Document ID: CBS-[PROJECT]-[YYYY]-[NNN]

## Rate Card Used
| Role | Rate/Day | Overhead | Effective/Day |
|------|---------:|---------:|--------------:|

## Cost Breakdown Structure
| WBS Code | Work Package | Role | Effort (days) | Labor | Overhead | Contingency | Total |
|----------|--------------|------|--------------:|------:|---------:|------------:|------:|
| 1        | [Category A]  |      |              |       |          |             |  ...  |  ← rollup
| 1.1      | [Package]     | ...  |            |      |          |             |  ...  |

## Totals
| Metric | Amount |
|--------|-------:|
| Net labor (no overhead) | ... |
| Overhead | ... |
| Contingency | ... |
| **Total estimated cost** | **...** |
| Optimistic / Most-likely / Pessimistic (if three-point) | ... / ... / ... |

## Confidence Notes
- Packages with RATE MISSING or LOW confidence (from the WBS) → flagged.
```

Write the file as `COST-SUMMARY.md` next to the WBS dictionary. Keep the same
language and currency as the rate card.

## Related skills
- `create-work-breakdown-structure` — produces the effort/dictionary input.
- `draft-project-charter` (agent-almanac) — charter input upstream.

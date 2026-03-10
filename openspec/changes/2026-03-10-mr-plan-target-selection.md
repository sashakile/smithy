# DQ-4: mr plan Target Potency Selection

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-4

## Problem

When `mr plan` analyzes signaling history and proposes a differentiation target, how does it
choose which potency level to propose?

Options:
- Always propose the lowest feasible potency (most aggressive compression)
- Always propose one step down from current (conservative, incremental)
- Propose multiple options and let the user choose
- Optimize for cost savings vs. coverage tradeoff

"Feasibility" is defined by coverage rate above a configurable threshold (default: 80%).

## Proposal

**Always propose the lowest feasible potency.** Show intermediate options. User overrides with
`--target P2`.

Output format:
```
Proposed target: P1 (coverage 73%, projected cost savings 94%)
Intermediate options:
  P2: coverage 91%, projected cost savings 72%
  P1: coverage 73%, projected cost savings 94%
Override: mr plan ticket-classifier --target P2
```

Rationale: The goal of differentiation is maximum compression. Proposing an intermediate step
when P1 is achievable is unnecessarily conservative. The user can always override downward.
Showing intermediate options preserves informed choice.

## Alternatives

1. **One-step-at-a-time** — Propose P3 from P4, then P2, then P1. Slower but reduces risk
   of big jumps. Each step accumulates more shadow evidence.
2. **Let user always choose** — `mr plan` shows all options; never recommends. Puts burden on
   user to understand coverage vs. cost tradeoffs.

## Decision

Pending. Recommended: always propose lowest feasible potency; show intermediate options with
explicit override flag.

# DQ-2: Open vs Closed Genome Schemas

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-2

## Problem

Genome schemas define what a component accepts (`:in`) and produces (`:out`). The question is
whether these schemas should be open (forward-compatible, allows extra keys) or closed (strict,
rejects extra keys).

The choice has different implications for `:in` vs `:out`:

- If `:in` is closed, adding a new field to an upstream system requires a coordinated genome
  update before it can be used.
- If `:out` is open, downstream components may accidentally rely on undocumented fields,
  creating hidden couplings.

## Proposal

Adopt split strictness: **`:in` open, `:out` closed**.

- `:in` open — forward-compatible. Extra keys are dropped by `receive` before DECIDE sees them
  (already enforced by input normalization). Components can be deployed before callers update.
- `:out` closed — strict. EMIT validates against closed schema. Prevents output drift and
  undocumented field coupling downstream.

Per-genome override via Malli options for cases where a component genuinely needs strict input
(compliance scenarios) or open output (extensible event schemas).

## Alternatives

1. **Both closed** — Maximum safety, but makes genome evolution painful and requires coordinated
   multi-component deploys for any field addition.
2. **Both open** — Maximum flexibility, but loses the EMIT schema guarantee that cascade
   comparison relies on (identical output shapes across potency levels).

## Decision

Pending. Recommended resolution: split strictness (`:in` open, `:out` closed) with per-genome
Malli override option.

# DQ-9: Per-Decision vs Per-Field Confidence

**Status:** accepted
**Date:** 2026-03-10
**ID:** DQ-9

## Problem

`Decision.confidence` is a single scalar `[:double {:min 0.0 :max 1.0}]`. This represents
overall confidence in the entire output value.

For components with structured outputs (e.g. a ticket classifier that produces
`{:priority :high :category :billing :assigned-team :tier-2}`), a single confidence score
may hide uneven certainty across fields:
- Confident about `:priority` (rule pattern matched perfectly)
- Uncertain about `:assigned-team` (required P3 reasoning)

Per-field confidence would enable more granular cascade behavior: cascade only the uncertain
fields, not the entire decision.

## Proposal

**Per-decision (scalar) for v0.1.0. Per-field is v2.x feature.**

`Decision.confidence` remains a scalar in v0.1.0. The cascade threshold check operates
on the single scalar, which must represent the weakest-link confidence of the full output.

Rationale:
- Per-field confidence requires a fundamentally different cascade architecture (partial results,
  field-level merge semantics)
- Current cascade design assumes atomic decisions — accept or escalate the whole thing
- Scalar confidence is simpler to reason about, easier to tune thresholds for
- P1 engines (Drools, lookup) naturally produce scalar confidence

Track as v2.x feature request when field-level granularity is demonstrated to be worth the
architectural complexity.

## Decision

Resolved in v0.1.0: per-decision scalar. Per-field deferred to v2.x.

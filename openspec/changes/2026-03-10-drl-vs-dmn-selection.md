# DQ-8: DRL vs DMN Selection in mr plan

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-8

## Problem

When `mr plan` generates Drools artifacts, it can produce either DRL rules (Drools Rule Language)
or DMN decision tables (Decision Model and Notation), or both. The right choice depends on the
nature of the decision patterns found in signaling history.

DRL: best for complex conditional logic with many interacting conditions.
DMN: best for matrix-style decisions (N conditions × M outcomes), accessible to non-engineers.

The CLI currently accepts `--target-format drools` but doesn't enumerate what other formats are
valid or how selection between DRL and DMN is made when `drools` is specified.

## Proposal

**Matrix patterns with <20 rows → DMN. Complex conditions → DRL. Both → composed.**
User override: `--target-format drools:drl`, `--target-format drools:dmn`, or `--target-format drools`
(auto).

Auto-selection algorithm:
1. Analyze clustered patterns from signaling history
2. If decision dimensions ≤ 4 AND unique outcome combinations ≤ 20: propose DMN table
3. If conditions involve regex, date arithmetic, list operations, or nested logic: propose DRL
4. If both are present in the same component: propose DMN for the matrix portion, DRL wraps
   and calls DMN node (Drools supports this composition natively)

Rationale: DMN tables are accessible to compliance/legal reviewers who need to approve rules.
DRL handles the cases DMN can't express.

## Alternatives

1. **Always DRL** — One format, simpler tooling, but non-engineers can't review.
2. **Always DMN** — Accessible but can't express complex logic; forces workarounds.
3. **User always specifies** — No auto-selection; `--target-format` required to be explicit.
   Maximum control, more friction for common cases.

## Decision

Pending. Recommended: auto-selection based on pattern complexity with explicit override flags.

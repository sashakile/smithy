# CG-9: Genome Evolution Strategy

**Status:** proposed
**Date:** 2026-03-10
**ID:** CG-9

## Problem

Genomes (`:in`/`:out` schemas) are defined as invariant across potency levels — every potency
level of a given cell sees the same schema. But what happens when the schema itself needs to
evolve?

For example: a ticket classifier's input adds a new field `:source-channel`. How is this
change propagated across existing P1 rules, P2 classifiers, P3 constraints, and P4 LLM prompts?

Options range from:
- In-place genome mutation (update the schema, all expressions see the new schema)
- New cell version with new cell ID (`:ticket-classifier-v2`)
- Schema versioning within the genome

## Proposal

**New cell version = new Cell ID. No in-place genome mutation.**

When a genome needs to evolve:

1. Define a new Cell: `:ticket-classifier-v2` with the updated genome
2. Register new cell with initial P4 expression (inherits from v1's P4)
3. Run observation mode alongside v1 cell
4. Differentiate v2 cell from scratch using its own signaling history
5. Once v2 is fully differentiated and validated, deprecate v1

Rationale:
- In-place genome mutation would silently invalidate all existing expressions (Drools rules
  generated from old schema may not compile; ONNX models trained on old features break)
- New Cell ID makes the versioning explicit and trackable in lineage
- Allows gradual migration: v1 and v2 can coexist in production during transition
- `lock.edn` tracks both cells independently — no merge conflicts

Drawback: signaling history does not automatically transfer. `mr plan` must start fresh for
v2. This is intentional — v1's traces may not be valid training data for the new genome.

## Alternatives

1. **In-place genome mutation** — Single cell ID throughout. Simpler but invalidates all
   existing expressions silently and makes rollback difficult.
2. **Schema versioning in genome** — `{:in {:v1 OldSchema :v2 NewSchema}}`. Adds complexity
   to every pipeline stage without clear benefit over the new-Cell-ID approach.

## Decision

Pending. Recommended: new Cell ID for genome evolution; no in-place genome mutation.

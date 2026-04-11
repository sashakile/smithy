## Why

The current OpenSpec corpus assumes Smithy can safely carry advanced adaptation, telemetry-derived analysis, and concurrency-heavy control flow before it has proven that the core differentiation loop produces net value. That creates a real risk of building governance and observability machinery whose cost, fragility, and operator burden exceed the savings it is meant to unlock.

## What Changes

- Tighten proposal evidence so promotion decisions account for operating overhead, not just gross cost reduction.
- Add an explicit, machine-decidable baseline-proof gate before topology adaptation and topology proposal workflows may be used on a component lineage.
- Require telemetry used for planning, evidence, and topology analysis to come from registered, versioned annotation producers with auditable compatibility declarations and exclusion reporting.
- Strengthen cascade epoch semantics so closed epochs cannot publish late externally visible effects or duplicate terminal results across adapters or sinks.
- Tighten CLI guardrails around emergency reprogramming, require independent review before repeated emergency use, and block topology commands until readiness conditions are satisfied.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `proposals`: require net-savings evidence and baseline-proof gating before advanced proposal kinds are allowed
- `signals`: require provenance-tagged, versioned annotation producers for analytics-critical telemetry
- `topology-adaptation`: fail closed on incompatible telemetry and require baseline proof before topology analysis may create proposals
- `cascade`: formalize execution epoch states and require suppression of late externally visible effects
- `mr-cli`: enforce readiness checks for topology commands and add stronger guardrails for emergency reprogramming

## Impact

This change affects spec semantics for the proposal workflow, telemetry model, topology analyzer, cascade runtime, and operator CLI. It will constrain some currently described workflows, add validation and readiness checks, and require implementation work in tracing, proposal evaluation, runtime effect publication, and CLI review/error reporting.

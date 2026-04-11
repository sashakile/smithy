## Context

Smithy currently specifies a wide surface area: differentiation planning, shadowing, proposal governance, topology adaptation, tracing, and concurrency-aware runtime behavior. Recent review artifacts in `.wai/` identified three systemic weaknesses across that surface:

1. Promotion logic optimizes for gross savings while ignoring the cost of running the framework itself.
2. Topology and evidence logic treat annotations as trustworthy without a stable producer contract.
3. Runtime correctness depends on terse prose around epoch closure, cancellation, and late effect suppression.

The design goal is not to add more feature surface. It is to make advanced features contingent on proof that the core slice is economically and operationally sound.

## Goals / Non-Goals

**Goals:**

- Make advanced adaptation features depend on measurable proof from a completed differentiation slice.
- Define which telemetry is comparable enough to support evidence and topology decisions.
- Make epoch closure semantics explicit enough to drive implementation and testing.
- Add CLI-level guardrails that stop the highest-risk operator shortcuts.

**Non-Goals:**

- Rework the full Smithy architecture or remove existing capabilities from the corpus.
- Define implementation-specific storage schemas or exact UI/CLI output formatting beyond the required checks.
- Introduce autonomous topology commitment or broaden emergency workflows.

## Decisions

### 1. Gate advanced adaptation on baseline proof

Topology work is the largest optional surface in the corpus and the weakest justified economically. The design introduces a baseline-proof concept at the proposal/spec level: a component lineage must have at least one committed, non-emergency differentiation with positive net savings after overhead and a fixed 14-day post-commit observation window before topology workflows are allowed. Baseline proof is only satisfied when the observation window contains enough compatible evidence to meet the minimum sample requirement and when the excluded-telemetry fraction remains below a published cap. This prevents the gate from being interpreted differently across implementations and makes evidence failure visible instead of silently inconclusive.

Alternative considered: gate topology globally at the installation level. Rejected because it blocks mature lineages alongside immature ones and weakens the evidence chain from one component to the next.

### 2. Treat analytics-critical annotations as governed telemetry

Annotations used in planning, evidence, or topology logic must not be free-form. The design requires registered producer identity, producer version, and an explicit compatibility-group declaration approved by the telemetry registry so analytics can reject mixed or semantically incompatible observations instead of silently combining them. Every derived metric must report the included sample count, excluded sample count, and exclusion reasons so operators can see when readiness is blocked by telemetry drift or gaming.

Alternative considered: keep annotation producers informal and rely on documentation. Rejected because the failure mode is silent analytical corruption rather than visible breakage.

### 3. Make closed epochs a hard publication boundary

Existing requirements say late results are discarded, but they do not define the lifecycle precisely enough for side effects. The design makes the epoch lifecycle explicit as `:open -> :closing -> :closed` and requires any externally visible ACT effect or terminal publication to carry an idempotency key derived from the execution epoch, publication kind, and sink identity. Adapters and publication sinks must treat that key as a deduplication contract for a bounded retention period. This keeps timeout, cancellation, and early-success races from duplicating outputs while still permitting legitimate retries against the same outcome.

Alternative considered: rely on cooperative cancellation alone. Rejected because it does not protect against effects already in flight or handlers that observe cancellation too late.

### 4. Put risky operator actions behind stronger CLI checks

Emergency reprogramming remains available, but it becomes harder to normalize as a routine tool. The CLI must require incident metadata and reject repeated emergency use on the same component lineage within a 14-day cooldown window unless a fresh human review, recorded by a reviewer other than the prior emergency approver, has cleared the lineage for another emergency action. Topology commands must surface readiness failures rather than generating speculative proposals.

Alternative considered: encode these rules only in organizational policy. Rejected because the main failure mode is operator convenience bypassing policy in moments of pressure.

## Risks / Trade-offs

- Baseline-proof gating slows access to topology workflows -> Mitigation: keep the gate component-lineage scoped rather than global.
- Registered telemetry contracts add operational friction for engine authors -> Mitigation: constrain the requirement to analytics-critical annotations, not all annotations, and standardize on explicit compatibility groups rather than ad hoc version heuristics.
- Epoch idempotency requirements may force effect adapters to change -> Mitigation: scope the requirement to externally visible ACT effects and terminal publications only, and define sink-scoped deduplication semantics.
- Emergency cooldowns can slow incident response -> Mitigation: permit emergency use, but require new incident metadata and reviewed state before repeated invocation.

## Migration Plan

1. Update proposal, signal, topology, cascade, and CLI specs with the new guards.
2. Implement telemetry producer registration and readiness checks in read-only mode first so operators can see what is missing.
3. Add baseline-proof evaluation and emergency cooldown enforcement before enabling topology proposal creation.
4. Add epoch-state and idempotency handling to runtime effect publication paths.
5. Turn readiness failures from warnings into hard blocks once all required evidence paths are available.

Rollback strategy: remove or relax readiness enforcement while keeping telemetry provenance fields additive. The spec changes are designed so conservative blocking can be loosened without invalidating stored proposal or trace history.

## Resolved Constants

- Baseline proof uses a fixed 14-day post-commit observation window.
- Emergency cooldown is enforced per component lineage for 14 days.
- Producer compatibility is declared through explicit compatibility groups in the telemetry registry.

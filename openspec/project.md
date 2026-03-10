# Project Context

## Purpose

Smithy is a Progressive Differentiation Framework for Adaptive Agent Architecture. It provides
a principled, automated, reversible path from expensive LLM agent calls (P4, ~$0.50/call) to
cheap deterministic code (P1, ~$0/call, <1ms) — reducing production agent costs by 50–97%
by progressively differentiating stable traffic patterns.

"A2A tells agents how to talk. Smithy tells agents how to think cheaper."

## Tech Stack

- **Clojure** (primary language — DR runtime and core library)
- **Integrant** (lifecycle management for DR subsystems)
- **Malli** (runtime schema validation for genomes and messages)
- **core.async** (channel-based pipeline composition)
- **Drools** (DRL/DMN rule engine for P1 differentiation target)
- **ONNX / DJL** (ML inference for P2 differentiation target)
- **GraalVM** (native-image binary for mr CLI, ~50ms startup)
- **PostgreSQL / TimescaleDB** (production signal history storage)
- **SQLite** (local dev signal history)
- **Prometheus / iapetos** (metrics)
- **OpenTelemetry / clj-otel** (distributed tracing)
- **μ/log (mulog)** (structured logging)

## Project Conventions

### Code Style

- Clojure idiomatic style; no type annotations unless required by interop
- All types defined as Malli schemas
- No type may have more than 7 required fields (Rule of 5 constraint)
- Thread-first (`->`) for pipeline composition, not thread-last (`->>`)
- Multimethods for polymorphic dispatch on `:engine` keyword

### Architecture Patterns

- **Vertical split**: identity (Cell) vs state (Fate) vs config (Wiring) — never merged
- **Protocol extraction**: implicit behavior becomes explicit Clojure protocols (IEngine, IRegistry, ISignalStore)
- **Horizontal split**: base type + extension maps (Annotations uses open map for extensibility)
- **Cascade outside pipeline**: pipeline is a pure function; cascade orchestrates across potency levels
- **All changes are Proposals**: differentiate, reprogram, split, fuse all use one Proposal type

### Testing Strategy

- Pure functions tested with direct assertion, no mocks
- Property-based testing via test.check for pipeline invariants
- Integration testing via `mr test <component> --corpus`
- No test bypasses cascade validation; every `mr differentiate` auto-runs regression suite

### Git Workflow

- Conventional commits
- All changes via PR; topology changes require human approval (never auto-commit)
- `lock.edn` committed to git; tracks component potency versions

## Domain Context

### Potency Model

Components exist at four potency levels (P1–P4). Differentiation moves P4→P1 (cheaper, faster,
less flexible). Reprogramming moves P1→P4 (expensive, regains flexibility).

- **P4 Pluripotent**: Full LLM agent with tools, multi-turn reasoning (~$0.50/call, 2–30s)
- **P3 Multipotent**: Constrained LLM with structured output (~$0.05/call, 200ms–2s)
- **P2 Committed**: ONNX classifier, Drools+PMML hybrid (~$0.001/call, 5–50ms)
- **P1 Differentiated**: Drools DRL/DMN, lookup table, deterministic code (~$0/call, <1ms)

### Core Type Constraint

Genome (`:in`/`:out` schema) is invariant across all potency levels. Only DECIDE varies.
RECEIVE normalizes input to schema-defined keys before DECIDE sees it — ensuring all potency
levels see identical input shapes during shadow comparison.

### Cascade Semantics

Cascade returns the BEST Decision even if all potency levels are below threshold. Only
infrastructure faults produce `{:fault ...}`. A sub-threshold Decision is still a Decision.

## Important Constraints

- `:auto-commit false` is a hard invariant for topology changes — DR emits startup warning if true
- API keys exclusively via environment variables, never in config files
- nREPL binds to localhost only; disabled in production unless `MR_NREPL_ENABLED=true`
- All Drools rule JARs hash-verified against `lock.edn` manifest before loading
- No type may have more than 7 required fields

## External Dependencies

- **Drools** (Apache 2.0) — P1/P2 rule engine; hot-reloadable via KieScanner
- **DJL + ONNX Runtime** — P2 ML inference with JVM interop
- **Spring AI** (1.0.0+) — Integration via `SmithyDifferentiationAdvisor` (CallAdvisor)
- **Kafka / Jackdaw** — Event-driven integration pattern
- **OpenTelemetry** — Distributed tracing across core.async channels and HTTP boundaries

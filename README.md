# smithy

[![tracked with wai](https://img.shields.io/badge/tracked%20with-wai-blue)](https://github.com/charly-vibes/wai)
[![status: specification](https://img.shields.io/badge/status-specification%20phase-orange)]()

Progressive Differentiation Framework for Adaptive Agent Architecture.

> "A2A tells agents how to talk. Smithy tells agents how to think cheaper."

Smithy provides a principled, automated, reversible path from expensive LLM agent calls to
cheap deterministic code — reducing production agent costs by 50–97% through progressive
differentiation of stable traffic patterns.

## Core Idea

Every AI agent decision starts at **P4** (full LLM, ~$0.50/call, 2–30s) and can be
progressively differentiated toward **P1** (Drools rules, ~$0/call, <1ms) as traffic
patterns stabilize:

```
P4: Full LLM agent          ~$0.50/call   2–30s
P3: Constrained LLM         ~$0.05/call   200ms–2s
P2: ONNX / ML classifier    ~$0.001/call  5–50ms
P1: Drools rules / lookup   ~$0/call      <1ms
```

A ticket classifier that costs $500/day at P4 can cost **$27.50/day** after differentiation
(94.5% reduction). Fraud detection: $120,000/day → $2,592/day (97.8% reduction).

## What's in This Repo

- **`mr` CLI** — Analyze signaling history, propose and execute differentiation, manage
  component lifecycle. (`smithy` alias available to avoid conflicts with `myrepos`.)
- **DR (Differentiation Runtime)** — Orchestration engine. Clojure, Integrant, Malli.
- **The Progressive Differentiation Model** — Formal architecture grounded in cell biology.

## Docs

- [`docs/spec.md`](docs/spec.md) — Full product & technical specification (v0.1.0)
- [`docs/type-system.md`](docs/type-system.md) — v0.1.0 type system reference (all types, protocols, APIs)
- [`openspec/changes/`](openspec/changes/) — Open architectural decisions

## Quick Start (Planned)

> This project is in **specification phase** — the CLI and runtime are not implemented yet.
> The commands below show the intended workflow.

```sh
mr init
mr plan ticket-classifier
mr shadow ticket-classifier --from P4 --to P1 --duration 24h
mr review ticket-classifier
mr differentiate ticket-classifier --to P1
```

See [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

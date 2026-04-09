# Smithy — Product & Technical Specification

**Version:** 0.1.0 (March 2026)
**Status:** Specification phase — no implementation yet.
**Tagline:** "A2A tells agents how to talk. Smithy tells agents how to think cheaper."
**Versioning:** Specs follow semver. Breaking changes to type contracts or pipeline
semantics require a major version bump. Additive changes (new engines, new middleware)
are minor bumps. Clarifications and fixes are patches.

---

## 1. Overview & Vision

### 1.1 Problem Statement

Running every AI agent decision through an LLM is expensive (~$0.50/call), slow (2–30s), and
unpredictable. Production traffic stabilizes over time — 70% of support tickets match patterns
that don't need LLM calls. No existing framework provides a principled, automated, reversible
path from expensive generality to cheap specialization.

### 1.2 What Smithy Is

Three deliverables:

- **`mr` CLI** — Named after Mr. Smith from The Matrix. `smithy` alias available to avoid
  conflicts with `myrepos`.
- **DR (Differentiation Runtime)** — Named after Dr. Smith. Orchestration engine.
- **The Progressive Differentiation Model** — Formal architecture grounded in cell biology.

### 1.3 Design Philosophy — Five Core Principles

1. **Genome Invariance** — Component contract (schema) never changes across potency levels.
   Only DECIDE varies.
2. **Progressive Commitment** — Differentiation happens in discrete, validated steps with
   shadow deployment before commitment.
3. **Reversible Fate** — Any differentiated component can be reprogrammed back.
4. **Separation of Concerns** — RECEIVE, DECIDE, ACT, EMIT cleanly separate concerns.
   Only DECIDE varies.
5. **Observable by Default** — Every execution produces signaling history feeding both
   differentiation decisions and topology adaptation.

### 1.4 Goals

1. Principled, automated path from P4 LLM agents to P1 deterministic code
2. Reduce production agent costs 50–90% through progressive differentiation
3. Enable reversible differentiation
4. Generate human-readable Drools rules; domain expert review and approval workflows
5. Integrate with Spring AI, MCP, A2A, LangGraph, CrewAI
6. Developer-friendly CLI and REPL-driven workflow (Clojure)
7. Production-grade observability: Prometheus, OpenTelemetry, structured logging

### 1.5 Non-Goals

- Not an execution framework (does not replace Spring AI, LangGraph, CrewAI)
- Not a communication protocol (does not replace MCP or A2A)
- Does not provide model training or fine-tuning
- Does not prescribe a specific LLM provider, model, or prompt methodology

---

## 2. Core Concepts & Domain Model

### 2.1 Potency Levels

| Level | Biology Analog | DECIDE Implementation | Latency | Cost/Call |
|---|---|---|---|---|
| P4: Pluripotent | Stem cell | Full LLM agent with tools, multi-turn reasoning | 2–30s | ~$0.50 |
| P3: Multipotent | Progenitor cell | Constrained LLM with structured output, few-shot | 200ms–2s | ~$0.05 |
| P2: Committed | Precursor cell | ONNX classifier, Drools+PMML hybrid, fine-tuned small model | 5–50ms | ~$0.001 |
| P1: Differentiated | Terminal cell | Drools DRL/DMN, pattern match, lookup table, deterministic code | <1ms | ~$0 |

**Differentiation** = P4→P1 (cheaper, faster, less flexible).
**Reprogramming** = P1→P4 (regains flexibility at cost).

Cost figures are illustrative order-of-magnitude.

### 2.2 The Four Primitives

| Primitive | Role | Nature | Varies Across Potency? |
|---|---|---|---|
| RECEIVE | Ingest and validate input against schema | Pure (validation) | No |
| DECIDE | Apply layer-appropriate logic | Varies by potency | Yes — compression target |
| ACT | Execute side effects based on decision | Effectful | No |
| EMIT | Produce validated output | Pure (serialization) | No |

### 2.3 Terminology Reference

| Term | Definition | Biological Origin |
|---|---|---|
| Progressive Differentiation | Compressing agent components from flexible to specialized | Cells lose potency, gain specialization |
| Reprogramming | Reversing differentiation; moving to higher potency | Yamanaka factors |
| Genome | Component schema/contract — invariant across differentiation | DNA identical in every cell |
| Expression / Phenotype | Current DECIDE implementation — varies by potency | Active genes determine cell behavior |
| Cell | A component — basic unit of function | Fundamental unit of life |
| DR | Orchestration engine managing execution, routing, observation | Stem cell niche directs cell fate |
| Signaling History | Recorded execution traces informing differentiation decisions | Morphogen gradients determine fate |
| Shadow Deployment | Running two potency implementations in parallel for validation | Bivalent chromatin |
| Morphogen | Signal/threshold triggering a differentiation decision | Signaling molecules |
| Lineage | History of potency transitions | Cell lineage tracing |

### 2.4 Metrics Terminology

Three distinct metrics are used throughout the system. Do not conflate them:

| Metric | Definition | Used By |
|---|---|---|
| **Confidence** | Per-decision certainty score (0.0–1.0) returned by DECIDE. Compared against Fate threshold to trigger cascade escalation. | Pipeline, Cascade |
| **Coverage** | Percentage of total traffic a lower potency level can handle (i.e., produces a Decision above threshold). Measures breadth. | `mr plan`, Proposals |
| **Agreement** | Percentage of shadow decisions where lower potency matches P4 ground truth. Measures fidelity. | Shadow deployment, `mr review` |

---

## 3. The `mr` CLI

### 3.1 Design Principles

Follows [clig.dev](https://clig.dev) guidelines. Inspired by Terraform lifecycle and kubectl
verb-resource model.

- Progressive disclosure — simple defaults, advanced flags for power users
- Output duality — human-readable to TTY; JSON/EDN when piped or with `--output json`
- Actionable errors — every error shows what went wrong, why, and how to fix it

### 3.2 Command Reference

**Core workflow:**

| Command | Description | Terraform Analog |
|---|---|---|
| `mr init` | Initialize project; create smithy.edn and .smithy/ | terraform init |
| `mr plan` | Analyze signaling history and propose differentiation candidates | terraform plan |
| `mr differentiate` | Execute a validated differentiation (lower potency) | terraform apply |
| `mr reprogram` | Reverse a differentiation (raise potency) | terraform destroy (partial) |
| `mr validate` | Validate all component genomes and configurations | terraform validate |

**Component operations:**

| Command | Description |
|---|---|
| `mr get cells` | List all registered components with current potency levels |
| `mr describe <n>` | Show full component descriptor: genome, lineage, potency score |
| `mr potency` | Show potency distribution across all components |
| `mr lineage <n>` | Show differentiation/reprogramming history |
| `mr review <n>` | Review pending differentiation proposal |

**Development & observability:**

| Command | Description |
|---|---|
| `mr dev` | Start DR in development mode with hot-reloading and nREPL |
| `mr repl` | Connect to running DR's nREPL |
| `mr shadow <n>` | Run shadow deployment comparing two potency levels |
| `mr trace <n>` | View recent signaling history for a component |
| `mr status` | Show DR health, component states, active shadow deployments |
| `mr metrics` | Show cost, latency, throughput metrics |

**Topology adaptation:**

| Command | Description |
|---|---|
| `mr plan --topology` | Analyze full component graph for split and fuse candidates |
| `mr split <c> --into <a> <b>` | Manually propose a split |
| `mr fuse <a> <b> --as <merged>` | Manually propose a fusion |
| `mr review --topology <n>` | Review pending split or fuse proposal |
| `mr topology` | Display component dependency graph with coupling scores |

### 3.3 Example Workflow: Day 1 → Day 30

```sh
mr init
mr plan ticket-classifier --target-format drools
# Analyzes 5,000 traces. Proposes P4→P1 (Drools). 14 DRL + 1 DMN. Coverage: 73%.
mr shadow ticket-classifier --from P4 --to P1 --duration 24h
mr review ticket-classifier
mr differentiate ticket-classifier --to P1
# P1 handles 73%; 27% escalates to P4. Cost: $0.05 → ~$0.014/ticket.
mr reprogram ticket-classifier --to P4 --reason "new product launch"
```

---

## 4. DR Architecture

### 4.1 Technology Stack

- **Clojure** (primary language)
- **Integrant** (lifecycle management)
- **core.async** (channel composition)
- **Malli** (runtime schema validation)
- **Multimethods** (polymorphic dispatch)

### 4.2 Core Subsystems

| Subsystem | Responsibility | Clojure Namespace |
|---|---|---|
| Registry | Stores component descriptors; source of truth for potency states | dr.core |
| Router | Dispatches incoming messages to correct component/potency | dr.core |
| Executor | Multimethod dispatch on :potency; runs RECEIVE→DECIDE→ACT→EMIT | dr.executor |
| Monitor | Collects signaling history via core.async mult/tap | dr.monitor |
| Shadow Engine | Parallel comparison of two potency implementations on live traffic | dr.shadow |
| Cascade | Escalation chain: tries P1 first, falls back through P2→P3→P4 | dr.cascade |
| Reprogrammer | Manages reverse path; raises potency when lower levels can't cope | dr.reprogram |
| Schema Engine | Malli-based validation for all component genomes and messages | dr.schema |

### 4.3 Cascade

`P1 → (uncertain?) → P2 → (uncertain?) → P3 → (uncertain?) → P4`

- **Worst-case latency:** P1→P2→P3→P4 ≈ 32 seconds
- **Worst-case cost:** ~$0.551 (P1: ~$0 + P2: ~$0.001 + P3: ~$0.05 + P4: ~$0.50). Rare — typically <1% of traffic reaches P4.
- **Cascade timeout:** configurable `:cascade-timeout` (default: 30s)
- **Level skipping:** `:cascade-skip` bypasses unused potency levels (e.g. P1→P4 directly)
- Returns best sub-threshold Decision if all levels fail; fault only on infrastructure failure.
- **Caller responsibility:** The HTTP API includes `confidence` in every response. Callers
  MUST check confidence against their own acceptance criteria. A sub-threshold Decision
  (including confidence 0.0) is a valid response — cascade does not convert low confidence
  to a fault.

### 4.4 Shadow Deployment

Three shadow strategies:

1. **Full shadow** — Every request through both implementations. Highest confidence.
2. **Sampled shadow (default)** — Configurable sample rate (default: 10%).
3. **Budget-capped shadow** — Specify total budget; DR auto-calculates sample rate.

Metrics: `smithy_shadow_agreement` (gauge), `smithy_shadow_cost_dollars` (gauge).

### 4.5 Rollback & Circuit Breaking

Three-tier rollback:

1. **Automatic Circuit Breaker** — Monitors agreement rate vs. sampled P4 baseline (default: 5%
   sample, 90% threshold, 100-decision window). Escalates within one decision cycle (<100ms).
2. **Hot-Standby** — Previous implementation retained for configurable grace period (default:
   7 days). Rollback is instantaneous.
3. **Manual Emergency Rollback** — `mr reprogram --emergency` bypasses shadow validation;
   an authorized operator approves at invocation time, then it immediately escalates to P4.
   Requires reason.

```edn
{:rollback {:circuit-breaker {:sample-rate 0.05 :threshold 0.90 :window-size 100}
            :hot-standby-days 7
            :notify-on-break true}}
```

### 4.6 Confidence Threshold Tuning

Three strategies:

1. **Static** — Fixed per-component value (e.g. `:confidence 0.80`).
2. **Adaptive** — EWMA: `threshold_new = α × observed_agreement + (1 − α) × threshold_current`.
   Default α = 0.05. Bounds default: [0.50, 0.99]. Cooldown after circuit-break (default: 1hr).
3. **Shadow-Calibrated** — `mr shadow` computes optimal threshold maximizing cost savings while
   maintaining target agreement rate (default: 95%).

### 4.7 Middleware Architecture

Six standard stage middleware layers (outermost first):

| Order | Middleware | Responsibility |
|---|---|---|
| 1 | wrap-trace-context | Creates/propagates OTel span per stage |
| 2 | wrap-structured-logging | Logs entry/exit via μ/log |
| 3 | wrap-metrics | Records stage duration histograms and error counters |
| 4 | wrap-cascade-bridge | Sets :cascade? true on exhausted :decide retries |
| 5 | wrap-retry | Exponential backoff for :transient errors; respects Retry-After |
| 6 | wrap-error-enrichment | Normalizes exceptions to canonical error map before retry evaluates the fault |

Signal persistence also applies mandatory `wrap-pii-redaction` before Trace writes when raw
input storage is enabled. Custom middleware declared in smithy.edn via `:insert-before`,
`:insert-after`, or `:replace`.

### 4.8 Autonomous Topology Adaptation

Two failure modes addressed:
- **Under-decomposition** — One component doing two jobs; one holds the other's potency hostage
- **Over-decomposition** — Components always firing sequentially with pure serialization overhead

**Split detection signals** (any single above threshold triggers a proposal):
1. Bimodal confidence distribution (Hartigan's dip > 0.3)
2. Potency ceiling lock (same potency 30+ days; per-cluster coverage gap ≥ 40 pp)
3. Decision path divergence (reasoning fingerprint partitions into non-overlapping groups)
4. Schema polymorphism (output shape signature entropy is high)

**Fuse detection signals** (across component pairs):
1. Temporal coupling (A always fires before B; B never independent; threshold: 95%)
2. Schema subsumption (A's EMIT ≈ subset of B's RECEIVE)
3. Redundant decision patterns (high Jaccard similarity on input features + outcomes)
4. Cascade waste (A cascades to P4 >20%; B's DECIDE is consistently sub-ms on A's output)

Topology proposals flow through same `plan→shadow→review→commit` cycle. `:auto-commit false`
is a hard invariant — topology changes NEVER auto-commit.

---

## 5. External Integrations

### 5.1 Spring AI (Pattern A — Embedded)

`SmithyDifferentiationAdvisor` implements `CallAdvisor` and intercepts every LLM call.
Order: `Ordered.HIGHEST_PRECEDENCE + 10`. Application code never changes.

### 5.2 LangGraph / LangChain (Pattern B — Sidecar)

Python nodes call HTTP decision API:
```python
response = requests.post("http://smithy-dr:8080/decide",
    json={"component": "ticket-classifier", "input": {...}})
```

### 5.3 MCP Server Integration

Smithy exposes components as MCP tools. Agent calls via MCP; DR routes through cascade
transparently. Agent never knows if lookup table or LLM answered.

### 5.4 A2A Protocol Integration

A2A sees Smithy as opaque black box — response quality is consistent regardless of whether P1
or P4 answered. Internal potency level is an implementation detail.

See open question DQ-7 for A2A task state mapping decision.

### 5.5 Observability Stack

| Pillar | Library | Role |
|---|---|---|
| Structured Logging | μ/log (mulog) | Event-based logging as Clojure maps |
| Metrics | iapetos | Prometheus client; latency histograms, token counters, cost gauges at /metrics |
| Distributed Tracing | clj-otel | OpenTelemetry SDK wrapper; span propagation across core.async and HTTP |

**Recommended SLOs:**
- Latency: 95% of requests resolved at P1 or P2 with <100ms end-to-end
- Cost: average per-request cost below $0.01 across all components
- Availability: 99.9% of /v1/decide requests return valid decision within cascade timeout

---

## 6. Drools Integration

### 6.1 Core Insight

Differentiating to P1 generates Drools DRL rules or DMN decision tables — human-readable,
auditable, version-controlled. AI proposes, humans govern, rules execute.

### 6.2 Rule Generation Algorithm (5 stages)

1. **Trace filtering** — Minimum 1,000 traces; filtered for completeness; deduplicated by
   input signature
2. **Pattern clustering** — Input→output pairs clustered by decision outcome; clusters <10
   exemplars excluded
3. **LLM-assisted rule synthesis** — P4 LLM receives genome schemas + ≤20 exemplars per
   cluster + DRL syntax spec; JSON output with rule text + metadata
4. **DRL validation loop** — Each rule parsed by KieBuilder; compilation failures trigger
   re-generation (max 3 attempts); persistent failures dropped and flagged
5. **Conflict resolution** — Contradictory decisions for same input: majority wins; minority
   excluded from rule conditions; flagged as "requires P4 fallback"

### 6.3 When to Use Drools vs. Other Targets

| Scenario | Best Target |
|---|---|
| Compliance approval required | Drools DRL/DMN |
| Regulated industry (finance, healthcare) | Drools DMN |
| Domain experts maintain rules | Drools Decision Tables (Excel) |
| Pure pattern matching, no governance | Lookup table (Clojure map) |
| High-dimensional statistical classification | ONNX classifier |
| Business rules + ML score | Drools DMN + PMML |
| Ultra-low latency (<100μs) | Compiled Clojure/Java code |

### 6.4 Hot-Reloading

KieScanner monitors Maven repository or local directory; hot-swaps rule JARs atomically;
zero downtime. 60-second rule deploy cycle.

---

## 7. Use Cases & Cost Projections

| Use Case | Baseline Cost/Day | After Differentiation | Reduction |
|---|---|---|---|
| Support ticket classification (10K/day) | $500 | ~$27.50 | 94.5% |
| Content moderation (50K/day) | $2,500 | ~$132.50 | 94.7% |
| RAG query routing (20K/day) | $1,000 | ~$257 | 74.3% |
| Fraud detection (2.4M/day) | $120,000 | ~$2,592 | 97.8% |
| Chatbot intent detection (50K/day) | $2,500 | ~$932 | 62.7%¹ |
| Dynamic pricing (100K/day) | $5,000 | ~$275 | 94.5% |

¹ Lower reduction than other use cases due to higher intent variance — chatbot intents
have more long-tail patterns that resist P1 differentiation, keeping more traffic at P3/P4.

---

## 8. Configuration

### 8.1 Configuration Precedence (highest to lowest)

1. CLI flags (`--model`, `--confidence`, etc.)
2. Environment variables (`MR_DEFAULT_MODEL`, `MR_LOG_LEVEL`)
3. Project config (`./smithy.edn`)
4. User config (`~/.config/smithy/config.edn`)
5. Installation defaults (bundled in binary)

### 8.2 smithy.edn Structure

EDN format with Aero reader macros (`#profile`, `#env`). JSON schema provided for
non-Clojure editors.

Keys: `:dr`, `:cells`, `:fates`, `:expressions`, `:wirings`, `:storage`, `:llm`, `:review`.

### 8.3 Runtime State (.smithy/)

`.gitignored` except `lock.edn`:
- `state.db` — SQLite for component registry, signaling history, cost tracking
- `proposals/` — Pending differentiation proposals with generated DRL/DMN files
- `shadow/` — Cached shadow deployment results
- `lock.edn` — Lockfile tracking component potency versions (committed to git)

### 8.4 Signaling History Retention

| Environment | Backend | Default Retention |
|---|---|---|
| Local dev | SQLite | 30 days rolling |
| Production | PostgreSQL/TimescaleDB | 90 days raw, 1 year aggregated |
| Archival | S3/GCS as Parquet | Unlimited |

---

## 9. Deployment

### 9.1 CLI Distribution

GraalVM native-image binary (~50ms startup) with JVM uberjar fallback.

- Homebrew: `brew install smithy/tap/mr`
- Scoop: `scoop bucket add smithy; scoop install mr`
- GitHub Releases: linux-amd64, linux-aarch64, macos-amd64, macos-aarch64, windows-amd64
- Docker: `docker pull ghcr.io/smithy-framework/mr`

### 9.2 DR Deployment

- **Local dev** — `mr dev` with hot-reloading, nREPL, Docker Compose (Kafka + Prometheus + Grafana)
- **Kubernetes** — Helm chart; multi-stage Docker (`clojure:temurin-21-tools-deps` → `eclipse-temurin:21-jre-jammy`)
- **Cloud** — Terraform modules for AWS (EKS + MSK + Secrets Manager) and GCP (GKE + Managed Kafka)
- **Enterprise/On-Prem** — Air-gap bundles; Ansible playbooks for VM deployments

---

## 10. Security Model

1. **API Key Management** — Exclusively via environment variables or OS keychain. Never written to disk.
2. **nREPL Access Control** — Binds to localhost only. Disabled in production unless `MR_NREPL_ENABLED=true`.
3. **Component Sandboxing** — Token budget limits, timeout enforcement, output schema validation, blocked tool lists.
4. **Rule Artifact Integrity** — Rule JARs signed and hash-verified before loading. CLI binary signed.

**Threat model:**
- Cost-escalation attack: per-component token budget limits + escalation rate limiting
- Decision API auth (Pattern B): Bearer JWT or mTLS in production
- Rule injection: hash verification against `lock.edn` manifest
- Tenant isolation: row-level security (PostgreSQL) or key-prefixed isolation (SQLite)

---

## 11. Testing Strategy

- **Component-level** — `mr test <c> --potency P1 --corpus test-data/X.edn`: schema compliance,
  behavioral equivalence, performance bounds
- **Cascade integration** — `mr test --cascade`: full escalation path validation
- **Differentiation regression** — After every `mr differentiate` or `mr reprogram`, DR runs
  most recent shadow dataset as regression suite
- **Property-based** — test.check generates random valid inputs; verifies output conforms to
  EMIT schema regardless of potency level

---

## 12. Migration & Adoption Guide

### 12.1 Minimum Viable Integration (Observation-Only)

Zero changes to existing agent logic:

1. `mr init` — configure smithy.edn with component definitions (schemas only)
2. Register `SmithyObservationAdvisor` or POST to `/observe` — all calls still reach LLM
3. Let run 1–4 weeks to accumulate decision traces
4. `mr plan` — review proposal; proceed to shadow if numbers look good

### 12.2 Ecosystem Positioning

| Layer | Concern | Smithy's Relationship |
|---|---|---|
| Communication Protocols (MCP, A2A) | How agents connect and communicate | Smithy components consume MCP tools; participate in A2A networks |
| Execution Frameworks (Spring AI, LangGraph, CrewAI) | How agents run | Smithy plugs in as an optimization layer |
| Optimization Frameworks | How agent behavior gets cheaper | Smithy's domain: full-spectrum P4→P1 differentiation |

- **vs. DSPy:** DSPy optimizes prompts/weights within a model call. Smithy eliminates the model
  call entirely for 70% of traffic.
- **vs. Google A2A:** Orthogonal and complementary. A2A = inter-agent communication;
  Smithy = intra-agent optimization.

---

## 13. License

Apache License, Version 2.0. Compatible with Drools (also Apache 2.0) and enterprise adoption.
Third-party dependencies in `NOTICE.md`.

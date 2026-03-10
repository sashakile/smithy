# Smithy Type System — v2.1 Reference

**Version:** 2.1 (March 2026)
**Status:** Authoritative. Post Rule-of-5 review — all 23 issues resolved.
**Constraint:** No type may have more than 7 required fields. Any type with >7 must be split.

---

## Design Principles

| # | Principle | Enforcement |
|---|---|---|
| 1 | No type > 7 required fields | Schema validates at build. If >7, split. |
| 2 | Identity ≠ State ≠ Config | Cell (immutable), Fate (mutable), Wiring (config). Never merged. |
| 3 | Extension by composition | Annotations is open. New features = namespaced keys. |
| 4 | One function, one job | receive/decide/act/emit do one thing. then threads. cascade orchestrates. |
| 5 | Dispatch on mechanism | DECIDE dispatches on :engine (how), not :potency (where). |
| 6 | Cascade is orchestration | Cascade lives outside pipeline. No cross-potency middleware. |
| 7 | All changes are Proposals | Differentiate, reprogram, split, fuse use one type. One workflow. |
| 8 | PII-safe by redaction | Raw input stored (differentiation needs it). PII fields redacted by middleware. |
| 9 | Config mirrors types | smithy.edn sections map 1:1 to runtime types. |
| 10 | Faults carry the minimum | 5 fields. Context added by middleware/tracing, not embedded in error. |

---

## 1. Atomic Types

### 1.1 Potency

```clojure
(def Potency [:enum :P1 :P2 :P3 :P4])
(def potency-rank {:P1 1 :P2 2 :P3 3 :P4 4})

(defn above [p] (get {:P1 :P2 :P2 :P3 :P3 :P4} p))
(defn below [p] (get {:P4 :P3 :P3 :P2 :P2 :P1} p))
(defn higher? [a b] (> (potency-rank a) (potency-rank b)))
```

Total ordering built into the type. 3 operations, nothing else.

### 1.2 Genome — 2 fields

The DNA of every cell. Invariant across all potency levels.

```clojure
(def Genome
  [:map {:closed true}
   [:in  :malli/schema]   ;; what the component accepts
   [:out :malli/schema]]) ;; what the component produces
```

### 1.3 Decision — 2 fields

Atomic unit of DECIDE output. Renamed from v2.0 "Disposition" for clarity.

```clojure
(def Decision
  [:map
   [:value any?]
   [:confidence [:double {:min 0.0 :max 1.0}]]])
```

Decision is content. Outcome is the envelope. "I decided but I'm not sure" is `{:ok ...}` with
low confidence, NOT a fault.

### 1.4 Fault — 5 fields (4 required + 1 optional)

```clojure
(def Fault
  [:map
   [:origin  [:enum :parse :in :decide :act :out]]
   [:kind    qualified-keyword?]
   [:message string?]
   [:retry?  boolean?]
   [:retry-after-ms {:optional true} pos-int?]])
```

`:parse` origin covers pre-RECEIVE JSON errors. `:retry-after-ms` carries provider hints.

### 1.5 Outcome — 2 variants

```clojure
(def Outcome
  [:or
   [:map [:ok    Decision]]
   [:map [:fault Fault]]])
```

`:uncertainty` variant removed. Low confidence is a Decision below threshold — cascade checks
the number, not a special type. Cascade returns BEST Decision even if below threshold.

---

## 2. Component Model

### 2.1 Cell — 2 fields (Component Identity)

Immutable after registration. What the component IS.

```clojure
(def Cell
  [:map
   [:id     keyword?]
   [:genome Genome]])
```

### 2.2 Fate — 4 fields (Runtime State)

Where the component currently sits. Changes on differentiate/reprogram.

```clojure
(def Fate
  [:map
   [:cell-id   keyword?]
   [:potency   Potency]
   [:threshold [:double {:min 0.0 :max 1.0}]]
   [:version   pos-int?]])   ;; monotonic, CAS key
```

- `Fate.threshold` is always the current scalar value regardless of strategy.
- Threshold strategy (static/adaptive/shadow-calibrated) lives in Wiring, not Fate.
- Adaptive tuner updates via `update-fate!` with CAS on `:version`.

### 2.3 Expression — 4 fields (DECIDE Implementation)

A concrete DECIDE implementation at a specific potency level. A cell can have MULTIPLE
expressions at the same potency.

```clojure
(def Expression
  [:map
   [:cell-id keyword?]
   [:potency Potency]
   [:engine  keyword?]    ;; :drools, :onnx, :llm, :lookup, :clojure
   [:ref     any?]])      ;; engine-specific reference
```

Registry stores expressions as `{[cell-id Potency] -> [Expression]}` (vector, not single).
Cascade iterates through all expressions at a potency level before escalating.

### 2.4 Wiring — 8 fields (1 required) (Operational Config)

```clojure
(def Wiring
  [:map
   [:cell-id            keyword?]
   [:cascade            {:optional true} CascadeConfig]
   [:depends-on         {:optional true} [:set keyword?]]
   [:middleware         {:optional true} [:vector qualified-keyword?]]
   [:engine-opts        {:optional true} [:map-of keyword? any?]]
   [:effects            {:optional true} [:vector Effect]]
   [:threshold-strategy {:optional true} ThresholdStrategy]
   [:store-raw-input    {:optional true} boolean?]])  ;; opt-in PII storage

(def CascadeConfig
  [:map
   [:skip       {:optional true} [:set Potency]]
   [:timeout-ms {:optional true :default 30000} pos-int?]
   [:fallback   {:optional true} Potency]])

(def ThresholdStrategy
  [:or
   [:map [:strategy [:= :static]]]
   [:map [:strategy [:= :adaptive]]
         [:alpha            {:default 0.05} [:double {:min 0.0 :max 1.0}]]
         [:bounds           {:default [0.5 0.99]} [:tuple double? double?]]
         [:cooldown-minutes {:default 60} pos-int?]]
   [:map [:strategy [:= :shadow-calibrated]]
         [:target-agreement {:default 0.95} double?]]])
```

### 2.5 Composition

```clojure
(defn resolve [registry cell-id]
  (let [fate (get-in registry [:fates cell-id])]
    {:cell   (get-in registry [:cells cell-id])
     :fate   fate
     :exprs  (get-in registry [:expressions [cell-id (:potency fate)]])  ;; vector!
     :wiring (get-in registry [:wirings cell-id])}))
```

v1: one 20-field map. v2.1: four small maps, composed by cell-id.

---

## 3. Engine Protocol

### 3.1 IEngine — 2 methods

Primary extension surface. Every DECIDE implementation is backed by an engine.

```clojure
(defprotocol IEngine
  (init-engine [engine expression]
    "Initialize engine from Expression.ref. Called once at registration.
     Returns an opaque engine-state (KieSession, ONNX session, etc.).")
  (invoke [engine engine-state input ctx]
    "Run the engine on validated input. Returns a Decision.
     MUST NOT return Outcome — infrastructure faults are exceptions,
     caught by middleware. invoke only produces Decisions."))
```

### 3.2 Built-in Engines

| Engine | init-engine | invoke |
|---|---|---|
| `:drools` | Creates KIE container + scanner | Stateless session, inserts facts, fires rules, extracts Decision |
| `:onnx` | Loads DJL ONNX model | Converts input to tensor, runs prediction, decodes label + max prob |
| `:llm` | Creates `{:client :model :prompt}` | Calls LLM, parses JSON body; confidence defaults to 0.8 if absent |
| `:lookup` | Reads EDN table | Key-field lookup; `{:confidence 1.0}` on hit, `{:confidence 0.0}` on miss |
| `:clojure` | Resolves var via `requiring-resolve` | Calls `(f input ctx)` |

---

## 4. Pipeline

### 4.1 The Four Functions

```clojure
(defn receive [genome input]
  ;; Validate + normalize input against genome :in schema.
  ;; Selects only schema-defined keys (extra keys logged, not forwarded).
  ;; Ensures all potency levels see identical input shapes.
  ...)

(defn act [effects decision]
  ;; Execute side effects. The ONLY impure step. Returns enriched Decision.
  ...)

(defn emit [genome value]
  ;; Validate output against genome :out schema.
  ...)
```

`receive` normalizes input — selects only keys defined in `:in` schema. Extra keys are dropped
before DECIDE sees them, ensuring P1 Drools and P4 LLM see identical input shapes during
shadow comparison.

### 4.2 Pipeline Composition

```clojure
(defn then [outcome f]
  (if (:ok outcome) (f (:ok outcome)) outcome))

(defn run-pipeline [cell expression wiring input ctx]
  (-> (receive genome input)
      (then #(invoke-engine expression engine-state % ctx))
      (then #(act (:effects wiring) %))
      (then #(emit genome (:value %)))))
```

Uses `->` (thread-first), NOT `->>` (thread-last).

### 4.3 Cascade

Lives OUTSIDE the pipeline. Runs pipelines at different potency levels until one succeeds
with sufficient confidence, or returns the best sub-threshold Decision.

```clojure
(defn cascade [cell fate expressions-by-potency wiring input ctx]
  (let [levels (cascade-order (:potency fate) wiring)
        thresh (:threshold fate)]
    (reduce
      (fn [best-so-far potency]
        (let [exprs   (get expressions-by-potency potency [])
              results (for [expr exprs] (run-pipeline cell expr wiring input ctx))
              wins    (->> results (filter :ok) (sort-by #(-> % :ok :confidence) >))
              best    (first wins)]
          (cond
            (and best (>= (-> best :ok :confidence) thresh))
              (reduced best)          ;; confident enough — stop
            best
              (if (or (nil? best-so-far) (:fault best-so-far)
                      (> (-> best :ok :confidence)
                         (-> best-so-far :ok :confidence 0.0)))
                best best-so-far)     ;; sub-threshold, keep best
            :else
              (or best-so-far {:fault {:origin :decide :kind :cascade/exhausted
                                       :message "All levels exhausted" :retry? false}}))))
      nil levels)))

(defn cascade-order [base-potency wiring]
  (let [skip (get-in wiring [:cascade :skip] #{})]
    (->> [:P1 :P2 :P3 :P4]
         (filter #(<= (potency-rank %) (potency-rank base-potency)))
         (remove skip)
         (sort-by potency-rank))))
```

---

## 5. Signals

### 5.1 Trace — 6 fields (Core Observation)

```clojure
(def Trace
  [:map
   [:id       string?]       ;; trace ID (OpenTelemetry compatible)
   [:cell-id  keyword?]
   [:potency  Potency]
   [:ts       inst?]
   [:decision Decision]
   [:input    any?]])        ;; raw input (stored by default)
```

`:store-raw-input` defaults to TRUE — `mr plan` needs raw inputs to generate Drools rules.
PII-sensitive fields redacted via `wrap-pii-redaction` middleware before the trace is written.

### 5.2 Span — 6 fields (Performance)

```clojure
(def Span
  [:map
   [:trace-id      string?]
   [:latency-ms    double?]
   [:cost          {:optional true} [:double {:min 0.0}]]
   [:tokens        {:optional true} nat-int?]
   [:cascade-depth nat-int?]
   [:cascade-path  [:vector Potency]]])
```

### 5.3 Annotations — open map (Extensible Metadata)

```clojure
(def Annotations
  [:map
   [:trace-id string?]
   [:data [:map-of keyword? any?]]])
```

Extension by namespace. Namespaced keys: `:pii.redacted-fields`, `:topology.cluster-id`,
`:topology.reasoning-fingerprint`, `:extra-input-keys`.

### 5.4 ISignalStore — 5 operations

```clojure
(defprotocol ISignalStore
  (append! [store trace span annotations])
  (query   [store cell-id opts])
  (count-by [store cell-id group-fn])
  (purge!  [store cell-id before-ts])
  (export  [store cell-id format]))

(def QueryOpts
  [:map
   [:since   {:optional true} inst?]
   [:until   {:optional true} inst?]
   [:potency {:optional true} Potency]
   [:limit   {:optional true} pos-int?]
   [:cursor  {:optional true} string?]])
```

Implementations: SQLite (dev), PostgreSQL/TimescaleDB (prod), in-memory (test).

---

## 6. Registry

### 6.1 Data Model

```clojure
(def Registry
  [:map
   [:cells       [:map-of keyword? Cell]]
   [:fates       [:map-of keyword? Fate]]
   [:expressions [:map-of [:tuple keyword? Potency] [:vector Expression]]]  ;; VECTOR
   [:wirings     [:map-of keyword? Wiring]]])
```

### 6.2 IRegistry — 5 operations

```clojure
(defprotocol IRegistry
  (register!       [reg cell expressions wiring]
    ;; Called by: mr init, smithy.edn loader at startup.
    ;; Creates initial Fate at highest available Expression potency.)
  (resolve         [reg cell-id]
    ;; Called by: Router on every incoming request.)
  (update-fate!    [reg cell-id expected-version f]
    ;; Called by: mr differentiate, mr reprogram, adaptive threshold tuner.
    ;; CAS semantics: checks :version == expected-version, applies f, increments :version.
    ;; Throws on version mismatch. Callers retry on conflict.)
  (add-expression! [reg cell-id expression]
    ;; Called by: mr plan (adds proposed Expression), mr differentiate (commits).
    ;; Appends to expression vector at [cell-id, potency].)
  (commit-diff!    [reg diff]
    ;; Called by: Proposal commit workflow.
    ;; Applies RegistryDiff ATOMICALLY. All mutations succeed or none do.))
```

---

## 7. Proposals

All changes (differentiate, reprogram, split, fuse) are Proposals: a diff + evidence, with
lifecycle: `draft → shadow → review → commit`.

```clojure
(def Proposal
  [:map
   [:id     string?]
   [:kind   [:enum :differentiate :reprogram :split :fuse]]
   [:status [:enum :draft :shadowing :reviewing :approved :committed :rejected]]
   [:diff   RegistryDiff]
   [:evidence Evidence]])

(def RegistryDiff
  [:map
   [:fates-update      {:optional true} [:map-of keyword? Fate]]
   [:expressions-add   {:optional true} [:vector Expression]]
   [:wirings-update    {:optional true} [:map-of keyword? Wiring]]
   [:cells-add         {:optional true} [:vector Cell]]
   [:cells-deprecate   {:optional true} [:set keyword?]]])

(def Evidence
  [:map
   [:traces-analyzed  {:optional true} pos-int?]
   [:coverage         {:optional true} [:double {:min 0.0 :max 1.0}]]
   [:agreement        {:optional true} [:double {:min 0.0 :max 1.0}]]
   [:signals          {:optional true} [:vector Signal]]
   [:shadow           {:optional true} ShadowResults]
   [:cost-projection  {:optional true} CostProjection]])

(def ShadowResults
  [:map
   [:strategy        [:enum :full :sampled :budget-capped]]
   [:sample-rate     [:double {:min 0.0 :max 1.0}]]
   [:duration-hours  pos-int?]
   [:agreement       [:double {:min 0.0 :max 1.0}]]
   [:p-value         {:optional true} [:double {:min 0.0 :max 1.0}]]
   [:latency         [:map [:current-p50 double?] [:proposed-p50 double?]
                           [:current-p99 double?] [:proposed-p99 double?]]]
   [:cost            [:map [:current-per-req double?] [:proposed-per-req double?]]]])

(def CostProjection
  [:map [:current-daily double?] [:projected-daily double?] [:savings-pct double?]])
```

---

## 8. HTTP API

### 8.1 Resource Model

| Resource | Path | Methods |
|---|---|---|
| Cells | /v1/cells | GET |
| Cell | /v1/cells/:id | GET |
| Fate | /v1/cells/:id/fate | GET, PUT |
| Traces | /v1/cells/:id/traces | GET |
| Shadow | /v1/cells/:id/shadow | POST, GET, DELETE |
| Decide | /v1/decide | POST |
| Batch | /v1/decide/batch | POST |
| Observe | /v1/observe | POST |
| Health | /v1/health | GET |

### 8.2 POST /v1/decide

Request (2 fields):
```json
{"cell": "ticket-classifier", "input": {...}}
```

Response (5 fields):
```json
{"value": {...}, "confidence": 0.94, "potency": "P1", "latency_ms": 0.8, "trace_id": "tr-001"}
```

### 8.3 Error Responses

Fault IS the API error type — one shape everywhere:
```json
{"fault": {"origin": "in", "kind": "schema/invalid-input", "message": "..."}}
```

HTTP status mapping:
- `:origin :parse` or `:in` → 400
- `:kind :cascade/exhausted` → 500
- `:kind :*/budget-exhausted` or `:*/rate-limited` → 429
- Cell not found → 404
- DR not ready → 503

---

## 9. Observability

### 9.1 Prometheus Metrics

| Metric | Type | Labels |
|---|---|---|
| smithy_decide_seconds | histogram | cell, potency, engine |
| smithy_decide_errors_total | counter | cell, potency, kind |
| smithy_cascade_depth | histogram | cell |
| smithy_cost_dollars | gauge | cell, potency, engine |
| smithy_tokens_total | counter | cell, provider, model |
| smithy_potency_traffic | counter | cell, potency |
| smithy_shadow_agreement | gauge | cell |
| smithy_threshold_current | gauge | cell |
| smithy_circuit_break_total | counter | cell |

### 9.2 Bundled Alert Rules

| Alert | Condition | Severity |
|---|---|---|
| SmithyHighCascadeRate | P4 traffic ratio > 30% for 10m | warning |
| SmithyCircuitBreak | Any circuit break event | critical |
| SmithyEmitViolation | Any output schema violation | critical |
| SmithyCostSpike | Cost > 2× 7-day average | warning |

---

## 10. Full Type Inventory

| Type | Fields | Purpose |
|---|---|---|
| Potency | enum(4) | Level in differentiation hierarchy |
| Genome | 2 | Input/output schema contract |
| Decision | 2 | DECIDE output: value + confidence |
| Fault | 5 (4 req) | Error: origin, kind, message, retry?, retry-after-ms |
| Outcome | 2 variants | Decision or Fault |
| Cell | 2 | Immutable component identity |
| Fate | 4 | Runtime state: potency + threshold + version |
| Expression | 4 | DECIDE implementation (engine + ref) |
| Wiring | 8 (1 req) | Operational config: cascade, deps, effects, strategy |
| IEngine | 2 methods | Extension protocol: init + invoke |
| Trace | 6 | What happened |
| Span | 6 | How it performed |
| Annotations | 2 (open) | Extensible metadata |
| SignalCollector | atom | Middleware → storage bridge |
| ISignalStore | 5 methods | Storage protocol |
| IRegistry | 5 methods | Runtime store protocol |
| Proposal | 5 | Proposed registry change |
| RegistryDiff | 5 (all opt) | What mutations the proposal makes |
| Evidence | 6 (all opt) | Why the proposal is justified |
| ShadowResults | 7 | Comparison data |
| CostProjection | 3 | Savings estimate |

**v1 → v2.1 metrics:**

| Metric | v1 | v2.1 |
|---|---|---|
| Max fields on any type | 20 | 8 (Wiring, 1 required) |
| Avg fields per type | ~14 | ~4 |
| Types with >10 fields | 5 | 0 |
| Missing protocols | 3 | 0 |

## Purpose
Define signal collection (Trace, Span, Annotations), PII handling via redaction middleware, the ISignalStore protocol, and Prometheus metrics emitted for every cascade execution.

## Requirements

### Requirement: Every pipeline execution produces a Trace
The system SHALL record a Trace for every cascade execution, capturing the cell-id, potency,
timestamp, Decision, and input. Traces SHALL be flushed after the cascade completes, not
during pipeline stages.

#### Scenario: Successful request produces a Trace
- **WHEN** a decide request completes successfully
- **THEN** a Trace containing trace-id, cell-id, potency, ts, decision, and input is written to the Signal Store

#### Scenario: Failed request produces a Trace with fault
- **WHEN** a decide request results in a cascade fault
- **THEN** a Trace is still written, recording the fault outcome

### Requirement: Raw input stored by default; PII redacted by middleware
The system SHALL store raw input in Trace by default (`:store-raw-input` defaults to true),
because `mr plan` requires raw inputs to generate Drools rules. PII fields SHALL be redacted
via `wrap-pii-redaction` middleware BEFORE the trace is written.

#### Scenario: Raw input is stored in Trace by default
- **WHEN** `:store-raw-input` is not configured in Wiring
- **THEN** Trace.input contains the full normalized input

#### Scenario: PII fields are redacted before trace write
- **WHEN** `wrap-pii-redaction` middleware is configured with `[:email :ssn]`
- **THEN** Trace.input has those fields replaced with redaction markers; Annotations records `:pii.redacted-fields`

#### Scenario: Opt-out stores only input hash
- **WHEN** `:store-raw-input false` is set in Wiring
- **THEN** Trace.input is nil and Annotations records the input hash for deduplication

### Requirement: Signal Store has five operations
The system SHALL implement ISignalStore with exactly five operations: `append!`, `query`,
`count-by`, `purge!`, and `export`. All storage backends SHALL implement this protocol.

#### Scenario: SQLite is used in development
- **WHEN** DR is started without storage configuration
- **THEN** SQLite is used as the Signal Store backend with a 30-day rolling retention window

#### Scenario: PostgreSQL/TimescaleDB is used in production
- **WHEN** DR is configured with a PostgreSQL connection string
- **THEN** PostgreSQL with TimescaleDB hypertables is used with 90-day raw retention

### Requirement: Annotations extend signals via namespaced keys
The system SHALL extend signal metadata via namespaced keys in the Annotations open map.
New features SHALL add namespaced keys to Annotations rather than modifying Trace or Span schemas.

#### Scenario: Topology metadata stored in Annotations
- **WHEN** a component has been analyzed for topology adaptation
- **THEN** `:topology.cluster-id` and `:topology.reasoning-fingerprint` are present in Annotations.data

### Requirement: Prometheus metrics are emitted for every decide call
The system SHALL emit the following Prometheus metrics for every cascade execution:
`smithy_decide_seconds` (histogram), `smithy_decide_errors_total` (counter),
`smithy_cascade_depth` (histogram), `smithy_potency_traffic` (counter).

#### Scenario: Successful decide emits latency metric
- **WHEN** a decide call completes at P1
- **THEN** `smithy_decide_seconds{cell="...", potency="P1", engine="drools"}` is observed

#### Scenario: LLM cost is tracked per call
- **WHEN** a P4 LLM call completes
- **THEN** `smithy_cost_dollars{cell="...", potency="P4", engine="llm"}` is updated with the call cost

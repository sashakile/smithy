## Purpose
Define the six-layer standard stage middleware stack, the Ring interceptor composition pattern, retry semantics, explicit cascade escalation results, the mandatory signal-write redaction middleware, and custom middleware declaration in smithy.edn.

## Requirements

### Requirement: Middleware follows Ring interceptor pattern
The system SHALL implement middleware as `(handler -> handler)` functions that compose via
`comp`. The middleware stack SHALL wrap each pipeline stage individually (stage-level
granularity), not the full pipeline. Each wrapped handler SHALL preserve the stage result
carrier `{:ok ...} | {:fault ...} | {:escalate ...}`.

#### Scenario: Custom middleware wraps a single stage
- **WHEN** custom middleware is applied to the `:decide` stage
- **THEN** it does not affect RECEIVE, ACT, or EMIT execution

### Requirement: Six standard stage middleware layers execute in order
The system SHALL provide six standard middleware layers applied outermost-first:
`wrap-trace-context`, `wrap-structured-logging`, `wrap-metrics`, `wrap-cascade-bridge`,
`wrap-retry`, `wrap-error-enrichment`.

#### Scenario: Trace context is available to all inner middleware
- **WHEN** a pipeline stage executes
- **THEN** `:trace-id` and `:span-id` are present in the pipeline context for all inner layers

#### Scenario: Error enrichment normalizes raw exceptions
- **WHEN** a pipeline stage throws an unhandled exception
- **THEN** `wrap-error-enrichment` catches it and produces a canonical Fault map with :origin, :component, :potency, :timestamp, :trace-id populated

#### Scenario: Retry sees classified faults from inner middleware
- **WHEN** a `:decide` handler throws a transient infrastructure exception
- **THEN** `wrap-error-enrichment` converts it to a Fault before `wrap-retry` evaluates whether to retry

#### Scenario: Middleware preserves explicit escalation results
- **WHEN** an inner handler returns `{:escalate ...}`
- **THEN** outer middleware propagates that result without converting it to `:ok` or mutating pipeline context

### Requirement: wrap-retry only retries :transient errors
The system SHALL retry only errors with severity `:transient` in the `:decide` and `:act` stages.
`:fatal` and `:degraded` errors SHALL NOT be retried. Maximum retries defaults to 2;
base delay 100ms; max delay 5000ms with exponential backoff and jitter.

#### Scenario: :transient LLM timeout is retried
- **WHEN** an LLM call returns `:decide :llm/timeout` (severity :transient)
- **THEN** `wrap-retry` retries up to 2 times with exponential backoff

#### Scenario: :fatal budget exhaustion is not retried
- **WHEN** `:decide :llm/budget-exhausted` (severity :fatal) is returned
- **THEN** `wrap-retry` does not retry and immediately returns the fault

#### Scenario: Retry-After header is respected
- **WHEN** a `:llm/rate-limited` error includes `:retry-after-ms` in the Fault
- **THEN** `wrap-retry` waits exactly that duration before retrying

### Requirement: wrap-cascade-bridge signals cascade on exhausted retries
The system SHALL return `{:escalate fault}` when `wrap-retry` exhausts its retries on a
`:transient` `:decide` error, signaling Cascade to try the next potency level. It SHALL NOT
signal escalation by mutating the pipeline context.

#### Scenario: Exhausted retries trigger cascade
- **WHEN** all retry attempts fail for a :decide :transient error
- **THEN** `wrap-cascade-bridge` returns `{:escalate {:origin :decide :kind :retry/exhausted ...}}` and Cascade escalates to the next potency level

### Requirement: Signal persistence uses mandatory PII-redaction middleware
The system SHALL apply `wrap-pii-redaction` on the signal-write path before any Trace is
persisted to the Signal Store. This middleware SHALL be mandatory whenever raw input is
stored and SHALL use the component's configured redaction fields. If the redaction policy is
missing, malformed, or cannot be loaded, `wrap-pii-redaction` SHALL fail closed by stripping
raw input, preserving only the input hash, and annotating the trace with the policy failure.

#### Scenario: Trace write redacts configured fields
- **WHEN** a trace is flushed with raw input and Wiring configures `[:email :ssn]` as redacted fields
- **THEN** `wrap-pii-redaction` replaces those fields before `append!` is called on the Signal Store

#### Scenario: Missing redaction policy strips raw input
- **WHEN** raw input storage is enabled but the redaction policy is missing or malformed
- **THEN** `wrap-pii-redaction` removes raw input from the trace, stores only the input hash, and records a redaction-policy failure annotation

### Requirement: Custom middleware is declared in smithy.edn via stable capability slots
The system SHALL support declaring custom middleware in smithy.edn against stable capability
slots such as `:before-tracing`, `:before-retry`, `:after-retry`, and `:before-signal-write`,
rather than by naming concrete implementation functions. Per-component `:retry` and `:logging`
keys SHALL override DR-level defaults.

#### Scenario: Custom middleware targets retry slot
- **WHEN** smithy.edn declares custom middleware with `:slot :before-retry`
- **THEN** the custom middleware executes before the standard retry capability in the onion order

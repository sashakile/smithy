## Purpose
Define the DR HTTP API: the /v1/decide and /v1/decide/batch decision endpoints, /v1/observe for observation-only mode, /v1/health, and the universal Fault error type.

## Requirements

### Requirement API-001 [Priority: P1]: POST /v1/decide accepts cell and input
The system SHALL accept POST requests to `/v1/decide` with a JSON body containing required
fields `cell` (string, cell-id) and `input` (object). Additional optional fields: `options.max_potency`,
`options.timeout_ms`, `options.trace` (boolean).

#### Scenario: Valid decide request returns decision
- **WHEN** POST /v1/decide is called with `{"cell": "ticket-classifier", "input": {...}}`
- **THEN** response 200 contains `{value, confidence, potency, latency_ms, trace_id}`

#### Scenario: Unknown cell returns 404
- **WHEN** POST /v1/decide is called with a cell-id not registered in the Registry
- **THEN** response is 404 with `{"fault": {"origin": "in", "kind": "cell/not-found", ...}}`

### Requirement API-002 [Priority: P1]: Fault is the universal error type
The system SHALL use Fault as the error type for all API error responses. Every non-2xx
response SHALL include `{"fault": {"origin": ..., "kind": ..., "message": ...}}`.

#### Scenario: Schema validation failure returns 400 with Fault
- **WHEN** input fails RECEIVE schema validation
- **THEN** response is 400 with `{"fault": {"origin": "in", "kind": "schema/invalid-input", ...}}`

#### Scenario: JSON parse failure returns 400 with :parse origin
- **WHEN** request body is not valid JSON
- **THEN** response is 400 with `{"fault": {"origin": "parse", "kind": "schema/invalid-json", ...}}`

#### Scenario: Cascade exhaustion returns 500
- **WHEN** all potency levels fail with infrastructure faults
- **THEN** response is 500 with `{"fault": {"origin": "decide", "kind": "cascade/exhausted", ...}}`

#### Scenario: Budget exhaustion returns 429
- **WHEN** a component's token or cost budget is exceeded
- **THEN** response is 429 with Retry-After header and `{"fault": {"kind": "llm/budget-exhausted", ...}}`

#### Scenario: DR starting or stopping returns 503
- **WHEN** DR is not yet ready or is shutting down
- **THEN** response is 503

### Requirement API-003 [Priority: P1]: POST /v1/decide/batch accepts array input
The system SHALL accept POST requests to `/v1/decide/batch` with `{"cell": ..., "inputs": [...]}`.
Partial failures SHALL be represented per-element; the batch SHALL NOT fail atomically.
The default maximum batch size SHALL be 100 inputs, the default maximum request body size
SHALL be 1 MiB, and batch execution SHALL honor the same effective timeout budget as a
single `/v1/decide` call unless `options.timeout_ms` is set on the request envelope.
Batch execution SHALL assign each element a stable positional index from the request order and
SHALL preserve that positional index in the response regardless of scheduling.

#### Scenario: Batch with one failed input returns partial success
- **WHEN** a batch of 3 inputs is submitted and 1 fails schema validation
- **THEN** response contains 2 successful decisions and 1 fault, all in positional order

#### Scenario: Valid batch with all element faults still returns positional results
- **WHEN** a batch envelope is valid but every input fails RECEIVE validation
- **THEN** response is 200 and contains one fault result per input in positional order

#### Scenario: Malformed batch envelope returns 400
- **WHEN** `/v1/decide/batch` is called without a valid `cell` or with `inputs` that is not an array
- **THEN** response is 400 with `{"fault": {"origin": "in", "kind": "schema/invalid-batch", ...}}`

#### Scenario: Oversized batch is rejected
- **WHEN** `/v1/decide/batch` is called with more than 100 inputs or a request body larger than 1 MiB
- **THEN** response is 413 with `{"fault": {"origin": "in", "kind": "schema/batch-too-large", ...}}`

#### Scenario: Batch timeout returns positional timeout faults
- **WHEN** batch execution exceeds the effective timeout budget after some elements have completed
- **THEN** completed elements keep their positional results and unfinished elements return `{"fault": {"origin": "decide", "kind": "cascade/timeout", ...}}` in positional order

### Requirement API-004 [Priority: P2]: POST /v1/observe records without cascade
The system SHALL accept POST requests to `/v1/observe` to record a decision event in signaling
history without routing through the cascade. This is used during observation-only migration.

#### Scenario: Observe records trace without executing pipeline
- **WHEN** POST /v1/observe is called with a decision event
- **THEN** the trace is recorded in signal history and no pipeline stages are executed

### Requirement API-005 [Priority: P1]: GET /v1/health returns DR status
The system SHALL expose GET /v1/health returning 200 when all required subsystem probes pass
and 503 when any required subsystem probe fails. Required probes SHALL include Registry read,
Signal Store append capability, and Cascade execution readiness. The response SHALL identify
each required subsystem with `status` in `{healthy, degraded}` and a probe latency in
milliseconds.

#### Scenario: Healthy DR returns 200
- **WHEN** all DR subsystems (Registry, Signal Store, Cascade) are operational
- **THEN** GET /v1/health returns 200 with subsystem status details

#### Scenario: Degraded DR returns 503
- **WHEN** Signal Store is unavailable
- **THEN** GET /v1/health returns 503 with the degraded subsystem identified

### Requirement API-006 [Priority: P2]: Batch scheduler is bounded and cancellation-safe
The system SHALL execute batch elements independently with bounded parallelism configured by the
server. Each element SHALL own an independent cascade execution epoch. When the batch timeout
budget expires, elements with terminal results already committed SHALL retain them; elements whose
epochs are still open SHALL be closed and rendered as positional timeout Faults. A closed batch
element epoch SHALL suppress late writes and late response replacement for that element.

#### Scenario: Parallel scheduling preserves positional determinism
- **WHEN** batch elements 2 and 3 finish before element 1 under bounded parallel execution
- **THEN** the response still returns results in input order 1, 2, 3

#### Scenario: Timed-out element cannot overwrite timeout Fault
- **WHEN** an unfinished batch element completes after the batch timeout has closed its epoch
- **THEN** its late completion is discarded and the element remains a timeout Fault in the final response

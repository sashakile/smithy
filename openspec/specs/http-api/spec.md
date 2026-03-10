## Purpose
Define the DR HTTP API: the /v1/decide and /v1/decide/batch decision endpoints, /v1/observe for observation-only mode, /v1/health, and the universal Fault error type.

## Requirements

### Requirement: POST /v1/decide accepts cell and input
The system SHALL accept POST requests to `/v1/decide` with a JSON body containing exactly
`cell` (string, cell-id) and `input` (object). Additional optional fields: `options.max_potency`,
`options.timeout_ms`, `options.trace` (boolean).

#### Scenario: Valid decide request returns decision
- **WHEN** POST /v1/decide is called with `{"cell": "ticket-classifier", "input": {...}}`
- **THEN** response 200 contains `{value, confidence, potency, latency_ms, trace_id}`

#### Scenario: Unknown cell returns 404
- **WHEN** POST /v1/decide is called with a cell-id not registered in the Registry
- **THEN** response is 404 with `{"fault": {"origin": "in", "kind": "cell/not-found", ...}}`

### Requirement: Fault is the universal error type
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

### Requirement: POST /v1/decide/batch accepts array input
The system SHALL accept POST requests to `/v1/decide/batch` with `{"cell": ..., "inputs": [...]}`.
Partial failures SHALL be represented per-element; the batch SHALL NOT fail atomically.

#### Scenario: Batch with one failed input returns partial success
- **WHEN** a batch of 3 inputs is submitted and 1 fails schema validation
- **THEN** response contains 2 successful decisions and 1 fault, all in positional order

### Requirement: POST /v1/observe records without cascade
The system SHALL accept POST requests to `/v1/observe` to record a decision event in signaling
history without routing through the cascade. This is used during observation-only migration.

#### Scenario: Observe records trace without executing pipeline
- **WHEN** POST /v1/observe is called with a decision event
- **THEN** the trace is recorded in signal history and no pipeline stages are executed

### Requirement: GET /v1/health returns DR status
The system SHALL expose GET /v1/health returning 200 when all subsystems are healthy and 503
when any required subsystem is degraded.

#### Scenario: Healthy DR returns 200
- **WHEN** all DR subsystems (Registry, Signal Store, Cascade) are operational
- **THEN** GET /v1/health returns 200 with subsystem status details

#### Scenario: Degraded DR returns 503
- **WHEN** Signal Store is unavailable
- **THEN** GET /v1/health returns 503 with the degraded subsystem identified

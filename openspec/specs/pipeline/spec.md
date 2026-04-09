## Purpose
Define the four-stage RECEIVE→DECIDE→ACT→EMIT pipeline, the separation of concerns across stages, the shared stage result carrier used for composition, input normalization, output validation, and fault short-circuiting behavior.

## Requirements

### Requirement: Four-stage pipeline with strict separation
The system SHALL implement a four-stage pipeline: RECEIVE → DECIDE → ACT → EMIT. Each stage
SHALL have exactly one responsibility. Only DECIDE SHALL vary by potency level.

#### Scenario: Each stage has one responsibility
- **WHEN** the pipeline processes a request
- **THEN** RECEIVE validates/normalizes input, DECIDE applies logic, ACT executes side effects, EMIT validates output — no stage performs another stage's responsibility

### Requirement: All pipeline stages compose through a shared Outcome carrier
The system SHALL model successful stage composition through a shared carrier:
`{:ok value}` for success, `{:fault fault}` for terminal failure, and `{:escalate fault}` for
non-terminal escalation to Cascade. Every stage SHALL accept the unwrapped success value from the
prior stage and SHALL return one of these three variants. Stage composition SHALL use `then`
or an equivalent primitive that short-circuits on `:fault` and propagates `:escalate`
without invoking later stages in the current potency attempt.

#### Scenario: Successful stages return wrapped values
- **WHEN** RECEIVE, DECIDE, ACT, and EMIT complete successfully
- **THEN** each stage returns `{:ok ...}` and the next stage receives the unwrapped success value

#### Scenario: Escalation short-circuits the current potency attempt
- **WHEN** DECIDE or ACT returns `{:escalate {:origin :decide ...}}`
- **THEN** later stages at that potency are not invoked and Cascade receives the escalation result

### Requirement: RECEIVE normalizes input to schema-defined keys
The system SHALL strip any keys not defined in the component's `:in` genome schema before
passing input to DECIDE. Extra keys SHALL be logged to Annotations but SHALL NOT be forwarded.

#### Scenario: Extra input keys are dropped
- **WHEN** a request arrives with keys beyond those defined in the genome `:in` schema
- **THEN** RECEIVE drops the extra keys and DECIDE receives only schema-defined keys

#### Scenario: Input normalization is consistent across potency levels
- **WHEN** the same raw input is processed at P1 and P4 during shadow comparison
- **THEN** both potency levels receive identical normalized inputs

### Requirement: RECEIVE rejects invalid input with a Fault
The system SHALL validate input against the genome `:in` schema and return `{:fault {:origin :in ...}}`
for inputs that fail schema validation. Invalid input SHALL NOT reach DECIDE.

#### Scenario: Schema-invalid input is rejected at RECEIVE
- **WHEN** input is missing a required field defined in the genome `:in` schema
- **THEN** RECEIVE returns `{:fault {:origin :in :kind :schema/missing-field :retry? false}}`

#### Scenario: Pre-receive JSON parse errors produce :parse origin
- **WHEN** the HTTP request body cannot be parsed as JSON
- **THEN** the system returns `{:fault {:origin :parse :kind :schema/invalid-json :retry? false}}`

### Requirement: ACT is the only impure stage
The system SHALL confine all side effects (database writes, API calls, Slack notifications)
to the ACT stage. RECEIVE, DECIDE, and EMIT SHALL be pure functions.

#### Scenario: DECIDE produces no side effects
- **WHEN** DECIDE is invoked
- **THEN** it returns `{:ok Decision}` without writing to any external system

#### Scenario: ACT executes declared effects
- **WHEN** ACT is invoked with a list of Effect declarations in Wiring
- **THEN** it executes each declared effect and returns `{:ok enriched-Decision}`

### Requirement: EMIT validates output against genome schema
The system SHALL validate the final decision value presented to callers after ACT completes
against the component's `:out` genome schema. An output that fails schema validation SHALL
produce `{:fault {:origin :out :kind :schema/output-violation}}`.

#### Scenario: Schema-valid output passes EMIT
- **WHEN** the final value after ACT conforms to the genome `:out` schema
- **THEN** EMIT returns `{:ok {:value <output> :confidence <n>}}`

#### Scenario: Schema-invalid output is caught at EMIT
- **WHEN** the final value after ACT does not conform to the genome `:out` schema
- **THEN** EMIT returns `{:fault {:origin :out :kind :schema/output-violation :retry? false}}` and an alert is emitted

### Requirement: Pipeline composes stages with thread-first
The system SHALL compose pipeline stages using thread-first (`->`) with `then` for
Outcome-aware chaining. A terminal Fault or Escalation at any stage SHALL short-circuit remaining
stages in the current potency attempt.

#### Scenario: Fault short-circuits pipeline
- **WHEN** RECEIVE returns `{:fault ...}`
- **THEN** DECIDE, ACT, and EMIT are not called; the fault is returned directly

#### Scenario: Escalation short-circuits pipeline
- **WHEN** DECIDE returns `{:escalate ...}`
- **THEN** ACT and EMIT are not called; the escalation is returned directly to Cascade

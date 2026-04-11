## MODIFIED Requirements

### Requirement: CAS-009 [Priority: P1]: Cascade timeout closes the execution epoch
The system SHALL assign each cascade execution a unique execution epoch with explicit states
`:open`, `:closing`, and `:closed`. Timeout, client cancellation, and early threshold-meeting
success SHALL move the epoch from `:open` to `:closing`; once the terminal result and trace
publication decision have been committed, the epoch SHALL become `:closed`. Handlers, retry
loops, ACT effects, EMIT, and trace flushes associated with a non-`open` epoch SHALL NOT publish
new externally visible results. Any externally visible ACT effect or terminal publication SHALL
carry an idempotency key derived from the execution epoch, the publication kind, and the target
sink identity so that late retries or duplicated completions cannot create a second externally
visible outcome. Publication adapters and sinks that can emit externally visible effects SHALL
retain deduplication state for those keys for at least the maximum configured retry horizon of the
execution. In-flight work MAY continue
internally until cooperative cancellation is observed, but any late completion after epoch closure
SHALL be discarded rather than persisted or returned.

#### Scenario: Late ACT completion is discarded after timeout
- **WHEN** cascade times out after P2 completes and an in-flight P3 ACT finishes later
- **THEN** the P3 completion does not execute external effects, does not flush a trace, and does not replace the timeout result

#### Scenario: Early confident result closes later potency attempts
- **WHEN** P1 returns a threshold-meeting Decision before P2 starts
- **THEN** the cascade epoch enters `:closing`, commits the terminal result once, and no later potency attempt publishes a competing result

#### Scenario: Duplicate external publication is suppressed by idempotency key
- **WHEN** an ACT adapter retries after the epoch has already committed a terminal result
- **THEN** the idempotency key prevents a second externally visible effect or terminal publication from being observed

#### Scenario: Different sinks use different idempotency keys
- **WHEN** the same execution publishes a terminal decision to one sink and an ACT effect to another sink
- **THEN** each publication uses a distinct idempotency key derived from the epoch, publication kind, and sink identity

#### Scenario: Deduplication survives adapter retry delay
- **WHEN** an adapter retries within the configured retry horizon after a prior publish attempt already succeeded
- **THEN** the sink suppresses the duplicate publication using retained deduplication state for the idempotency key

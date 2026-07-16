## Purpose
Define the cascade orchestration mechanism that tries potency levels in ascending order, consumes explicit pipeline stage results, combines candidate outcomes with a deterministic fold, returns the best sub-threshold Decision on exhaustion, and manages concurrent Fate updates with CAS semantics.

## Requirements

### Requirement CAS-001 [Priority: P1]: Cascade lives outside the pipeline
The system SHALL implement cascade as an orchestrator that calls the pipeline at successive
potency levels. Cascade SHALL NOT be a pipeline stage. Each pipeline invocation SHALL be
independently testable.

#### Scenario: Pipeline is invocable without cascade
- **WHEN** a single pipeline is invoked directly at a specific potency level
- **THEN** it executes RECEIVE→DECIDE→ACT→EMIT without cascade logic

### Requirement CAS-002 [Priority: P1]: Cascade tries potency levels in ascending order
The system SHALL try potency levels from P1 up to P4 in ascending order, starting the search
at P1 regardless of the component's current Fate potency. A differentiated component's
unconfident traffic SHALL escalate to higher (more expensive) levels. Levels in the
`:cascade :skip` set SHALL be omitted. `{:escalate ...}` results from the pipeline SHALL
advance Cascade to the next eligible potency level without being treated as terminal faults.

#### Scenario: Cascade stops at first confident result
- **WHEN** P1 returns a Decision with confidence ≥ threshold
- **THEN** cascade returns that Decision and does not invoke P2, P3, or P4

#### Scenario: Cascade skips configured levels
- **WHEN** `:cascade {:skip #{:P2 :P3}}` is configured
- **THEN** cascade tries only P1 and P4, skipping P2 and P3

#### Scenario: Escalation advances to the next potency
- **WHEN** a P2 pipeline attempt returns `{:escalate {:kind :retry/exhausted ...}}`
- **THEN** cascade records that result and tries P3 next if P3 is eligible

### Requirement CAS-003 [Priority: P1]: Cascade returns best sub-threshold Decision on exhaustion
The system SHALL return the highest-confidence Decision seen across all potency levels when
no level meets the threshold, rather than returning a Fault. A Fault SHALL only be returned
when all potency levels produce infrastructure faults.

#### Scenario: All levels below threshold returns best Decision
- **WHEN** P1 returns confidence 0.6 and P4 returns confidence 0.75, threshold is 0.80
- **THEN** cascade returns the P4 Decision (confidence 0.75), not a Fault

#### Scenario: All levels produce infrastructure faults returns Fault
- **WHEN** every potency level returns `{:fault ...}` due to infrastructure failure
- **THEN** cascade returns `{:fault {:origin :decide :kind :cascade/exhausted :retry? false}}`

### Requirement CAS-004 [Priority: P1]: Candidate selection is a deterministic associative fold
The system SHALL combine results within a potency level and across potency levels using a
deterministic associative fold over candidate results. The combine function SHALL prefer:
(1) any threshold-meeting Decision over all other candidates,
(2) otherwise the highest-confidence Decision,
(3) otherwise `{:escalate ...}` over terminal faults,
(4) otherwise the terminal Fault with the highest deterministic precedence. Fault precedence
SHALL be ordered by: `:retry? false` before `:retry? true`, then lower potency before higher
potency, then ascending immutable `:registration-order` within a potency level. Ties between
Decisions with equal confidence SHALL be broken deterministically by ascending immutable
`:registration-order` within a potency level and then by lower potency before higher potency
across levels. The fold SHALL define an identity element representing "no candidate yet".

#### Scenario: Equal-confidence decisions resolve deterministically
- **WHEN** two expressions at the same potency both return confidence 0.90
- **THEN** cascade selects the expression with the lower immutable `:registration-order`

#### Scenario: Fold identity does not affect the result
- **WHEN** candidate reduction begins from the empty candidate
- **THEN** combining the empty candidate with any actual result yields the same result

### Requirement CAS-005 [Priority: P1]: Multiple expressions per potency level are all tried
The system SHALL store expressions as a vector per `[cell-id, potency]` pair. Cascade SHALL
try all expressions at a potency level before escalating to the next level.

#### Scenario: Multiple P1 expressions are all evaluated
- **WHEN** a cell has two P1 expressions (e.g., two Drools rule sets)
- **THEN** cascade invokes both and uses the one with the highest confidence

### Requirement CAS-006 [Priority: P1]: Cascade uses CAS for concurrent Fate updates
The system SHALL use compare-and-swap (CAS) semantics on `Fate.version` when updating potency
or threshold. Callers SHALL retry on version mismatch.

#### Scenario: Concurrent Fate update conflict is detected
- **WHEN** two callers attempt to update Fate simultaneously with the same expected version
- **THEN** one succeeds and one receives a version-mismatch error and retries

### Requirement CAS-007 [Priority: P2]: Cascade timeout is configurable
The system SHALL support a configurable `:cascade :timeout-ms` (default: 35000ms). If the
cascade exceeds this timeout, the highest-confidence result obtained so far SHALL be returned.
If no potency level has completed before the timeout, cascade SHALL return
`{:fault {:origin :decide :kind :cascade/timeout :retry? true}}`.

#### Scenario: Cascade timeout returns best result
- **WHEN** cascade timeout is reached while P3 is still executing
- **THEN** cascade returns the best Decision obtained from P1 and P2 without waiting for P3

#### Scenario: Cascade timeout before any result returns fault
- **WHEN** cascade timeout is reached before P1 produces any Decision or Fault
- **THEN** cascade returns `{:fault {:origin :decide :kind :cascade/timeout :retry? true}}`

### Requirement CAS-008 [Priority: P2]: Candidate fold laws are property-tested
The system SHALL verify the candidate combine operation with property-based tests for
associativity and identity so regrouping or parallel reduction cannot change selection results.

#### Scenario: Candidate fold remains stable under regrouping
- **WHEN** candidate results are reduced as `(combine a (combine b c))` and `((combine a b) c)`
- **THEN** both reductions yield the same selected candidate

### Requirement CAS-009 [Priority: P1]: Cascade timeout closes the execution epoch
The system SHALL assign each cascade execution a unique execution epoch. When timeout,
client cancellation, or early success terminates the cascade, that epoch becomes closed.
Handlers, retry loops, ACT effects, EMIT, and trace flushes associated with a closed epoch
SHALL NOT publish new externally visible results. In-flight work MAY continue internally until
cooperative cancellation is observed, but any late completion after epoch closure SHALL be
discarded rather than persisted or returned.

#### Scenario: Late ACT completion is discarded after timeout
- **WHEN** cascade times out after P2 completes and an in-flight P3 ACT finishes later
- **THEN** the P3 completion does not execute external effects, does not flush a trace, and does not replace the timeout result

#### Scenario: Early confident result closes later potency attempts
- **WHEN** P1 returns a threshold-meeting Decision before P2 starts
- **THEN** the cascade epoch closes immediately after the P1 result is committed and no later potency attempt publishes a competing result

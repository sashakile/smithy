## Purpose
Define the cascade orchestration mechanism that tries potency levels in ascending order, returns the best sub-threshold Decision on exhaustion, and manages concurrent Fate updates with CAS semantics.

## Requirements

### Requirement: Cascade lives outside the pipeline
The system SHALL implement cascade as an orchestrator that calls the pipeline at successive
potency levels. Cascade SHALL NOT be a pipeline stage. Each pipeline invocation SHALL be
independently testable.

#### Scenario: Pipeline is invocable without cascade
- **WHEN** a single pipeline is invoked directly at a specific potency level
- **THEN** it executes RECEIVE→DECIDE→ACT→EMIT without cascade logic

### Requirement: Cascade tries potency levels in ascending order
The system SHALL try potency levels from lowest (P1) up to the component's base potency,
stopping when a Decision meets or exceeds the confidence threshold. Levels in the `:cascade :skip`
set SHALL be omitted.

#### Scenario: Cascade stops at first confident result
- **WHEN** P1 returns a Decision with confidence ≥ threshold
- **THEN** cascade returns that Decision and does not invoke P2, P3, or P4

#### Scenario: Cascade skips configured levels
- **WHEN** `:cascade {:skip #{:P2 :P3}}` is configured
- **THEN** cascade tries only P1 and P4, skipping P2 and P3

### Requirement: Cascade returns best sub-threshold Decision on exhaustion
The system SHALL return the highest-confidence Decision seen across all potency levels when
no level meets the threshold, rather than returning a Fault. A Fault SHALL only be returned
when all potency levels produce infrastructure faults.

#### Scenario: All levels below threshold returns best Decision
- **WHEN** P1 returns confidence 0.6 and P4 returns confidence 0.75, threshold is 0.80
- **THEN** cascade returns the P4 Decision (confidence 0.75), not a Fault

#### Scenario: All levels produce infrastructure faults returns Fault
- **WHEN** every potency level returns `{:fault ...}` due to infrastructure failure
- **THEN** cascade returns `{:fault {:origin :decide :kind :cascade/exhausted :retry? false}}`

### Requirement: Multiple expressions per potency level are all tried
The system SHALL store expressions as a vector per `[cell-id, potency]` pair. Cascade SHALL
try all expressions at a potency level before escalating to the next level.

#### Scenario: Multiple P1 expressions are all evaluated
- **WHEN** a cell has two P1 expressions (e.g., two Drools rule sets)
- **THEN** cascade invokes both and uses the one with the highest confidence

### Requirement: Cascade uses CAS for concurrent Fate updates
The system SHALL use compare-and-swap (CAS) semantics on `Fate.version` when updating potency
or threshold. Callers SHALL retry on version mismatch.

#### Scenario: Concurrent Fate update conflict is detected
- **WHEN** two callers attempt to update Fate simultaneously with the same expected version
- **THEN** one succeeds and one receives a version-mismatch error and retries

### Requirement: Cascade timeout is configurable
The system SHALL support a configurable `:cascade :timeout-ms` (default: 30000ms). If the
cascade exceeds this timeout, the highest-confidence result obtained so far SHALL be returned.

#### Scenario: Cascade timeout returns best result
- **WHEN** cascade timeout is reached while P3 is still executing
- **THEN** cascade returns the best Decision obtained from P1 and P2 without waiting for P3

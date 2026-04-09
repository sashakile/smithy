## Purpose
Define the four potency levels (P1–P4), their ordering, cost/latency characteristics, and the genome invariance constraint that governs differentiation and reprogramming.

## Requirements

### Requirement POT-001 [Priority: P1]: Four potency levels with total ordering
The system SHALL define exactly four potency levels — P1, P2, P3, P4 — with a total ordering
where P1 < P2 < P3 < P4. Every component SHALL have a current potency level at all times.

#### Scenario: Potency ordering is consistent
- **WHEN** two potency levels are compared
- **THEN** P1 < P2 < P3 < P4 is always true and `above`/`below`/`higher?` reflect this ordering

#### Scenario: Potency algebra is complete
- **WHEN** `above` is called on P4 or `below` is called on P1
- **THEN** the function returns nil (no level above P4 or below P1)

### Requirement POT-002 [Priority: P1]: Genome invariance across potency levels
The system SHALL maintain a component's genome (`:in` and `:out` schemas) unchanged across all
potency levels. Only the DECIDE implementation SHALL vary by potency.

#### Scenario: Genome unchanged after differentiation
- **WHEN** a component is differentiated from P4 to P1
- **THEN** the component's genome `:in` and `:out` schemas are identical before and after

#### Scenario: Genome unchanged after reprogramming
- **WHEN** a component is reprogrammed from P1 to P4
- **THEN** the component's genome `:in` and `:out` schemas are identical before and after

### Requirement POT-003 [Priority: P1]: Differentiation direction is P4 to P1
The system SHALL define differentiation as movement from higher potency (P4) to lower potency
(P1). Differentiation SHALL preserve genome compatibility while selecting an implementation with
lower expected cost and latency than the pre-differentiation potency, as evidenced by the
promotion thresholds defined in the planning and shadow workflow.

#### Scenario: Differentiation moves potency downward
- **WHEN** `mr differentiate` is called with `--to P1`
- **THEN** the component's potency in Fate is updated to P1 and the previous potency is archived

### Requirement POT-004 [Priority: P1]: Reprogramming direction is P1 to P4
The system SHALL define reprogramming as movement from lower potency (P1) to higher potency
(P4). Reprogramming SHALL restore access to a higher-flexibility implementation while accepting
higher expected cost and latency than the pre-reprogramming potency.

#### Scenario: Reprogramming moves potency upward
- **WHEN** `mr reprogram` is called with `--to P4`
- **THEN** the component's potency in Fate is updated to P4 and previous implementation is retained in standby

### Requirement POT-005 [Priority: P3]: Cost and latency are monotonically ordered by potency
The system SHALL document that P1 implementations have lower expected latency and cost than P4.
Reference values: P1 <1ms ~$0/call; P2 5–50ms ~$0.001/call; P3 200ms–2s ~$0.05/call;
P4 2–30s ~$0.50/call. These are illustrative order-of-magnitude targets, not hard SLAs.

#### Scenario: P1 is faster than P4
- **WHEN** the same input is processed at P1 and at P4
- **THEN** the documented expected latency range for P1 remains lower than the documented expected latency range for P4

## ADDED Requirements

### Requirement: TOPO-008 [Priority: P1]: Topology analysis requires baseline proof and compatible telemetry
The system SHALL treat topology adaptation as unavailable for a component lineage until baseline
proof has been established for that lineage according to the proposal workflow. Topology analysis
SHALL operate only on observations whose analytics-critical annotations were emitted by compatible,
registered producer contracts. Unknown producers, incompatible producer versions, or observations
lacking the required pairing metadata SHALL be excluded from candidate metrics. If the remaining
compatible observation set does not satisfy the minimum sample requirements for a signal, or if the
excluded observation share exceeds the configured exclusion cap, the analyzer SHALL fail closed and
SHALL NOT generate a split or fuse proposal. The analyzer SHALL publish a readiness report that
includes the compatible sample count, excluded sample count, exclusion percentage, and exclusion
reasons.

#### Scenario: Mixed telemetry blocks topology proposal generation
- **WHEN** the trailing observation window contains enough total traces but fewer than the required minimum from compatible producer contracts
- **THEN** the analyzer reports insufficient compatible telemetry and generates no topology proposal

#### Scenario: Baseline proof gates topology analysis
- **WHEN** topology adaptation is enabled for a component lineage without baseline proof
- **THEN** the analyzer skips proposal generation and records that topology readiness has not been achieved

#### Scenario: Topology readiness report shows exclusion breakdown
- **WHEN** topology analysis fails because unknown or incompatible producers push excluded observations above the configured cap
- **THEN** the analyzer records the compatible sample count, excluded sample count, exclusion percentage, and producer-specific exclusion reasons

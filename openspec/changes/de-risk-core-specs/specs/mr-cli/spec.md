## MODIFIED Requirements

### Requirement: CLI-004 [Priority: P1]: mr reprogram reverses a differentiation
The system SHALL reverse a differentiation via `mr reprogram <component> --to <potency>`.
`mr reprogram --emergency` SHALL bypass shadow validation, require `--approved-by <operator>`,
`--approval-reason <text>`, and `--incident-id <id>` at invocation time, and immediately
escalate to P4 after recording proposal approval metadata. Emergency approval metadata SHALL
include `approved-by`, `approved-at`, `approval-reason`, and `incident-id`, where `approved-at`
is captured from the system clock at execution time. All reprogram calls SHALL require a
`--reason` argument. The system SHALL reject a repeated emergency reprogram for the same
component lineage within the configured 14-day cooldown window unless an intervening human review
recorded `reviewed-by`, `reviewed-at`, `review-reason`, and `cleared-incident-id`, where
`reviewed-by` SHALL differ from the most recent emergency `approved-by`, has cleared the lineage
for another emergency action.

#### Scenario: Emergency reprogram bypasses shadow validation
- **WHEN** `mr reprogram --emergency` is called
- **THEN** the component immediately escalates to P4 without waiting for shadow validation, and the approval is recorded in the Proposal history

#### Scenario: Reprogram without reason is rejected
- **WHEN** `mr reprogram` is called without `--reason`
- **THEN** mr reprogram exits with an error requesting a reason

#### Scenario: Emergency reprogram without approval metadata is rejected
- **WHEN** `mr reprogram --emergency` is called without `--approved-by`, `--approval-reason`, or `--incident-id`
- **THEN** mr reprogram exits with an error requesting the missing approval metadata

#### Scenario: Emergency reprogram persists approval before potency mutation
- **WHEN** `mr reprogram --emergency` succeeds
- **THEN** the Proposal records `approved-by`, `approved-at`, `approval-reason`, and `incident-id` in the same atomic transition that commits the RegistryDiff updating Fate.potency

#### Scenario: Repeated emergency reprogram is blocked during cooldown
- **WHEN** a second `mr reprogram --emergency` is requested for the same component before the cooldown window expires and no intervening review has cleared the component
- **THEN** mr reprogram exits with a cooldown error and references the prior emergency action

#### Scenario: Repeated emergency reprogram requires independent reviewer
- **WHEN** a component lineage has an emergency action in the cooldown window and the same operator attempts to clear it for another emergency action
- **THEN** the CLI rejects the review record because the reviewer must differ from the most recent emergency approver

### Requirement: CLI-008 [Priority: P2]: mr exposes topology proposal commands
The system SHALL provide `mr split <component> --into <a> <b>` and
`mr fuse <a> <b> --as <merged>` to create topology proposals without directly mutating the
Registry. These commands SHALL perform topology readiness checks before proposal creation.
Readiness SHALL require baseline proof for the target lineage and sufficient compatible telemetry
for topology analysis. If readiness is not satisfied, the command SHALL fail without creating a
Proposal and SHALL report the unmet readiness conditions, including compatible sample count,
excluded sample count, exclusion percentage, and exclusion reasons when telemetry compatibility is
the blocking condition.

#### Scenario: Manual split creates a proposal
- **WHEN** `mr split ticket-router --into billing-router support-router` is run for a lineage that satisfies topology readiness
- **THEN** a split Proposal is created in `:draft` status under the topology-specific lifecycle

#### Scenario: Manual fuse creates a proposal
- **WHEN** `mr fuse intake classify --as intake-classify` is run for a lineage pair that satisfies topology readiness
- **THEN** a fuse Proposal is created in `:draft` status under the topology-specific lifecycle

#### Scenario: Topology command is blocked without readiness
- **WHEN** `mr split` or `mr fuse` is run for components that do not satisfy baseline proof or compatible-telemetry requirements
- **THEN** the command exits without creating a Proposal and reports the blocking readiness failures

#### Scenario: Topology command reports telemetry exclusion breakdown
- **WHEN** `mr split` or `mr fuse` is blocked because too much telemetry was excluded as unknown or incompatible
- **THEN** the command reports the compatible sample count, excluded sample count, exclusion percentage, and producer-specific exclusion reasons

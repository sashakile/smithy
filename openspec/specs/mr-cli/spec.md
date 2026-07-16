## Purpose
Define the mr CLI commands for planning, review, differentiation, reprogramming, shadowing,
topology operations, runtime inspection, initialization, and the output duality
(human-readable TTY vs machine-parseable JSON).

## Requirements

### Requirement CLI-001 [Priority: P1]: mr plan analyzes signaling history and proposes differentiation
The system SHALL analyze a component's signaling history via `mr plan <component>` and propose
a differentiation target. The plan SHALL include coverage rate, projected cost savings, and
generated artifacts (DRL rules, DMN tables, ONNX model spec). A minimum of 1,000 traces SHALL
be required before a plan is generated. A potency target SHALL be considered feasible only if it
meets the configured agreement threshold (default: ≥ 0.95 against the current potency on the
evaluation corpus) and projected daily savings > 0. Coverage SHALL be reported as an economic
input to the savings calculation, not a hard feasibility threshold. The default target selection
rule SHALL choose the lowest potency that satisfies the agreement and savings thresholds.

The coverage threshold MAY be configured via `:promotion :min-coverage` in smithy.edn (default: 0.0,
meaning no minimum). The agreement threshold MAY be configured via `:promotion :min-agreement`
(default: 0.95).

#### Scenario: Plan requires minimum trace count
- **WHEN** `mr plan` is run on a component with fewer than 1,000 traces
- **THEN** mr plan exits with an error indicating insufficient trace history

#### Scenario: Plan proposes lowest feasible potency based on agreement
- **WHEN** `mr plan` finds that P1 agreement is 0.97 and P2 agreement is 0.99
- **THEN** the proposal targets P1 because P1 exceeds the default agreement threshold and is the lowest potency

#### Scenario: Plan generates human-readable Drools artifacts
- **WHEN** `mr plan` targets a Drools P1 differentiation
- **THEN** DRL rules and/or DMN tables are generated in `.smithy/proposals/` in human-readable format

### Requirement CLI-002 [Priority: P1]: mr review advances or rejects pending proposals
The system SHALL support proposal review via `mr review <component>` for differentiation and
reprogramming proposals, and `mr review --topology <component-or-proposal>` for split and
fuse proposals. Review output SHALL include evidence summary, current status, proposal ID, and the
available actions (`approve`, `reject`). When more than one pending proposal exists for the target
component, `mr review <component>` SHALL fail with an ambiguity error that lists proposal IDs and
requires the operator to rerun the command with an explicit proposal ID.

#### Scenario: Review approves a pending differentiation proposal
- **WHEN** `mr review ticket-classifier --approve` is run on a proposal in `:reviewing`
- **THEN** the proposal status advances to `:approved`

#### Scenario: Topology review requires explicit mode
- **WHEN** a topology proposal is reviewed
- **THEN** `mr review --topology` loads the proposal and applies the topology-specific lifecycle rules without using a separate command family

#### Scenario: Ambiguous review target is rejected
- **WHEN** `mr review <component>` matches more than one pending proposal
- **THEN** the command exits with an ambiguity error and lists the matching proposal IDs

### Requirement CLI-003 [Priority: P1]: mr differentiate executes a validated differentiation
The system SHALL execute a differentiation via `mr differentiate <component> --to <potency>`
only after a shadow deployment meets the configured agreement threshold. Differentiation SHALL
update the component's Fate.potency in the Registry. Unless overridden in configuration,
the required shadow thresholds SHALL be agreement rate ≥ 0.95, no severity `:fatal`
regressions on the shadow corpus, and projected daily savings > 0.

#### Scenario: Differentiation requires shadow validation
- **WHEN** `mr differentiate` is called without a completed shadow deployment
- **THEN** mr differentiate exits with an error requesting shadow validation first

#### Scenario: Differentiation rejects insufficient agreement
- **WHEN** a completed shadow deployment reports agreement 0.93 against a required threshold of 0.95
- **THEN** `mr differentiate` exits with an error indicating the agreement threshold was not met

#### Scenario: Differentiation triggers automatic regression run
- **WHEN** `mr differentiate` completes successfully
- **THEN** DR automatically runs the most recent shadow dataset as a regression suite

### Requirement CLI-004 [Priority: P1]: mr reprogram reverses a differentiation
The system SHALL reverse a differentiation via `mr reprogram <component> --to <potency>`.
`mr reprogram --emergency` SHALL bypass shadow validation, require `--approved-by <operator>`
and `--approval-reason <text>` at invocation time, and immediately escalate to P4 after
recording proposal approval metadata. Emergency approval metadata SHALL include `approved-by`,
`approved-at`, and `approval-reason`, where `approved-at` is captured from the system clock at
execution time.
All reprogram calls SHALL require a `--reason` argument.

#### Scenario: Emergency reprogram bypasses shadow validation
- **WHEN** `mr reprogram --emergency` is called
- **THEN** the component immediately escalates to P4 without waiting for shadow validation, and the approval is recorded in the Proposal history

#### Scenario: Reprogram without reason is rejected
- **WHEN** `mr reprogram` is called without `--reason`
- **THEN** mr reprogram exits with an error requesting a reason

#### Scenario: Emergency reprogram without approval metadata is rejected
- **WHEN** `mr reprogram --emergency` is called without `--approved-by` or `--approval-reason`
- **THEN** mr reprogram exits with an error requesting the missing approval metadata

#### Scenario: Emergency reprogram persists approval before potency mutation
- **WHEN** `mr reprogram --emergency` succeeds
- **THEN** the Proposal records `approved-by`, `approved-at`, and `approval-reason` in the same atomic transition that commits the RegistryDiff updating Fate.potency

### Requirement CLI-005 [Priority: P1]: mr shadow runs parallel shadow deployment
The system SHALL support shadow deployment via `mr shadow <component> --from <p> --to <p>`.
Three strategies SHALL be supported: full (100% sample), sampled (default 10%), and
budget-capped (auto-calculated sample rate from `--budget`). The computed sample rate SHALL be
clamped to the range `(0, 1]`, and budget-capped planning SHALL report the estimated duration,
expected sample count, and 95% Wilson confidence interval for agreement.

#### Scenario: Default shadow uses 10% sample rate
- **WHEN** `mr shadow` is called without `--sample-rate` or `--budget`
- **THEN** 10% of live traffic is routed to both implementations

#### Scenario: Budget-capped shadow auto-calculates sample rate
- **WHEN** `mr shadow --budget $100` is called
- **THEN** DR calculates the sample rate and duration that fit within $100 and reports the achieved confidence interval

### Requirement CLI-006 [Priority: P2]: mr output is human-readable to TTY and machine-parseable when piped
The system SHALL output human-readable text when stdout is a TTY and machine-parseable
JSON/EDN when stdout is piped or when `--output json` is passed. `NO_COLOR` SHALL be respected.

#### Scenario: Piped output is machine-parseable
- **WHEN** `mr status | jq`
- **THEN** output is valid JSON

#### Scenario: NO_COLOR suppresses ANSI color codes
- **WHEN** `NO_COLOR=1 mr status`
- **THEN** output contains no ANSI escape sequences

### Requirement CLI-007 [Priority: P2]: mr exposes operational inspection commands
The system SHALL provide `mr status`, `mr metrics`, and `mr topology` for operational
inspection. These commands SHALL be read-only.

#### Scenario: mr status reports DR and shadow state
- **WHEN** `mr status` is run
- **THEN** it reports DR health, component states, and active shadow deployments

#### Scenario: mr metrics reports cost and latency aggregates
- **WHEN** `mr metrics` is run
- **THEN** it reports current cost, latency, and throughput metrics

### Requirement CLI-008 [Priority: P2]: mr exposes topology proposal commands
The system SHALL provide `mr split <component> --into <a> <b>` and
`mr fuse <a> <b> --as <merged>` to create topology proposals without directly mutating the
Registry.

#### Scenario: Manual split creates a proposal
- **WHEN** `mr split ticket-router --into billing-router support-router` is run
- **THEN** a split Proposal is created in `:draft` status under the topology-specific lifecycle

#### Scenario: Manual fuse creates a proposal
- **WHEN** `mr fuse intake classify --as intake-classify` is run
- **THEN** a fuse Proposal is created in `:draft` status under the topology-specific lifecycle

### Requirement CLI-009 [Priority: P2]: mr init initializes project structure
The system SHALL initialize the project via `mr init`, creating `smithy.edn` and the
`.smithy/` directory. `mr init` SHALL be idempotent.

#### Scenario: mr init creates smithy.edn
- **WHEN** `mr init` is run in an empty directory
- **THEN** smithy.edn is created with default configuration

#### Scenario: mr init is idempotent
- **WHEN** `mr init` is run in an already-initialized project
- **THEN** existing configuration is preserved and no error is thrown

## Purpose
Define the mr CLI commands: plan, differentiate, reprogram, shadow, init, and the output duality (human-readable TTY vs machine-parseable JSON).

## Requirements

### Requirement: mr plan analyzes signaling history and proposes differentiation
The system SHALL analyze a component's signaling history via `mr plan <component>` and propose
a differentiation target. The plan SHALL include coverage rate, projected cost savings, and
generated artifacts (DRL rules, DMN tables, ONNX model spec). A minimum of 1,000 traces SHALL
be required before a plan is generated.

#### Scenario: Plan requires minimum trace count
- **WHEN** `mr plan` is run on a component with fewer than 1,000 traces
- **THEN** mr plan exits with an error indicating insufficient trace history

#### Scenario: Plan proposes lowest feasible potency
- **WHEN** `mr plan` finds that P1 coverage is 73% and P2 coverage is 91%
- **THEN** the proposal targets P1 with P2 shown as an intermediate option

#### Scenario: Plan generates human-readable Drools artifacts
- **WHEN** `mr plan` targets a Drools P1 differentiation
- **THEN** DRL rules and/or DMN tables are generated in `.smithy/proposals/` in human-readable format

### Requirement: mr differentiate executes a validated differentiation
The system SHALL execute a differentiation via `mr differentiate <component> --to <potency>`
only after a shadow deployment meets the configured agreement threshold. Differentiation SHALL
update the component's Fate.potency in the Registry.

#### Scenario: Differentiation requires shadow validation
- **WHEN** `mr differentiate` is called without a completed shadow deployment
- **THEN** mr differentiate exits with an error requesting shadow validation first

#### Scenario: Differentiation triggers automatic regression run
- **WHEN** `mr differentiate` completes successfully
- **THEN** DR automatically runs the most recent shadow dataset as a regression suite

### Requirement: mr reprogram reverses a differentiation
The system SHALL reverse a differentiation via `mr reprogram <component> --to <potency>`.
`mr reprogram --emergency` SHALL bypass shadow validation and immediately escalate to P4.
All reprogram calls SHALL require a `--reason` argument.

#### Scenario: Emergency reprogram bypasses shadow validation
- **WHEN** `mr reprogram --emergency` is called
- **THEN** the component immediately escalates to P4 without waiting for shadow validation

#### Scenario: Reprogram without reason is rejected
- **WHEN** `mr reprogram` is called without `--reason`
- **THEN** mr reprogram exits with an error requesting a reason

### Requirement: mr shadow runs parallel shadow deployment
The system SHALL support shadow deployment via `mr shadow <component> --from <p> --to <p>`.
Three strategies SHALL be supported: full (100% sample), sampled (default 10%), and
budget-capped (auto-calculated sample rate from `--budget`).

#### Scenario: Default shadow uses 10% sample rate
- **WHEN** `mr shadow` is called without `--sample-rate` or `--budget`
- **THEN** 10% of live traffic is routed to both implementations

#### Scenario: Budget-capped shadow auto-calculates sample rate
- **WHEN** `mr shadow --budget $100` is called
- **THEN** DR calculates the sample rate and duration that fit within $100 and reports the achieved confidence interval

### Requirement: mr output is human-readable to TTY and machine-parseable when piped
The system SHALL output human-readable text when stdout is a TTY and machine-parseable
JSON/EDN when stdout is piped or when `--output json` is passed. `NO_COLOR` SHALL be respected.

#### Scenario: Piped output is machine-parseable
- **WHEN** `mr status | jq`
- **THEN** output is valid JSON

#### Scenario: NO_COLOR suppresses ANSI color codes
- **WHEN** `NO_COLOR=1 mr status`
- **THEN** output contains no ANSI escape sequences

### Requirement: mr init initializes project structure
The system SHALL initialize the project via `mr init`, creating `smithy.edn` and the
`.smithy/` directory. `mr init` SHALL be idempotent.

#### Scenario: mr init creates smithy.edn
- **WHEN** `mr init` is run in an empty directory
- **THEN** smithy.edn is created with default configuration

#### Scenario: mr init is idempotent
- **WHEN** `mr init` is run in an already-initialized project
- **THEN** existing configuration is preserved and no error is thrown

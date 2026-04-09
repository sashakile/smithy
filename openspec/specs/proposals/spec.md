## Purpose
Define the Proposal envelope, kind-specific proposal variants, and lifecycle rules that govern all Registry changes including differentiation, reprogramming, splits, and fuses.

## Requirements

### Requirement PROP-001 [Priority: P1]: All registry changes are represented as Proposals
The system SHALL represent all component lifecycle changes (differentiate, reprogram, split,
fuse) as Proposals containing a RegistryDiff and Evidence. No direct Registry mutation SHALL
occur outside the Proposal commit workflow.

#### Scenario: Differentiation creates a Proposal
- **WHEN** `mr differentiate` is executed
- **THEN** a Proposal with `:kind :differentiate` is created, shadow-validated, reviewed, and committed

#### Scenario: Reprogram creates a Proposal
- **WHEN** `mr reprogram` is executed
- **THEN** a Proposal with `:kind :reprogram` is created and committed through the proposal workflow (emergency skips `:shadowing` only)

### Requirement PROP-002 [Priority: P1]: Proposal is a tagged union with kind-specific lifecycle rules
The system SHALL model Proposal as a tagged union keyed by `:kind`. All Proposals SHALL share
the envelope fields required for auditability (`:kind`, `:status`, `RegistryDiff`, `Evidence`,
review metadata), but allowed statuses and transitions SHALL be validated per proposal kind
rather than by a single generic lifecycle.

#### Scenario: Proposal kind determines legal transitions
- **WHEN** a Proposal transition is evaluated
- **THEN** the system validates the transition against the lifecycle for that Proposal's `:kind`

### Requirement PROP-003 [Priority: P1]: Differentiation and standard reprogram proposals use the shadowed lifecycle
The system SHALL progress `:differentiate` and non-emergency `:reprogram` proposals through
`:draft` → `:shadowing` → `:reviewing` → `:approved` → `:committed`. Either kind MAY transition
from `:reviewing` to `:rejected`.

#### Scenario: Differentiation proposal cannot skip review
- **WHEN** a `:differentiate` Proposal is in `:draft` status
- **THEN** it cannot be committed until it passes through `:shadowing`, `:reviewing`, and `:approved`

#### Scenario: Rejected proposal is not committed
- **WHEN** a Proposal is rejected at review
- **THEN** its status is `:rejected` and no Registry mutations occur

### Requirement PROP-004 [Priority: P1]: Emergency reprogram proposals use the expedited lifecycle
The system SHALL progress `:reprogram` proposals created with `--emergency` through
`:draft` → `:reviewing` → `:approved` → `:committed`, skipping `:shadowing` while still
requiring review and approval metadata.

#### Scenario: Emergency reprogram skips shadowing but still records approval
- **WHEN** `mr reprogram --emergency` is executed by an authorized human operator
- **THEN** the Proposal bypasses `:shadowing`, records review and approval metadata, and commits without omitting the approval record

### Requirement PROP-005 [Priority: P1]: Topology proposals use the reviewable topology lifecycle
The system SHALL progress `:split` and `:fuse` proposals through a topology-specific lifecycle.
Manually created topology proposals SHALL start in `:draft`; analyzer-generated topology
proposals MAY start in `:reviewing`; both kinds SHALL require explicit approval before
transitioning to `:committed`.

#### Scenario: Manual split starts in draft
- **WHEN** `mr split` creates a topology proposal
- **THEN** the Proposal starts in `:draft` and later advances to `:reviewing` before approval

#### Scenario: Analyzer-generated split starts in reviewing
- **WHEN** the topology analyzer generates a split proposal
- **THEN** the Proposal enters `:reviewing` directly with its triggering evidence attached

### Requirement PROP-006 [Priority: P1]: Active proposals are unique per scope
The system SHALL prevent concurrent active Proposals with overlapping mutation scope. For
`:differentiate` and `:reprogram`, at most one Proposal whose status is in
`#{:draft :shadowing :reviewing :approved}` MAY exist per component. For `:split` and `:fuse`,
at most one active Proposal MAY exist per normalized topology target set. Creating a new Proposal
with an overlapping active scope SHALL fail with a conflict Fault rather than enqueueing a second
competing change.

#### Scenario: Second active differentiate proposal is rejected
- **WHEN** a component already has an active `:differentiate` Proposal
- **THEN** creating another active `:differentiate` or `:reprogram` Proposal for that component fails with a conflict Fault

#### Scenario: Topology proposals conflict on normalized target set
- **WHEN** an active `:fuse` Proposal exists for components A and B
- **THEN** creating another active topology Proposal for the normalized target set `{A B}` fails with a conflict Fault

### Requirement PROP-007 [Priority: P1]: Proposal transitions are linearizable
The system SHALL persist Proposal state with a monotonic version and validate transitions with
compare-and-swap semantics. Each transition SHALL observe the latest Proposal version, apply one
legal lifecycle edge, and commit atomically with any coupled RegistryDiff commit. Concurrent
transition attempts on the same Proposal SHALL result in exactly one successful transition; the
others SHALL fail with a version-mismatch error and re-read state.

#### Scenario: Concurrent approvals do not double-commit
- **WHEN** two reviewers try to approve the same Proposal version simultaneously
- **THEN** exactly one approval transition succeeds and at most one RegistryDiff commit occurs

### Requirement PROP-008 [Priority: P2]: Evidence captures quantitative justification
The system SHALL record Evidence with a Proposal including: traces analyzed, coverage rate,
agreement rate, shadow results (strategy, sample-rate, agreement, p-value, latency comparison,
cost comparison), and cost projection.

#### Scenario: Evidence includes shadow agreement rate
- **WHEN** a Proposal completes shadowing
- **THEN** Evidence.shadow.agreement is populated with the measured agreement rate between current and proposed potency

#### Scenario: Evidence includes cost projection
- **WHEN** a Proposal is generated by mr plan
- **THEN** Evidence.cost-projection includes current-daily, projected-daily, and savings-pct

### Requirement PROP-009 [Priority: P1]: RegistryDiff commit is atomic
The system SHALL commit a RegistryDiff atomically — all mutations succeed or none do.
This prevents partial state from being observable in the Registry.

#### Scenario: Atomic commit on in-memory Registry uses swap!
- **WHEN** `commit-diff!` is called on an in-memory Registry
- **THEN** a single `swap!` applies all RegistryDiff mutations atomically

#### Scenario: Atomic commit on PostgreSQL uses a transaction
- **WHEN** `commit-diff!` is called on a PostgreSQL-backed Registry
- **THEN** all mutations execute within a single database transaction with rollback on failure

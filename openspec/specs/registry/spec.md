## Purpose
Define the Registry's four-map data model, expression vector storage, atomic CAS Fate updates, and atomic RegistryDiff commits.

## Requirements

### Requirement: Registry stores four separate maps
The system SHALL store component data as four independent maps keyed by cell-id:
`cells` (identity), `fates` (runtime state), `expressions` (DECIDE implementations),
`wirings` (operational config). These SHALL never be merged into a single object.

#### Scenario: Registry resolves a component as four maps
- **WHEN** `resolve` is called with a cell-id
- **THEN** it returns `{:cell ... :fate ... :exprs [...] :wiring ...}` assembled on demand

### Requirement: Expressions stored as vectors per potency level
The system SHALL store expressions as `{[cell-id potency] -> [Expression]}` (vector, not scalar).
Multiple expressions at the same potency level SHALL coexist without collision.

#### Scenario: Two expressions at same potency coexist
- **WHEN** two expressions are registered for the same cell-id and potency level
- **THEN** both are stored and both are returned by resolve for that potency level

### Requirement: Fate updates are atomic with CAS
The system SHALL implement `update-fate!` with compare-and-swap semantics using `Fate.version`
as the CAS key. `Fate.version` SHALL be monotonically incremented on every successful update.

#### Scenario: CAS succeeds when version matches
- **WHEN** `update-fate!` is called with the correct expected version
- **THEN** the Fate is updated and version is incremented by 1

#### Scenario: CAS fails when version mismatches
- **WHEN** `update-fate!` is called with a stale expected version
- **THEN** the call throws and the caller retries with the current version

### Requirement: RegistryDiff commits are atomic
The system SHALL implement `commit-diff!` such that all mutations in a RegistryDiff either
all succeed or none do. Partial commits SHALL NOT occur.

#### Scenario: Full diff commits atomically
- **WHEN** a RegistryDiff contains fate updates, expression additions, and wiring updates
- **THEN** all mutations are applied atomically; no partial state is observable

#### Scenario: Failed diff leaves registry unchanged
- **WHEN** a RegistryDiff commit fails partway through
- **THEN** the registry is unchanged from its pre-commit state

### Requirement: Initial Fate potency is highest available Expression potency
The system SHALL set the initial Fate potency to the highest potency level for which an
Expression is registered when a cell is first registered via `register!`.

#### Scenario: New cell starts at highest registered potency
- **WHEN** a cell is registered with expressions at P1 and P4
- **THEN** initial Fate.potency is P4

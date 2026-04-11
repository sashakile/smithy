## MODIFIED Requirements

### Requirement: SIG-004 [Priority: P2]: Annotations extend signals via namespaced keys
The system SHALL extend signal metadata via namespaced keys in the Annotations open map.
New features SHALL add namespaced keys to Annotations rather than modifying Trace or Span schemas.
Any Annotation field used for planning, proposal evidence, or topology analysis SHALL be emitted
by a registered producer contract identified by immutable `:producer/id` and `:producer/version`
metadata plus a registry-declared `:producer/compatibility-group` value. Analytics that compare or
aggregate such fields SHALL treat observations as comparable only when their producer contracts are
explicitly compatible under the configured normalization policy and compatibility-group rules;
incompatible or unknown producer contracts SHALL be excluded from derived metrics and reported as
unusable evidence rather than silently co-mingled. Every derived metric used for planning,
evidence, or topology analysis SHALL report the included sample count, excluded sample count, and
exclusion reasons grouped by producer contract.

#### Scenario: Topology metadata stored in Annotations
- **WHEN** a component has been analyzed for topology adaptation
- **THEN** `:topology.cluster-id` and `:topology.reasoning-fingerprint` are present in Annotations.data together with the producing contract identity and version

#### Scenario: Incompatible producer contracts are excluded from analytics
- **WHEN** two traces contain `:topology.reasoning-fingerprint` values emitted by incompatible producer versions
- **THEN** topology and evidence analyzers exclude those traces from comparative metrics and report them as incompatible telemetry

#### Scenario: Compatibility is declared by registry group rather than version heuristics
- **WHEN** two producer versions differ but both are registered in the same compatibility group for an analytics-critical field
- **THEN** analytics may compare their observations according to the configured normalization policy

#### Scenario: Derived metrics expose exclusion breakdown
- **WHEN** evidence or topology analysis excludes traces due to unknown or incompatible producers
- **THEN** the resulting metric report includes the count of excluded traces and the exclusion reason for each producer contract

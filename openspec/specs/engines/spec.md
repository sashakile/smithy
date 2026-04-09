## Purpose
Define the IEngine protocol (init-engine + invoke), the shared stage result contract used by engine-backed DECIDE handlers, the five built-in engine implementations (:drools, :onnx, :llm, :lookup, :clojure), and genome-to-facts mapping for Drools.

## Requirements

### Requirement ENG-001 [Priority: P1]: IEngine protocol has exactly two methods
The system SHALL define the IEngine protocol with exactly two methods: `init-engine` and `invoke`.
`init-engine` SHALL be called once at registration; `invoke` SHALL be called on every request.

#### Scenario: Engine is initialized once at registration
- **WHEN** a new Expression is registered with an engine
- **THEN** `init-engine` is called exactly once and the opaque engine-state is stored

#### Scenario: Engine is invoked on every request
- **WHEN** cascade selects an expression at a potency level
- **THEN** `invoke` is called with the stored engine-state and the normalized input

### Requirement ENG-002 [Priority: P1]: invoke returns stage results, never bare Decisions
The system SHALL require that `invoke` implementations return `{:ok Decision}` on success.
When an implementation can classify an infrastructure failure precisely, it SHALL return
`{:fault ...}` or `{:escalate ...}` directly. When an implementation encounters an unclassified
runtime failure, it SHALL throw an exception, which middleware SHALL convert to `{:fault ...}`.
`invoke` SHALL NOT return a bare Decision.

#### Scenario: Engine exception is caught by middleware
- **WHEN** `invoke` throws an exception (e.g., Drools compilation error)
- **THEN** middleware catches it and produces `{:fault {:origin :decide :kind :runtime/exception ...}}`

### Requirement ENG-003 [Priority: P2]: Five built-in engines are provided
The system SHALL provide five built-in engine implementations: `:drools`, `:onnx`, `:llm`,
`:lookup`, `:clojure`.

#### Scenario: :drools engine fires DRL rules
- **WHEN** the `:drools` engine is invoked
- **THEN** it creates a stateless KIE session, inserts genome-mapped facts, fires rules, extracts a Decision, and returns `{:ok Decision}`

#### Scenario: :lookup engine returns full confidence on hit
- **WHEN** the `:lookup` engine finds the input key in the EDN table
- **THEN** it returns `{:ok {:value <match> :confidence 1.0}}`

#### Scenario: :lookup engine returns zero confidence on miss
- **WHEN** the `:lookup` engine does not find the input key in the EDN table
- **THEN** it returns `{:ok {:value nil :confidence 0.0}}`, allowing cascade to escalate on confidence policy rather than type adaptation

#### Scenario: :llm engine defaults confidence to 0.8 if absent
- **WHEN** the LLM response JSON does not include a confidence field
- **THEN** the `:llm` engine uses 0.8 as the default confidence value

#### Scenario: :clojure engine resolves and calls a var
- **WHEN** the `:clojure` engine is initialized with a qualified symbol
- **THEN** it resolves the var via `requiring-resolve` and calls `(f input ctx)` on each invocation, expecting a stage result map in return

### Requirement ENG-004 [Priority: P2]: genome->facts bridges Malli schemas to Drools facts
The system SHALL generate a `genome->facts` mapping at build time via `mr build-facts <cell-id>`
that converts Malli schema types to Java types for Drools working memory.

#### Scenario: Malli keyword enum maps to Java String
- **WHEN** the genome `:in` schema contains `[:enum :urgent :normal :low]`
- **THEN** `genome->facts` produces a String field in the generated Java fact class

#### Scenario: Malli optional field maps to @Nullable Java field
- **WHEN** the genome `:in` schema contains `[:optional string?]`
- **THEN** `genome->facts` produces a `@Nullable String` field

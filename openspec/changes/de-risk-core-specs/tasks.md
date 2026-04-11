## 1. Proposal And Evidence Gating

- [ ] 1.1 Update proposal evaluation to compute net savings after shadow, tracing, storage, and review overhead
- [ ] 1.2 Add baseline-proof evaluation for component lineages before topology proposals may be created or approved
- [ ] 1.3 Add validation coverage for proposal promotion and topology blocking when baseline proof is absent

## 2. Telemetry Provenance

- [ ] 2.1 Add registered producer identity and version fields for analytics-critical annotations in the signal model
- [ ] 2.2 Enforce compatible-producer filtering in planning and topology analyzers with explicit failure reporting
- [ ] 2.3 Add regression tests for mixed-version, unknown-producer, and insufficient-compatible-sample cases

## 3. Runtime Epoch Hardening

- [ ] 3.1 Implement explicit execution epoch states and state transitions in cascade control flow
- [ ] 3.2 Add idempotency-key enforcement for externally visible ACT effects and terminal publications
- [ ] 3.3 Add race-condition tests covering timeout, cancellation, early success, and late completion suppression

## 4. CLI Guardrails

- [ ] 4.1 Update `mr split` and `mr fuse` to report readiness blockers instead of creating proposals prematurely
- [ ] 4.2 Update `mr reprogram --emergency` to require incident metadata and enforce repeated-use cooldown rules
- [ ] 4.3 Add CLI integration tests for topology readiness failures and emergency cooldown behavior

## 5. Verification

- [ ] 5.1 Validate the OpenSpec change with `openspec validate de-risk-core-specs --strict`
- [ ] 5.2 Add or update law/property tests and scenario coverage mapped to the modified requirements

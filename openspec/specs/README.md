# Smithy Specification Index

Recommended reading order for new contributors. Each spec is self-contained
but builds on concepts from earlier specs.

| # | Spec | Description |
|---|---|---|
| 1 | [potency-model](potency-model/spec.md) | P1–P4 levels, differentiation, reprogramming |
| 2 | [pipeline](pipeline/spec.md) | RECEIVE → DECIDE → ACT → EMIT four-stage pipeline |
| 3 | [engines](engines/spec.md) | IEngine protocol and five built-in engines |
| 4 | [cascade](cascade/spec.md) | Escalation chain across potency levels |
| 5 | [registry](registry/spec.md) | Cell/Fate/Expression/Wiring storage and CAS updates |
| 6 | [signals](signals/spec.md) | Traces, spans, annotations, and ISignalStore |
| 7 | [middleware](middleware/spec.md) | Six-layer Ring interceptor stack |
| 8 | [proposals](proposals/spec.md) | Change lifecycle: draft → shadow → review → approve → commit |
| 9 | [mr-cli](mr-cli/spec.md) | CLI commands and workflows |
| 10 | [http-api](http-api/spec.md) | DR HTTP API resource model |
| 11 | [topology-adaptation](topology-adaptation/spec.md) | Autonomous split/fuse detection |

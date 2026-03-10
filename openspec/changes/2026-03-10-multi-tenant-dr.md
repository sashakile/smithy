# DQ-10: Multi-Tenant DR — Shared vs Isolated

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-10

## Problem

For SaaS deployments or internal platform teams serving multiple product lines, DR may need to
serve multiple tenants from a single instance. The isolation model determines how cell registries,
signaling histories, cost budgets, and thresholds are partitioned.

Options range from:
- **Fully isolated** — Separate DR process per tenant. Maximum isolation, maximum ops overhead.
- **Shared process, isolated data** — One DR process, tenant-scoped data partitioning.
- **Fully shared** — Single DR with tenant as a tag. Simple but risks cross-tenant data leakage
  and noisy-neighbor cost escalation.

## Proposal

**Shared process, isolated data. Tenant in Annotations. Row-level security in Postgres.
Budget per-tenant in Wiring.**

Implementation:
- Tenant ID carried in request header (`X-Smithy-Tenant`) or Wiring configuration
- All traces, spans, and annotations tagged with `:tenant-id` in Annotations data
- Postgres RLS (row-level security) enforces that queries return only the calling tenant's traces
- Per-tenant cost budgets configurable in Wiring (`:budget {:daily-dollars 50}`)
- Fate, Expression, Wiring stored with tenant key prefix: `[tenant-id cell-id]`
- Cells (genome definitions) may be shared across tenants (shared schema) or tenant-specific

Rationale: separate DR processes per tenant is operationally expensive and makes cross-tenant
analysis impossible. Shared process with strong data isolation at the storage layer is the
standard multi-tenant pattern for Postgres-backed services.

## Alternatives

1. **Fully isolated processes** — Zero risk of cross-tenant data leakage; full resource
   isolation. Operationally expensive; requires a process-per-tenant orchestration layer.
2. **Namespace-only isolation** — Tenant as key prefix, no RLS. Simpler but vulnerable to
   implementation bugs causing cross-tenant reads.
3. **Tenant as just a tag** — No isolation; all tenants share all data. Only appropriate for
   internal single-org deployments.

## Decision

Pending. Recommended: shared process, Postgres RLS isolation, per-tenant budget in Wiring.

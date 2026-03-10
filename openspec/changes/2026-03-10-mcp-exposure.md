# DQ-6: MCP Exposure — Auto or Opt-In

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-6

## Problem

Smithy can expose components as MCP tools (Section 5.3). When a component is registered in
DR, should it automatically become an MCP tool, or should this be an explicit opt-in?

Auto-exposure risks:
- Internal components not intended for external agent consumption get exposed
- Schema changes silently break downstream MCP clients
- No namespace isolation between internal and external-facing components

Opt-in risks:
- Operators forget to enable MCP on components that should be exposed
- No convention for which components are "MCP-eligible"

## Proposal

**Opt-in via `:mcp true` in Wiring.** Auto-generates tool schema from `Cell.genome.in`.

```edn
{:wirings
 {:ticket-classifier
  {:cell-id :ticket-classifier
   :mcp true}}}
```

When `:mcp true`:
- DR generates MCP tool descriptor from `Cell.genome.in` Malli schema
- Tool name = cell-id (kebab-case → snake_case for MCP compatibility)
- Tool description pulled from genome metadata (`:description` annotation on schema)
- Tool registered in MCP server's tool list; updated on next DR restart or hot-reload

## Alternatives

1. **Auto-expose all** — Simple operator experience, but exposes internal components and creates
   implicit MCP API surface.
2. **Separate MCP registry** — Operators explicitly register MCP tools in a separate config
   section, decoupled from cell wiring. More explicit but more config overhead.

## Decision

Pending. Recommended: opt-in via `:mcp true` in Wiring with auto-generated schema from genome.

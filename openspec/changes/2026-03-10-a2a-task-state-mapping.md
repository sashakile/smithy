# DQ-7: A2A Task State Mapping

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-7

## Problem

When Smithy participates in an A2A network (Section 5.4), a cascade call may take variable
time depending on which potency level handles it:
- P1 Drools: <1ms → synchronous response is trivially fine
- P4 multi-turn LLM: potentially minutes → A2A task model needs to express "still working"

A2A's task model has three relevant states:
- **synchronous** — immediate response
- **working** — task accepted, result coming asynchronously
- **input-required** — task needs additional information from the caller

The mapping from Smithy cascade behavior to these states is not defined.

## Proposal

**Cascade <5s = synchronous. Cascade >5s = A2A 'working'. P4 multi-turn = A2A 'input-required'.**

Detailed mapping:
- P1/P2 cascade (typically <100ms): synchronous response
- P3 cascade (200ms–2s): synchronous response (within typical HTTP timeout)
- P4 single-call cascade (2–30s, configurable): if >5s configured threshold → A2A 'working'
  state; DR holds task and pushes result when complete
- P4 multi-turn LLM (agent loops, tool use): A2A 'input-required' when LLM calls a tool that
  requires external input or human-in-the-loop

The 5s synchronous threshold should be configurable per component via Wiring.

## Alternatives

1. **Always synchronous** — Simplest integration; caller blocks. Works for P1/P2, times out for
   slow P4.
2. **Always async** — Every cascade goes through A2A task model. Unnecessary overhead for P1.
3. **Caller-configurable** — Caller specifies preferred response model in request options.
   Maximum flexibility, maximum complexity.

## Decision

Pending. Recommended: latency-threshold approach (5s default) with per-component Wiring override.

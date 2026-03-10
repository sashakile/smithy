# DQ-3: Shadow Disagreement Adjudication

**Status:** proposed
**Date:** 2026-03-10
**ID:** DQ-3

## Problem

During shadow deployment, when P1 and P4 disagree on a decision, which implementation is
treated as ground truth? How should disagreements be classified and acted upon?

Possible stances:
- P4 (LLM) is always right — P1 is approximating P4, so disagreement means P1 is wrong.
- Disagreement is ambiguous — both could be wrong, or P1 could be right and P4 wrong.
- Case-by-case human review — all disagreements are escalated.

The choice determines how `mr plan` treats coverage gaps and how the agreement threshold works.

## Proposal

**P4 is ground truth.** Flag disagreements for human review if agreement < 90%.

Rationale: P4 is the source implementation that P1 is derived from. The entire differentiation
workflow assumes P1 is a compression of P4's behavior. If P1 disagrees, the null hypothesis is
that P1 is wrong.

Exception: if domain experts review disagreements and find P4 was wrong (e.g. LLM hallucinated,
P1 rule was manually corrected), those traces can be annotated and excluded from the agreement
rate denominator.

## Alternatives

1. **Majority vote across multiple P4 calls** — More robust but 3× more expensive during shadow.
2. **Human review of ALL disagreements** — High confidence but not scalable at >1K traces/day.
3. **Statistical approach** — Treat high-confidence P1 disagreements with low-confidence P4 as
   ambiguous rather than P1-wrong.

## Decision

Pending. Recommended: P4 = ground truth; disagreements flagged for human review when agreement
rate drops below configurable threshold (default: 90%).

# OpenSpec

> **Agent instructions:** This file tells AI agents how to work with architectural
> change proposals in this repo. Human contributors: see CONTRIBUTING.md.

Architectural change proposals for smithy.

## What is OpenSpec?

OpenSpec is a lightweight system for tracking architectural decisions and change proposals.
Each proposal lives as a markdown file in `openspec/changes/`.

## Process

1. Create a proposal: `openspec/changes/YYYY-MM-DD-short-title.md`
2. Use the template below
3. Discuss in PR
4. Archive once deployed

## Template

```markdown
# Title

**Status:** proposed | accepted | rejected | deployed | archived
**Date:** YYYY-MM-DD

## Problem

What problem does this solve?

## Proposal

What is the proposed change?

## Alternatives

What alternatives were considered?

## Decision

Why was this approach chosen?
```

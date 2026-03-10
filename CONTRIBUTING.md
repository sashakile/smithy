# Contributing to smithy

## Workflow

This project uses [wai](https://github.com/charly-vibes/wai) for AI-driven development workflow.

### Getting started

```sh
wai prime        # Orient at session start
wai status       # Check project status
bd ready         # Find unblocked work
```

### Creating issues

```sh
bd create "Title" --type task --priority 2
```

### Proposing architectural changes

Create a file in `openspec/changes/` following the template in `openspec/AGENTS.md`.

### Committing

```sh
just lint        # Run pre-commit checks
```

Pre-commit hooks run automatically on `git commit`. Hooks are managed via beads
(`core.hooksPath=.beads/hooks`), which chains prek. If beads regenerates its
hooks (e.g. after `bd upgrade`), re-add prek to `.beads/hooks/pre-commit`.

### Common commands

```sh
just             # List all recipes
just doctor      # Check workspace health
just way         # Check repo best practices
just lint        # Run all pre-commit hooks
just issues      # List open issues
```

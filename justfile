# smithy justfile

# List available recipes
default:
    @just --list

# Check workspace health
doctor:
    wai doctor && bd doctor

# Check repo best practices
way:
    wai way

# Show project status
status:
    wai status && bd status

# Run pre-commit hooks on all files
lint:
    prek run --all-files

# List open issues
issues:
    bd ready

# Create an issue: just issue "my title"
issue title:
    bd create "{{title}}" --type task

# Show docs: just docs
docs:
    @echo "OpenSpec proposals: openspec/changes/"
    @ls openspec/changes/

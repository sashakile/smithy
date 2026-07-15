# smithy justfile

# ─── Basics ──────────────────────────────────────────────

# List available recipes
default:
    @just --list

# Show project status
status:
    @echo "=== wai status ==="
    wai status
    @echo ""
    @echo "=== bd status ==="
    bd status

# Check workspace health
doctor:
    @echo "=== wai doctor ==="
    wai doctor || true
    @echo ""
    @echo "=== bd doctor ==="
    bd doctor || true
    @echo ""
    @echo "=== dont doctor ==="
    dont doctor || true
    @echo ""
    @echo "=== espectacular doctor ==="
    espectacular doctor || true
    @echo ""
    @echo "=== pretender doctor ==="
    pretender doctor || true

# Check repo best practices
way:
    wai way

# ─── Git Hooks (lefthook) ──────────────────────────────

# Install lefthook git hooks
hooks-install:
    lefthook install

# Run pre-commit hooks on all staged files
hooks-pre-commit:
    lefthook run pre-commit

# Run pre-push hooks
hooks-pre-push:
    lefthook run pre-push

# Validate lefthook config
hooks-validate:
    lefthook validate

# Dump resolved lefthook config
hooks-dump:
    lefthook dump

# ─── Code Quality (pretender) ─────────────────────────

# Run pretender check (fast pass/fail)
pretender-check:
    @if ls *.clj *.cljs *.cljc *.java *.edn 2>/dev/null > /dev/null; then pretender check --threshold guidance .; else echo "(pretender: no code files found)"; fi

# Run pretender with detailed report (markdown)
pretender-report:
    pretender report --format markdown

# Show cyclomatic complexity
pretender-complexity:
    pretender complexity

# Run mutation tests
pretender-mutation:
    pretender mutation

# ─── Spec Verification (espectacular) ─────────────────

# Run all spec checks
espectacular-check:
    espectacular check

# Generate spec report
espectacular-report:
    espectacular report

# Check spec drift signals
espectacular-signals:
    espectacular signals

# ─── Test Selection (testaruda) ──────────────────────

# Select affected tests from current changes
testaruda-select:
    testaruda select --from git diff --name-only main

# Show dependency graph
testaruda-graph:
    testaruda graph

# Import dependency graph
testaruda-discover:
    testaruda discover

# Explain why a test was selected
testaruda-explain path:
    testaruda explain "{{path}}"

# ─── Epistemic Grounding (dont) ───────────────────────

# Check all claims are grounded
dont-check:
    dont check

# Show all claims and terms
dont-list:
    dont list

# Show project stats
dont-stats:
    dont stats

# Prime dont session
dont-prime:
    dont prime

# ─── Spec Integrity ───────────────────────────────────

# Verify openspec change proposals have valid statuses
spec-status:
    scripts/check-spec-status.sh

# Check for broken internal doc links
spec-links:
    scripts/check-doc-links.sh docs/*.md README.md

# ─── Lint & CI ────────────────────────────────────────

# Run all pre-commit checks (lefthook)
lint:
    lefthook run pre-commit

# Run all CI checks locally
ci:
    @echo "=== Repo hygiene ==="
    wai way --json
    @echo ""
    @echo "=== Spec consistency ==="
    scripts/check-spec-status.sh
    @echo ""
    @echo "=== Doc links ==="
    scripts/check-doc-links.sh docs/*.md README.md
    @echo ""
    @echo "=== don't check ==="
    dont check
    @echo ""
    @echo "=== espectacular check ==="
    espectacular check || echo "(espectacular: spec coverage — implement tests during development)"
    @echo ""
    @echo "=== pretender check ==="
    @if ls *.clj *.cljs *.cljc *.java *.edn 2>/dev/null > /dev/null; then pretender check --threshold guidance .; else echo "(pretender: no code to check yet — expected in spec phase)"; fi
    @echo ""
    @echo "=== All checks passed ==="

# ─── Issues & Workflow ────────────────────────────────

# List open issues
issues:
    bd ready

# Create an issue: just issue "my title"
issue title:
    bd create "{{title}}" --type task

# ─── Docs ──────────────────────────────────────────────

# Show doc index
docs:
    @echo "OpenSpec proposals: openspec/changes/"
    @ls openspec/changes/
    @echo ""
    @echo "Docs:"
    @ls docs/
    @echo ""
    @echo "Specs:"
    @ls openspec/specs/

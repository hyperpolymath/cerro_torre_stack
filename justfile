# SPDX-License-Identifier: PMPL-1.0-or-later
# Justfile for Cerro Torre Stack umbrella

# List available commands
default:
    @just --list

# Install dependencies for all apps
deps:
    mix deps.get

# Compile all apps
build:
    mix compile

# Clean build artifacts
clean:
    mix clean
    rm -rf _build deps

# Run all tests
test:
    mix test

# Run tests with coverage
test-coverage:
    mix test --cover

# Run tests for specific app
test-app APP:
    mix test --prefix {{APP}}

# Format all code
fmt:
    mix format

# Check code quality (format + dialyzer)
check:
    mix format --check-formatted
    mix dialyzer

# Start Svalinn in separate mode (default)
serve-separate:
    #!/usr/bin/env bash
    echo "Starting Svalinn in SEPARATE mode..."
    echo "Vörðr must be running separately on port 8080"
    export VORDR_ENDPOINT=http://localhost:8080
    mix phx.server --prefix svalinn

# Start entire stack in snapped mode (if Vörðr is in umbrella)
serve-snapped:
    #!/usr/bin/env bash
    echo "Starting full stack in SNAPPED mode..."
    if [ ! -d "apps/vordr" ]; then
        echo "ERROR: apps/vordr not found"
        echo "Add Vörðr to umbrella first:"
        echo "  ln -s ~/Documents/hyperpolymath-repos/vordr apps/vordr"
        exit 1
    fi
    mix phx.server

# Interactive console (separate mode)
console-separate:
    #!/usr/bin/env bash
    export VORDR_ENDPOINT=http://localhost:8080
    iex -S mix phx.server --prefix svalinn

# Interactive console (snapped mode)
console-snapped:
    iex -S mix phx.server

# Run test suite for snap-in architecture
test-integration:
    ./test_both_modes.sh

# Run health checks only
test-health:
    ./test_both_modes.sh --health-only

# Benchmark performance
bench:
    ./test_both_modes.sh --no-tests --iterations 1000

# Check deployment mode
mode:
    #!/usr/bin/env bash
    echo "Checking deployment mode..."
    curl -s http://localhost:8000/adapter | jq '.'

# Build production release (separate mode)
release-separate:
    MIX_ENV=prod mix release svalinn

# Build production release (snapped mode)
release-snapped:
    #!/usr/bin/env bash
    if [ ! -d "apps/vordr" ]; then
        echo "ERROR: apps/vordr not found for snapped release"
        exit 1
    fi
    MIX_ENV=prod mix release cerro_torre_stack

# Add Vörðr to umbrella (symlink)
add-vordr:
    #!/usr/bin/env bash
    if [ -d "apps/vordr" ]; then
        echo "Vörðr already exists in umbrella"
        exit 0
    fi
    echo "Creating symlink to Vörðr..."
    ln -s ~/Documents/hyperpolymath-repos/vordr apps/vordr
    echo "✓ Vörðr added to umbrella"
    echo "Run 'just build' to compile in snapped mode"

# Remove Vörðr from umbrella
remove-vordr:
    #!/usr/bin/env bash
    if [ -L "apps/vordr" ]; then
        echo "Removing Vörðr symlink..."
        rm apps/vordr
        echo "✓ Vörðr removed (back to separate mode)"
    elif [ -d "apps/vordr" ]; then
        echo "WARNING: apps/vordr is a directory, not a symlink"
        echo "Remove manually if needed"
        exit 1
    else
        echo "Vörðr not in umbrella"
    fi

# Show current configuration
info:
    #!/usr/bin/env bash
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  Cerro Torre Stack - Configuration                       ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Apps in umbrella:"
    ls -1 apps/
    echo ""
    if [ -d "apps/vordr" ]; then
        echo "Mode: SNAPPED (Vörðr in umbrella)"
    else
        echo "Mode: SEPARATE (Vörðr external)"
    fi
    echo ""
    echo "Elixir version:"
    elixir --version | head -2
    echo ""
    echo "Mix version:"
    mix --version

# Start Vörðr separately (for testing separate mode)
vordr-separate:
    #!/usr/bin/env bash
    echo "Starting Vörðr on port 8080..."
    cd ~/Documents/hyperpolymath-repos/vordr
    mix phx.server

# Full development setup
dev-setup:
    just deps
    just build
    @echo ""
    @echo "✓ Development setup complete"
    @echo ""
    @echo "Next steps:"
    @echo "  just serve-separate   # Start Svalinn (separate mode)"
    @echo "  just serve-snapped    # Start full stack (snapped mode)"
    @echo "  just test-integration # Run test suite"

# Reset to clean state
reset:
    just clean
    rm -f mix.lock
    just deps
    just build

# Generate documentation
docs:
    mix docs
    @echo "Documentation generated in doc/"

# Watch mode for development (auto-recompile)
watch:
    #!/usr/bin/env bash
    echo "Watching for changes..."
    fswatch -o apps/ | xargs -n1 -I{} mix compile

# Analyze dependencies
deps-tree:
    mix deps.tree

# Check for outdated dependencies
deps-outdated:
    mix hex.outdated

# Security audit
audit:
    mix deps.audit
    mix hex.audit

# Precommit checks (format + test + dialyzer)
precommit:
    just fmt
    just test
    just check

# CI simulation (what CI will run)
ci:
    just clean
    just deps
    just build
    just test-coverage
    just check

# Show logs from last run
logs APP="svalinn":
    tail -f _build/dev/lib/{{APP}}/priv/logs/*.log

# Database setup (if needed in future)
db-setup:
    @echo "No database configured yet"

# Generate new app in umbrella
new-app NAME:
    cd apps && mix new {{NAME}} --sup

# Profile performance
profile:
    #!/usr/bin/env bash
    echo "Profiling with fprof..."
    mix profile.fprof -e "Svalinn.VordrAdapter.list_containers()"

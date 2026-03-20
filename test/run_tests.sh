#!/bin/bash
# ccsm Test Runner
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BATS="$SCRIPT_DIR/bats/bin/bats"

if [ ! -x "$BATS" ]; then
    echo "Error: bats not found. Run: git submodule update --init --recursive"
    exit 1
fi

echo "Running ccsm tests..."
echo ""

if [ -n "$1" ]; then
    # Einzelne Testdatei
    "$BATS" --verbose-run "$SCRIPT_DIR/$1"
else
    # Alle Tests
    "$BATS" --verbose-run "$SCRIPT_DIR"/*.bats
fi

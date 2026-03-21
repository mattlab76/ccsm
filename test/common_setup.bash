#!/bin/bash
# Shared setup for all ccsm tests

CCSM_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

_common_setup() {
    # Load bats helpers
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # Enable test mode, force English for deterministic tests
    export CCSM_TESTING=true
    export CCSM_LANG=en
    export HOME="$BATS_TEST_TMPDIR"

    # Create required directories
    mkdir -p "$BATS_TEST_TMPDIR/.claude"
    mkdir -p "$BATS_TEST_TMPDIR/.local/bin"

    # Set paths used by ccsm
    export SESSION_LOG="$BATS_TEST_TMPDIR/.claude/session_log.tsv"
    export CONFIG_FILE="$BATS_TEST_TMPDIR/.claude/ccsm.conf"
    export CCSM_TMPDIR="$BATS_TEST_TMPDIR/tmp-ccsm"
    mkdir -p "$CCSM_TMPDIR"

    # Create empty session log
    touch "$SESSION_LOG"

    # Disable fzf for deterministic tests
    export HAS_FZF=false

    # Source ccsm to load all functions
    source "$CCSM_ROOT/ccsm"
}

# Helper: run a function via a fresh bash process with ccsm sourced
# This ensures associative arrays are available (bats' run loses them)
run_fn() {
    local fn_name="$1"
    shift
    # Pass arguments safely via positional parameters to avoid # and quote issues
    output=$(bash -c '
        export CCSM_TESTING=true CCSM_LANG=en HAS_FZF=false
        export HOME="'"$HOME"'" SESSION_LOG="'"$SESSION_LOG"'" CONFIG_FILE="'"$CONFIG_FILE"'" CCSM_TMPDIR="'"$CCSM_TMPDIR"'"
        source "'"$CCSM_ROOT"'/ccsm"
        '"$fn_name"' "$@"
    ' _ "$@" 2>&1) || true
    status=${PIPESTATUS[0]:-$?}
    IFS=$'\n' read -r -d '' -a lines <<< "$output" || true
}

# Helper: Create test session log with sample data
create_test_sessions() {
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "sid-001" "/home/test/project-a" "Erstes Projekt" "2026-01-15" "#infra" \
        > "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "sid-002" "/home/test/project-b" "Zweites Projekt" "2026-02-20" "#webapp" \
        >> "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "sid-003" "/home/test/project-a" "Drittes Projekt" "2026-03-01" "-" \
        >> "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "sid-004" "/home/test/project-c" "Viertes Projekt" "2026-03-18" "#bugfix #infra" \
        >> "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "sid-005" "/home/test/project-b" "Fuenftes Projekt" "2026-03-19" "-" \
        >> "$SESSION_LOG"
}

# Helper: Create a minimal JSONL transcript
create_test_transcript() {
    local path="$1"
    local message="${2:-Hallo, hilf mir beim Testen}"
    cat > "$path" <<JSONLEOF
{"type":"queue-operation","operation":"enqueue","timestamp":"2026-03-20T10:00:00.000Z","sessionId":"test-session"}
{"type":"queue-operation","operation":"dequeue","timestamp":"2026-03-20T10:00:00.001Z","sessionId":"test-session"}
{"parentUuid":null,"isSidechain":false,"userType":"external","cwd":"/tmp/test","sessionId":"test-session","version":"2.1.79","type":"user","message":{"role":"user","content":[{"type":"text","text":"${message}"}]}}
JSONLEOF
}

# Helper: Create hook input JSON
create_hook_input() {
    local sid="${1:-test-session-id}"
    local cwd="${2:-/tmp/test}"
    local transcript="${3:-}"
    echo "{\"session_id\":\"${sid}\",\"cwd\":\"${cwd}\",\"transcript_path\":\"${transcript}\",\"hook_event_name\":\"SessionEnd\",\"reason\":\"other\"}"
}

# Helper: Create temp session file (as hook would)
create_temp_session_file() {
    local sid="${1:-test-session-id}"
    local cwd="${2:-/tmp/test}"
    local betreff="${3:-Test Betreff}"
    local transcript="${4:-}"
    local tmpfile="$CCSM_TMPDIR/session-${sid}.json"
    cat > "$tmpfile" <<EOF
{"session_id":"${sid}","cwd":"${cwd}","betreff":"${betreff}","transcript":"${transcript}"}
EOF
    echo "$tmpfile"
}

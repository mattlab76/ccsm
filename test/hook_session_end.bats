#!/usr/bin/env bats
# Tests für den SessionEnd Hook

CCSM_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
HOOK_SCRIPT="$CCSM_ROOT/hooks/session_end.sh"

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    export TMPDIR="$BATS_TEST_TMPDIR/tmp-ccsm"
    mkdir -p "$TMPDIR"

    # Hook verwendet /tmp/ccsm hart — überschreiben via sed
    HOOK_PATCHED="$BATS_TEST_TMPDIR/session_end_patched.sh"
    sed "s|TMPDIR=\"/tmp/ccsm\"|TMPDIR=\"$TMPDIR\"|" "$HOOK_SCRIPT" > "$HOOK_PATCHED"
    chmod +x "$HOOK_PATCHED"
}

teardown() {
    rm -rf "$TMPDIR"
}

@test "hook: extrahiert session_id korrekt" {
    echo '{"session_id":"abc-123","cwd":"/tmp/test","transcript_path":""}' | bash "$HOOK_PATCHED"

    [ -f "$TMPDIR/session-abc-123.json" ]
    local sid
    sid=$(jq -r '.session_id' "$TMPDIR/session-abc-123.json")
    assert_equal "$sid" "abc-123"
}

@test "hook: extrahiert cwd korrekt" {
    echo '{"session_id":"test-cwd","cwd":"/home/user/project","transcript_path":""}' | bash "$HOOK_PATCHED"

    local cwd
    cwd=$(jq -r '.cwd' "$TMPDIR/session-test-cwd.json")
    assert_equal "$cwd" "/home/user/project"
}

@test "hook: beendet sich bei leerer session_id" {
    run bash -c 'echo "{\"session_id\":\"\",\"cwd\":\"/tmp\",\"transcript_path\":\"\"}" | bash '"$HOOK_PATCHED"
    assert_success
    # Keine Temp-Datei erstellt
    local count
    count=$(ls "$TMPDIR"/session-*.json 2>/dev/null | wc -l)
    assert_equal "$count" "0"
}

@test "hook: Dateiname enthält Session-ID" {
    echo '{"session_id":"unique-id-42","cwd":"/tmp","transcript_path":""}' | bash "$HOOK_PATCHED"

    [ -f "$TMPDIR/session-unique-id-42.json" ]
}

@test "hook: extrahiert Betreff aus Transcript" {
    local transcript="$BATS_TEST_TMPDIR/test_transcript.jsonl"
    cat > "$transcript" <<'JSONLEOF'
{"type":"queue-operation","operation":"enqueue","timestamp":"2026-03-20T10:00:00.000Z","sessionId":"t1"}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Hilf mir beim Docker Setup"}]}}
JSONLEOF

    echo "{\"session_id\":\"betreff-test\",\"cwd\":\"/tmp\",\"transcript_path\":\"$transcript\"}" | bash "$HOOK_PATCHED"

    local betreff
    betreff=$(jq -r '.betreff' "$TMPDIR/session-betreff-test.json")
    assert_equal "$betreff" "Hilf mir beim Docker Setup"
}

@test "hook: leeres Transcript ergibt leeren Betreff" {
    local transcript="$BATS_TEST_TMPDIR/empty.jsonl"
    echo "" > "$transcript"

    echo "{\"session_id\":\"empty-test\",\"cwd\":\"/tmp\",\"transcript_path\":\"$transcript\"}" | bash "$HOOK_PATCHED"

    local betreff
    betreff=$(jq -r '.betreff' "$TMPDIR/session-empty-test.json")
    assert_equal "$betreff" ""
}

@test "hook: Tabs im Betreff werden ersetzt" {
    local transcript="$BATS_TEST_TMPDIR/tab_transcript.jsonl"
    # Erstelle Transcript mit Tab im Text
    python3 -c "
import json
obj = {'type':'user','message':{'role':'user','content':[{'type':'text','text':'Text\tmit\tTabs'}]}}
print(json.dumps(obj))
" > "$transcript"

    echo "{\"session_id\":\"tab-test\",\"cwd\":\"/tmp\",\"transcript_path\":\"$transcript\"}" | bash "$HOOK_PATCHED"

    local betreff
    betreff=$(jq -r '.betreff' "$TMPDIR/session-tab-test.json")
    # Sollte keine Tabs enthalten
    [[ "$betreff" != *$'\t'* ]]
}

@test "hook: parallele Sessions erzeugen separate Dateien" {
    echo '{"session_id":"parallel-1","cwd":"/tmp/a","transcript_path":""}' | bash "$HOOK_PATCHED"
    echo '{"session_id":"parallel-2","cwd":"/tmp/b","transcript_path":""}' | bash "$HOOK_PATCHED"

    [ -f "$TMPDIR/session-parallel-1.json" ]
    [ -f "$TMPDIR/session-parallel-2.json" ]

    local cwd1 cwd2
    cwd1=$(jq -r '.cwd' "$TMPDIR/session-parallel-1.json")
    cwd2=$(jq -r '.cwd' "$TMPDIR/session-parallel-2.json")
    assert_equal "$cwd1" "/tmp/a"
    assert_equal "$cwd2" "/tmp/b"
}

@test "hook: Transcript-Pfad wird in JSON gespeichert" {
    echo '{"session_id":"path-test","cwd":"/tmp","transcript_path":"/home/user/.claude/transcript.jsonl"}' | bash "$HOOK_PATCHED"

    local transcript
    transcript=$(jq -r '.transcript' "$TMPDIR/session-path-test.json")
    assert_equal "$transcript" "/home/user/.claude/transcript.jsonl"
}

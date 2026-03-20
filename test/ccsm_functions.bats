#!/usr/bin/env bats
# Tests für reine Funktionen: days_since, setup_display, generate_suggestions

setup() {
    load 'common_setup'
    _common_setup
}

# --- days_since ---

@test "days_since: heutiges Datum ergibt 0" {
    local today
    today=$(date '+%Y-%m-%d')
    run days_since "$today"
    assert_success
    assert_output "0"
}

@test "days_since: gestriges Datum ergibt 1" {
    local yesterday
    yesterday=$(date -d "yesterday" '+%Y-%m-%d')
    run days_since "$yesterday"
    assert_success
    assert_output "1"
}

@test "days_since: Datum vor 30 Tagen ergibt 30" {
    local past
    past=$(date -d "30 days ago" '+%Y-%m-%d')
    run days_since "$past"
    assert_success
    assert_output "30"
}

@test "days_since: ungültiges Datum gibt Fehler" {
    run days_since "not-a-date"
    assert_failure
}

@test "days_since: leerer String ergibt 0 oder Fehler" {
    # Leerer String wird von date als 'heute' interpretiert oder schlägt fehl
    run days_since ""
    # Akzeptiere beides: Fehler ODER 0 (implementationsabhängig)
    if [ "$status" -eq 0 ]; then
        assert_output "0"
    else
        assert_failure
    fi
}

# --- setup_display ---

@test "setup_display: setzt HLINE auf korrekte Länge" {
    export COLUMNS=80
    setup_display
    local expected_len=$((INNER))
    local actual_len=${#HLINE}
    [ "$actual_len" -eq "$expected_len" ]
}

@test "setup_display: Mindestbreite 60" {
    export COLUMNS=30
    setup_display
    [ "$WIDTH" -ge 60 ]
}

@test "setup_display: INNER ist WIDTH-2" {
    setup_display
    [ "$INNER" -eq $((WIDTH - 2)) ]
}

# --- generate_suggestions ---

@test "generate_suggestions: extrahiert ersten User-Prompt" {
    local transcript="$BATS_TEST_TMPDIR/test.jsonl"
    create_test_transcript "$transcript" "Hilf mir beim Docker Setup"

    run generate_suggestions "$transcript" "/home/test/my-project"
    assert_success
    assert_line --index 0 "Hilf mir beim Docker Setup"
}

@test "generate_suggestions: generiert Verzeichnis-Vorschlag" {
    local transcript="$BATS_TEST_TMPDIR/test.jsonl"
    create_test_transcript "$transcript" "Etwas tun"

    run generate_suggestions "$transcript" "/home/test/my-project"
    assert_success
    assert_line --index 1 "Arbeit in: my-project"
}

@test "generate_suggestions: leeres Transcript ergibt keine User-Nachrichten" {
    local transcript="$BATS_TEST_TMPDIR/empty.jsonl"
    echo "" > "$transcript"

    run generate_suggestions "$transcript" "/tmp"
    assert_success
    # Kein User-Prompt, aber ggf. Verzeichnis-Vorschlag
    refute_output --partial "Hilf"
}

@test "generate_suggestions: mehrere User-Nachrichten erzeugen mehrere Vorschläge" {
    local transcript="$BATS_TEST_TMPDIR/multi.jsonl"
    cat > "$transcript" <<'JSONLEOF'
{"type":"queue-operation","operation":"enqueue","timestamp":"2026-03-20T10:00:00.000Z","sessionId":"t1"}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Erste Nachricht hier"}]}}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Zweite Nachricht hier"}]}}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Dritte Nachricht hier"}]}}
JSONLEOF

    run generate_suggestions "$transcript" "/home/test/projekt"
    assert_success
    # Mindestens 3 Vorschläge (erste Nachricht, Verzeichnis, zweite Nachricht)
    [ "${#lines[@]}" -ge 3 ]
}

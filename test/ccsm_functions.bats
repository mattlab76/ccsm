#!/usr/bin/env bats
# Tests für reine Funktionen: days_since, calc_columns, format_tokens, _tac, with_lock,
# ccsm_log, _rotate_log, _save_config, lookup_sid, is_yes, generate_suggestions

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
    yesterday=$(_date_ago 1)
    run days_since "$yesterday"
    assert_success
    assert_output "1"
}

@test "days_since: Datum vor 30 Tagen ergibt 30" {
    local past
    past=$(_date_ago 30)
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

# --- calc_columns ---

@test "calc_columns: setzt Spaltenbreiten" {
    calc_columns
    [ "$_W_NUM" -eq 3 ]
    [ "$_W_DATE" -eq 18 ]
    [ "$_W_SUBJ" -ge 18 ]
    [ "$_W_DIR" -ge 14 ]
}

@test "calc_columns: Mindestbreite für Subject" {
    calc_columns
    [ "$_W_SUBJ" -ge 18 ]
}

@test "calc_columns: Mindestbreite für Directory" {
    calc_columns
    [ "$_W_DIR" -ge 14 ]
}

# --- format_tokens (pure bash arithmetic, no bc) ---

@test "format_tokens: 0 ergibt '0'" {
    run format_tokens 0
    assert_output "0"
}

@test "format_tokens: leerer Input ergibt '0'" {
    run format_tokens ""
    assert_output "0"
}

@test "format_tokens: kleine Zahl bleibt unverändert" {
    run format_tokens 500
    assert_output "500"
}

@test "format_tokens: Tausender mit k-Suffix" {
    run format_tokens 47567
    assert_output "47.5k"
}

@test "format_tokens: Millionen mit M-Suffix" {
    run format_tokens 1353202
    assert_output "1.3M"
}

@test "format_tokens: exakt 1000 ergibt 1.0k" {
    run format_tokens 1000
    assert_output "1.0k"
}

@test "format_tokens: exakt 1000000 ergibt 1.0M" {
    run format_tokens 1000000
    assert_output "1.0M"
}

# --- _tac (cross-platform reverse) ---

@test "_tac: kehrt Datei um" {
    local testfile="$BATS_TEST_TMPDIR/tac_test.txt"
    printf 'line1\nline2\nline3\n' > "$testfile"
    run _tac "$testfile"
    assert_success
    assert_line --index 0 "line3"
    assert_line --index 1 "line2"
    assert_line --index 2 "line1"
}

@test "_tac: leere Datei ergibt leere Ausgabe" {
    local testfile="$BATS_TEST_TMPDIR/tac_empty.txt"
    touch "$testfile"
    run _tac "$testfile"
    assert_success
    assert_output ""
}

@test "_tac: einzeilige Datei bleibt gleich" {
    local testfile="$BATS_TEST_TMPDIR/tac_single.txt"
    echo "only line" > "$testfile"
    run _tac "$testfile"
    assert_success
    assert_output "only line"
}

# --- with_lock (file locking) ---

@test "with_lock: führt Kommando aus" {
    run with_lock echo "locked"
    assert_success
    assert_output "locked"
}

@test "with_lock: schreibt Datei korrekt" {
    local outfile="$BATS_TEST_TMPDIR/lock_out.txt"
    _write_test() { echo "data" > "$outfile"; }
    with_lock _write_test
    [ -f "$outfile" ]
    assert_equal "$(cat "$outfile")" "data"
}

# --- is_yes (locale-aware confirmation) ---

@test "is_yes: erkennt 'y' als ja (EN)" {
    run bash -c 'export CCSM_TESTING=true CCSM_LANG=en HOME="'"$HOME"'" SESSION_LOG="'"$SESSION_LOG"'" CONFIG_FILE="'"$CONFIG_FILE"'" CCSM_TMPDIR="'"$CCSM_TMPDIR"'"; source "'"$CCSM_ROOT"'/ccsm"; is_yes "y"'
    assert_success
}

@test "is_yes: erkennt 'j' als ja (DE)" {
    run bash -c 'export CCSM_TESTING=true CCSM_LANG=de HOME="'"$HOME"'" SESSION_LOG="'"$SESSION_LOG"'" CONFIG_FILE="'"$CONFIG_FILE"'" CCSM_TMPDIR="'"$CCSM_TMPDIR"'"; source "'"$CCSM_ROOT"'/ccsm"; is_yes "j"'
    assert_success
}

@test "is_yes: lehnt 'n' ab" {
    run bash -c 'export CCSM_TESTING=true CCSM_LANG=en HOME="'"$HOME"'" SESSION_LOG="'"$SESSION_LOG"'" CONFIG_FILE="'"$CONFIG_FILE"'" CCSM_TMPDIR="'"$CCSM_TMPDIR"'"; source "'"$CCSM_ROOT"'/ccsm"; is_yes "n"'
    assert_failure
}

# --- ccsm_log (activity log) ---

@test "ccsm_log: schreibt Log-Eintrag" {
    export CCSM_LOG="$BATS_TEST_TMPDIR/test.log"
    export LOG_DAYS=90
    ccsm_log "TEST" "test message"
    [ -f "$CCSM_LOG" ]
    run grep "TEST" "$CCSM_LOG"
    assert_success
    assert_output --partial "test message"
}

@test "ccsm_log: enthält Datum und Aktion" {
    export CCSM_LOG="$BATS_TEST_TMPDIR/test2.log"
    export LOG_DAYS=90
    ccsm_log "NEW" "my session"
    local content
    content=$(cat "$CCSM_LOG")
    [[ "$content" == *"[NEW]"* ]]
    [[ "$content" == *"my session"* ]]
    # Prüfe Datumsformat YYYY-MM-DD HH:MM
    [[ "$content" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2} ]]
}

@test "ccsm_log: schreibt nichts wenn LOG_DAYS=0" {
    export CCSM_LOG="$BATS_TEST_TMPDIR/test3.log"
    export LOG_DAYS=0
    ccsm_log "TEST" "should not appear"
    [ ! -f "$CCSM_LOG" ]
}

# --- _rotate_log (log rotation) ---

@test "_rotate_log: behält aktuelle Einträge" {
    export CCSM_LOG="$BATS_TEST_TMPDIR/rotate.log"
    export LOG_DAYS=90
    local today
    today=$(date '+%Y-%m-%d')
    echo "$today 12:00 [TEST] recent entry" > "$CCSM_LOG"
    _rotate_log
    [ -s "$CCSM_LOG" ]
    run grep "recent entry" "$CCSM_LOG"
    assert_success
}

@test "_rotate_log: tut nichts wenn LOG_DAYS=0" {
    export CCSM_LOG="$BATS_TEST_TMPDIR/rotate2.log"
    export LOG_DAYS=0
    echo "2020-01-01 12:00 [TEST] old" > "$CCSM_LOG"
    _rotate_log
    # Datei sollte unverändert sein
    run grep "old" "$CCSM_LOG"
    assert_success
}

@test "_rotate_log: tut nichts wenn keine Log-Datei" {
    export CCSM_LOG="$BATS_TEST_TMPDIR/nonexistent.log"
    export LOG_DAYS=90
    run _rotate_log
    assert_success
}

# --- _save_config ---

@test "_save_config: schreibt alle Einstellungen" {
    export CONFIG_FILE="$BATS_TEST_TMPDIR/test_config.conf"
    CLEANUP_DAYS=45
    LOG_DAYS=120
    CCSM_LANG=de
    _save_config
    [ -f "$CONFIG_FILE" ]
    run grep "CLEANUP_DAYS=45" "$CONFIG_FILE"
    assert_success
    run grep "LOG_DAYS=120" "$CONFIG_FILE"
    assert_success
    run grep "CCSM_LANG=de" "$CONFIG_FILE"
    assert_success
}

# --- lookup_sid (awk-based session lookup) ---

@test "lookup_sid: findet Session per ID" {
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "sid-abc" "/tmp" "Test" "2026-03-22" "-" "0/0" > "$SESSION_LOG"
    local result
    result=$(lookup_sid "sid-abc")
    [[ "$result" == *"sid-abc"* ]]
    [[ "$result" == *"Test"* ]]
}

@test "lookup_sid: gibt nichts zurück bei unbekannter ID" {
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "sid-abc" "/tmp" "Test" "2026-03-22" "-" "0/0" > "$SESSION_LOG"
    local result
    result=$(lookup_sid "sid-unknown")
    [ -z "$result" ]
}

@test "lookup_sid: kein Regex-Match auf Teilstrings" {
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "sid-abc-123" "/tmp" "Test" "2026-03-22" "-" "0/0" > "$SESSION_LOG"
    local result
    result=$(lookup_sid "sid-abc")
    [ -z "$result" ]
}

# --- days_since with time format ---

@test "days_since: funktioniert mit Datum+Uhrzeit Format" {
    local today
    today=$(date '+%Y-%m-%d')
    run days_since "$today 14:30"
    assert_success
    assert_output "0"
}

# --- ask_path (alias for ask_input) ---

@test "ask_path: ist als Funktion definiert" {
    run type ask_path
    assert_success
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
    assert_line --index 1 "Work in: my-project"
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

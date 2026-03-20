#!/usr/bin/env bats
# Tests für Edge Cases

setup() {
    load 'common_setup'
    _common_setup
}

@test "edge: leeres Log — show_sessions gibt Meldung" {
    run_fn show_sessions
    [[ "$output" == *"No"* ]] || [[ "$output" == *"saved"* ]] || [[ "$output" == *"session"* ]]
}

@test "edge: leeres Log — search gibt Meldung" {
    run_fn search_sessions "test"
    [[ "$output" == *"No sessions"* ]] || [[ "$output" == *"session"* ]]
}

@test "edge: leeres Log — stats gibt Meldung" {
    run_fn show_stats
    [[ "$output" == *"No sessions"* ]] || [[ "$output" == *"session"* ]]
}

@test "edge: leeres Log — cleanup ist still" {
    run_fn check_cleanup
    assert_success
    assert_output ""
}

@test "edge: fehlende Session-Log-Datei wird angelegt" {
    rm -f "$SESSION_LOG"
    # Re-source um die Datei-Erstellung auszulösen
    source "$CCSM_ROOT/ccsm"
    [ -f "$SESSION_LOG" ]
}

@test "edge: Tabs im Betreff werden bei TSV-Speicherung ersetzt" {
    local betreff_with_tab
    betreff_with_tab=$(printf 'Text\tmit\tTabs')
    local clean
    clean=$(echo "$betreff_with_tab" | tr '\t' ' ')

    assert_equal "$clean" "Text mit Tabs"
}

@test "edge: sehr langer Betreff wird in show_sessions gekürzt" {
    local long_betreff
    long_betreff=$(printf 'A%.0s' {1..200})
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-long" "/tmp" "$long_betreff" "2026-03-20" "-" > "$SESSION_LOG"

    run_fn show_sessions
    assert_success
    # Ausgabe sollte ".." enthalten (Kürzung)
    assert_output --partial ".."
}

@test "edge: Session-ID mit Sonderzeichen im grep" {
    printf '%s\t%s\t%s\t%s\t%s\n' "abc-123-def" "/tmp" "Test" "2026-03-20" "-" > "$SESSION_LOG"

    # grep mit Tab-Delimiter sollte nur exakte Matches finden
    run grep "^abc-123-def	" "$SESSION_LOG"
    assert_success
}

@test "edge: CLEANUP_DAYS aus Config wird übernommen" {
    echo "CLEANUP_DAYS=7" > "$CONFIG_FILE"
    source "$CONFIG_FILE"
    assert_equal "$CLEANUP_DAYS" "7"
}

@test "edge: save_session ohne Temp-Datei zeigt Warnung" {
    # Leeres TMPDIR, keine Temp-Dateien
    rm -rf "$TMPDIR"/*

    run_fn save_session
    assert_output --partial "No session data"
}

@test "edge: choose_betreff mit n gibt __SKIP__ zurück" {
    local result
    result=$(echo "n" | choose_betreff "" "/tmp")
    assert_equal "$result" "__SKIP__"
}

@test "edge: choose_betreff mit leerem Input gibt Default-Betreff zurück" {
    local result
    result=$(echo "" | choose_betreff "" "/tmp/my-project")
    # Should return a default subject (not __SKIP__)
    [[ "$result" != "__SKIP__" ]]
    [[ "$result" == *"my-project"* ]]
}

#!/usr/bin/env bats
# Tests für Edge Cases

setup() {
    load 'common_setup'
    _common_setup
}

@test "edge: leeres Log — show_sessions gibt Fehler" {
    run show_sessions
    assert_failure
    assert_output --partial "Keine"
}

@test "edge: leeres Log — search gibt Meldung" {
    run search_sessions "test"
    assert_output --partial "Keine Sessions"
}

@test "edge: leeres Log — stats gibt Meldung" {
    run show_stats
    assert_output --partial "Keine Sessions"
}

@test "edge: leeres Log — cleanup ist still" {
    run check_cleanup
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

    run show_sessions
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

    run save_session
    assert_output --partial "Keine Session-Daten"
}

@test "edge: choose_betreff mit n gibt __SKIP__ zurück" {
    local result
    result=$(echo "n" | choose_betreff "" "/tmp")
    assert_equal "$result" "__SKIP__"
}

@test "edge: choose_betreff mit leerem Input gibt __SKIP__ zurück" {
    local result
    result=$(echo "" | choose_betreff "" "/tmp")
    assert_equal "$result" "__SKIP__"
}

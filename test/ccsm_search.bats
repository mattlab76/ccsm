#!/usr/bin/env bats
# Tests für Suchfunktionalität

setup() {
    load 'common_setup'
    _common_setup
    export HAS_FZF=false
}

@test "search: findet Session nach Betreff" {
    create_test_sessions
    run_fn search_sessions "Zweites"
    assert_success
    assert_output --partial "Zweites Projekt"
}

@test "search: findet Session nach Verzeichnispfad" {
    create_test_sessions
    run_fn search_sessions "project-c"
    assert_success
    assert_output --partial "Viertes Projekt"
}

@test "search: findet Session nach Tag" {
    create_test_sessions
    run_fn search_sessions "#webapp"
    assert_success
    assert_output --partial "Zweites Projekt"
}

@test "search: kein Treffer zeigt Meldung" {
    create_test_sessions
    run_fn search_sessions "gibtsnicht"
    assert_output --partial "No matches"
}

@test "search: leeres Log zeigt Meldung" {
    run_fn search_sessions "test"
    [[ "$output" == *"No sessions"* ]] || [[ "$output" == *"session"* ]]
}

@test "search: ist case-insensitiv" {
    create_test_sessions
    run_fn search_sessions "ERSTES"
    assert_success
    assert_output --partial "Erstes Projekt"
}

@test "search: Trefferzähler ist korrekt" {
    create_test_sessions
    # #infra kommt in sid-001 und sid-004 vor
    run_fn search_sessions "#infra"
    assert_success
    assert_output --partial "2 match"
}

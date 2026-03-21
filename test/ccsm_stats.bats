#!/usr/bin/env bats
# Tests für Statistiken

setup() {
    load 'common_setup'
    _common_setup
}

@test "stats: leeres Log zeigt Meldung" {
    run_fn show_stats
    assert_output --partial "No sessions"
}

@test "stats: zeigt korrekte Gesamtanzahl" {
    create_test_sessions
    run_fn show_stats
    assert_success
    assert_output --partial "5 session(s)"
}

@test "stats: zeigt älteste Session" {
    create_test_sessions
    run_fn show_stats
    assert_success
    assert_output --partial "2026-01-15"
}

@test "stats: zeigt neueste Session" {
    create_test_sessions
    run_fn show_stats
    assert_success
    assert_output --partial "2026-03-19"
}

@test "stats: zeigt Top-Verzeichnisse" {
    create_test_sessions
    run_fn show_stats
    assert_success
    # project-a und project-b haben je 2 Sessions
    assert_output --partial "2x"
}

@test "stats: zeigt Top-Tags" {
    create_test_sessions
    run_fn show_stats
    assert_success
    assert_output --partial "#infra"
}

@test "stats: zeigt Version" {
    create_test_sessions
    run_fn show_stats
    assert_success
    assert_output --partial "$CCSM_VERSION"
}

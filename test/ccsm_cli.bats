#!/usr/bin/env bats
# Tests für CLI Argument Parsing

setup() {
    load 'common_setup'
    _common_setup
}

@test "CLI: --version gibt Version aus" {
    run_fn main --version
    assert_success
    assert_output "ccsm v${CCSM_VERSION}"
}

@test "CLI: -v gibt Version aus" {
    run_fn main -v
    assert_success
    assert_output "ccsm v${CCSM_VERSION}"
}

@test "CLI: --help gibt Nutzungshinweise aus" {
    run_fn main --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "--search"
    assert_output --partial "--stats"
}

@test "CLI: -h gibt Nutzungshinweise aus" {
    run_fn main -h
    assert_success
    assert_output --partial "Usage:"
}

@test "CLI: --stats bei leerem Log" {
    run_fn main --stats
    assert_success
    assert_output --partial "No sessions"
}

@test "CLI: --stats zeigt Statistiken" {
    create_test_sessions
    run_fn main --stats
    assert_success
    assert_output --partial "Total:"
    assert_output --partial "5 Sessions"
}

@test "CLI: --search ohne Treffer" {
    create_test_sessions
    run_fn main --search "nichtvorhanden"
    assert_output --partial "No matches"
}

@test "CLI: --search findet Session" {
    create_test_sessions
    run_fn main --search "Erstes"
    assert_success
    assert_output --partial "Erstes Projekt"
}

@test "CLI: --cleanup bei leerem Log" {
    run_fn main --cleanup
    assert_success
    assert_output ""
}

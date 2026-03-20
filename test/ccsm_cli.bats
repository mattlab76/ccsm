#!/usr/bin/env bats
# Tests für CLI Argument Parsing

setup() {
    load 'common_setup'
    _common_setup
}

@test "CLI: --version gibt Version aus" {
    run main --version
    assert_success
    assert_output "ccsm v${CCSM_VERSION}"
}

@test "CLI: -v gibt Version aus" {
    run main -v
    assert_success
    assert_output "ccsm v${CCSM_VERSION}"
}

@test "CLI: --help gibt Nutzungshinweise aus" {
    run main --help
    assert_success
    assert_output --partial "Nutzung:"
    assert_output --partial "--search"
    assert_output --partial "--stats"
}

@test "CLI: -h gibt Nutzungshinweise aus" {
    run main -h
    assert_success
    assert_output --partial "Nutzung:"
}

@test "CLI: --stats bei leerem Log" {
    run main --stats
    assert_success
    assert_output --partial "Keine Sessions"
}

@test "CLI: --stats zeigt Statistiken" {
    create_test_sessions
    run main --stats
    assert_success
    assert_output --partial "Gesamt:"
    assert_output --partial "5 Sessions"
}

@test "CLI: --search ohne Treffer" {
    create_test_sessions
    run main --search "nichtvorhanden"
    assert_output --partial "Keine Treffer"
}

@test "CLI: --search findet Session" {
    create_test_sessions
    run main --search "Erstes"
    assert_success
    assert_output --partial "Erstes Projekt"
}

@test "CLI: --cleanup bei leerem Log" {
    run main --cleanup
    assert_success
    assert_output ""
}

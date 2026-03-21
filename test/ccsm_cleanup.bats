#!/usr/bin/env bats
# Tests für Cleanup-Logik

setup() {
    load 'common_setup'
    _common_setup
    export CLEANUP_DAYS=30
}

@test "cleanup: kehrt sofort zurück bei leerem Log" {
    run_fn check_cleanup
    assert_success
    assert_output ""
}

@test "cleanup: kehrt sofort zurück wenn CLEANUP_DAYS=0" {
    create_test_sessions
    # Config mit CLEANUP_DAYS=0 schreiben
    echo "CLEANUP_DAYS=0" > "$CONFIG_FILE"
    run_fn check_cleanup
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cleanup: erkennt alte Sessions" {
    local old_date
    old_date=$(_date_ago 60)
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte Session" "$old_date" "-" > "$SESSION_LOG"

    output=$(echo "" | bash -c '
        export CCSM_TESTING=true CCSM_LANG=en HAS_FZF=false
        export HOME="'"$HOME"'" SESSION_LOG="'"$SESSION_LOG"'" CONFIG_FILE="'"$CONFIG_FILE"'" CCSM_TMPDIR="'"$CCSM_TMPDIR"'"
        source "'"$CCSM_ROOT"'/ccsm"
        check_cleanup
    ' 2>&1)
    echo "$output" | grep -q "Alte Session"
}

@test "cleanup: ignoriert junge Sessions" {
    local recent_date
    recent_date=$(date '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-new" "/tmp" "New Session" "$recent_date" "-" > "$SESSION_LOG"

    run_fn check_cleanup
    assert_success
    refute_output --partial "Old sessions"
}

@test "cleanup: Löschen entfernt Session aus Log" {
    local old_date
    old_date=$(_date_ago 60)
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte Session" "$old_date" "-" > "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-new" "/tmp" "New Session" "2026-03-20" "-" >> "$SESSION_LOG"

    # "1" = first old session number
    echo "1" | check_cleanup

    local count
    count=$(_count_lines "$SESSION_LOG")
    assert_equal "$count" "1"
    run grep "sid-old" "$SESSION_LOG"
    assert_failure
    run grep "sid-new" "$SESSION_LOG"
    assert_success
}

@test "cleanup: Behalten lässt Session unverändert" {
    local old_date
    old_date=$(_date_ago 60)
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte Session" "$old_date" "-" > "$SESSION_LOG"

    # Enter = behalten
    echo "" | check_cleanup

    local count
    count=$(_count_lines "$SESSION_LOG")
    assert_equal "$count" "1"
}

@test "cleanup: gemischt alt/neu — nur alte angeboten" {
    local old_date recent_date
    old_date=$(_date_ago 60)
    recent_date=$(date '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte" "$old_date" "-" > "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-new" "/tmp" "Neue" "$recent_date" "-" >> "$SESSION_LOG"

    # Behalten (Enter)
    output=$(echo "" | check_cleanup 2>&1)
    echo "$output" | grep -q "Alte"
    # "Neue" sollte nicht in der Cleanup-Ausgabe erscheinen
    ! echo "$output" | grep -q "New Session"
}

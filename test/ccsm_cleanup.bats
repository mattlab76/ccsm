#!/usr/bin/env bats
# Tests für Cleanup-Logik

setup() {
    load 'common_setup'
    _common_setup
    export CLEANUP_DAYS=30
}

@test "cleanup: kehrt sofort zurück bei leerem Log" {
    run check_cleanup
    assert_success
    assert_output ""
}

@test "cleanup: kehrt sofort zurück wenn CLEANUP_DAYS=0" {
    create_test_sessions
    CLEANUP_DAYS=0
    run check_cleanup
    assert_success
    assert_output ""
}

@test "cleanup: erkennt alte Sessions" {
    local old_date
    old_date=$(date -d "60 days ago" '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte Session" "$old_date" "-" > "$SESSION_LOG"

    # Enter = behalten
    output=$(echo "" | check_cleanup 2>&1)
    echo "$output" | grep -q "Alte Sessions gefunden"
}

@test "cleanup: ignoriert junge Sessions" {
    local recent_date
    recent_date=$(date '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-new" "/tmp" "Neue Session" "$recent_date" "-" > "$SESSION_LOG"

    run check_cleanup
    assert_success
    refute_output --partial "Alte Sessions"
}

@test "cleanup: Löschen entfernt Session aus Log" {
    local old_date
    old_date=$(date -d "60 days ago" '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte Session" "$old_date" "-" > "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-new" "/tmp" "Neue Session" "2026-03-20" "-" >> "$SESSION_LOG"

    # 'd' = löschen
    echo "d" | check_cleanup

    local count
    count=$(wc -l < "$SESSION_LOG")
    assert_equal "$count" "1"
    run grep "sid-old" "$SESSION_LOG"
    assert_failure
    run grep "sid-new" "$SESSION_LOG"
    assert_success
}

@test "cleanup: Behalten lässt Session unverändert" {
    local old_date
    old_date=$(date -d "60 days ago" '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte Session" "$old_date" "-" > "$SESSION_LOG"

    # Enter = behalten
    echo "" | check_cleanup

    local count
    count=$(wc -l < "$SESSION_LOG")
    assert_equal "$count" "1"
}

@test "cleanup: gemischt alt/neu — nur alte angeboten" {
    local old_date recent_date
    old_date=$(date -d "60 days ago" '+%Y-%m-%d')
    recent_date=$(date '+%Y-%m-%d')
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-old" "/tmp" "Alte" "$old_date" "-" > "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-new" "/tmp" "Neue" "$recent_date" "-" >> "$SESSION_LOG"

    # Behalten (Enter)
    output=$(echo "" | check_cleanup 2>&1)
    echo "$output" | grep -q "Alte"
    # "Neue" sollte nicht in der Cleanup-Ausgabe erscheinen
    ! echo "$output" | grep -q "Neue Session"
}

#!/usr/bin/env bats
# Tests für TSV Session Log Operationen

setup() {
    load 'common_setup'
    _common_setup
}

# --- Session-Log Format ---

@test "TSV: neue Session hat 5 Tab-separierte Felder" {
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-test" "/tmp/test" "Test Betreff" "2026-03-20" "#test" >> "$SESSION_LOG"

    local fields
    fields=$(awk -F'\t' '{print NF}' "$SESSION_LOG")
    assert_equal "$fields" "5"
}

@test "TSV: Felder sind korrekt positioniert" {
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-abc" "/home/test" "Mein Betreff" "2026-03-20" "#infra" >> "$SESSION_LOG"

    local sid cwd betreff datum tags
    IFS=$'\t' read -r sid cwd betreff datum tags < "$SESSION_LOG"
    assert_equal "$sid" "sid-abc"
    assert_equal "$cwd" "/home/test"
    assert_equal "$betreff" "Mein Betreff"
    assert_equal "$datum" "2026-03-20"
    assert_equal "$tags" "#infra"
}

@test "TSV: mehrere Sessions werden korrekt angehängt" {
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-1" "/tmp/a" "Erste" "2026-03-18" "-" >> "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-2" "/tmp/b" "Zweite" "2026-03-19" "-" >> "$SESSION_LOG"
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-3" "/tmp/c" "Dritte" "2026-03-20" "-" >> "$SESSION_LOG"

    local count
    count=$(_count_lines "$SESSION_LOG")
    assert_equal "$count" "3"
}

# --- show_sessions ---

@test "build_table: leeres Log erzeugt keine Zeilen" {
    build_table 0
    [ "${#TABLE_LINES[@]}" -eq 0 ]
}

@test "build_table: zeigt Sessions an" {
    create_test_sessions
    build_table 0
    local table_output
    table_output=$(printf '%s\n' "${TABLE_LINES[@]}")
    [[ "$table_output" == *"Erstes"* ]]
    [[ "$table_output" == *"Fuenftes"* ]]
}

@test "build_table: Sessions in umgekehrter Reihenfolge" {
    create_test_sessions
    build_table 0
    local table_output
    table_output=$(printf '%s\n' "${TABLE_LINES[@]}")
    local pos_fuenftes pos_erstes
    pos_fuenftes=$(echo "$table_output" | grep -n "Fuenftes" | head -1 | cut -d: -f1)
    pos_erstes=$(echo "$table_output" | grep -n "Erstes" | head -1 | cut -d: -f1)
    [ "$pos_fuenftes" -lt "$pos_erstes" ]
}

# --- Session löschen (grep-basiert) ---

@test "TSV: Session löschen per grep -v entfernt korrekte Zeile" {
    create_test_sessions

    local tmplog="${SESSION_LOG}.tmp"
    grep -v "^sid-003	" "$SESSION_LOG" > "$tmplog"
    mv "$tmplog" "$SESSION_LOG"

    local count
    count=$(_count_lines "$SESSION_LOG")
    assert_equal "$count" "4"
    run grep "sid-003" "$SESSION_LOG"
    assert_failure  # sid-003 sollte nicht mehr da sein
}

@test "TSV: Löschen der einzigen Session ergibt leeres Log" {
    printf '%s\t%s\t%s\t%s\t%s\n' "only-one" "/tmp" "Einzige" "2026-03-20" "-" > "$SESSION_LOG"

    local tmplog="${SESSION_LOG}.tmp"
    # grep -v gibt Fehler bei 0 Treffern, daher || true
    grep -v "^only-one	" "$SESSION_LOG" > "$tmplog" || true
    mv "$tmplog" "$SESSION_LOG"

    local count
    count=$(_count_lines "$SESSION_LOG")
    assert_equal "$count" "0"
}

@test "TSV: andere Sessions bleiben beim Löschen erhalten" {
    create_test_sessions

    local tmplog="${SESSION_LOG}.tmp"
    grep -v "^sid-002	" "$SESSION_LOG" > "$tmplog"
    mv "$tmplog" "$SESSION_LOG"

    run grep "sid-001" "$SESSION_LOG"
    assert_success
    run grep "sid-003" "$SESSION_LOG"
    assert_success
    run grep "sid-004" "$SESSION_LOG"
    assert_success
    run grep "sid-005" "$SESSION_LOG"
    assert_success
}

# --- Session Update ---

@test "TSV: Datum-Update ändert nur das Datum" {
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-upd" "/tmp/test" "Original" "2026-01-01" "#tag" > "$SESSION_LOG"

    local tmplog="${SESSION_LOG}.tmp"
    while IFS=$'\t' read -r s c b d t; do
        if [ "$s" = "sid-upd" ]; then
            printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$c" "$b" "2026-03-20" "$t"
        else
            printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$c" "$b" "$d" "$t"
        fi
    done < "$SESSION_LOG" > "$tmplog"
    mv "$tmplog" "$SESSION_LOG"

    IFS=$'\t' read -r sid cwd betreff datum tags < "$SESSION_LOG"
    assert_equal "$betreff" "Original"
    assert_equal "$datum" "2026-03-20"
    assert_equal "$tags" "#tag"
}

@test "TSV: Betreff-Update ändert Betreff und Datum" {
    printf '%s\t%s\t%s\t%s\t%s\n' "sid-upd" "/tmp/test" "Alt" "2026-01-01" "-" > "$SESSION_LOG"

    local tmplog="${SESSION_LOG}.tmp"
    while IFS=$'\t' read -r s c b d t; do
        if [ "$s" = "sid-upd" ]; then
            printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$c" "Neu" "2026-03-20" "$t"
        else
            printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$c" "$b" "$d" "$t"
        fi
    done < "$SESSION_LOG" > "$tmplog"
    mv "$tmplog" "$SESSION_LOG"

    IFS=$'\t' read -r sid cwd betreff datum tags < "$SESSION_LOG"
    assert_equal "$betreff" "Neu"
    assert_equal "$datum" "2026-03-20"
}

# --- Session-Zähler ---

@test "TSV: Zähler zeigt korrekte Anzahl" {
    create_test_sessions
    local count
    count=$(_count_lines "$SESSION_LOG")
    assert_equal "$count" "5"
}

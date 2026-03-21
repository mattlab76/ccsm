#!/usr/bin/env bash
# ccsm Uninstaller
set -e

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# Language detection
case "${CCSM_LANG:-${LC_ALL:-${LANG:-}}}" in
    de*) L="de" ;;
    *)   L="en" ;;
esac

if [[ "$L" == "de" ]]; then
    T_TITLE="ccsm Deinstallation"
    T_CONFIRM="ccsm wirklich deinstallieren? (j/n): "
    T_YES="j"
    T_CANCELLED="Abgebrochen."
    T_REMOVED="Entfernt"
    T_NOT_REMOVED="Nicht entfernt (manuell prüfen):"
    T_CONFIG="Konfiguration"
    T_DATA="Session-Daten"
    T_HOOK_MANUAL="Hook-Eintrag manuell entfernen"
    T_DONE="ccsm deinstalliert."
else
    T_TITLE="ccsm Uninstaller"
    T_CONFIRM="Really uninstall ccsm? (y/n): "
    T_YES="y"
    T_CANCELLED="Cancelled."
    T_REMOVED="Removed"
    T_NOT_REMOVED="Not removed (check manually):"
    T_CONFIG="Configuration"
    T_DATA="Session data"
    T_HOOK_MANUAL="Remove hook entry manually"
    T_DONE="ccsm uninstalled."
fi

echo -e "${BOLD}${T_TITLE}${RESET}"
echo ""

read -rp "$T_CONFIRM" confirm
[[ "${confirm,,}" != "${T_YES}" ]] && { echo "$T_CANCELLED"; exit 0; }

echo ""

FILES=(
    "$HOME/.local/bin/ccsm"
    "$HOME/.claude/hooks/ccsm_session_end.sh"
    "$HOME/.local/share/zsh/site-functions/_ccsm"
)

for f in "${FILES[@]}"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo -e "  ${GREEN}✓${RESET} ${T_REMOVED}: $f"
    fi
done

if [ -d "/tmp/ccsm" ]; then
    rm -rf "/tmp/ccsm"
    echo -e "  ${GREEN}✓${RESET} ${T_REMOVED}: /tmp/ccsm"
fi

echo ""
echo -e "${YELLOW}${T_NOT_REMOVED}${RESET}"
echo "  ~/.claude/ccsm.conf        (${T_CONFIG})"
echo "  ~/.claude/session_log.tsv   (${T_DATA})"
echo "  ~/.claude/settings.json     (${T_HOOK_MANUAL})"
echo ""
echo -e "${GREEN}${T_DONE}${RESET}"

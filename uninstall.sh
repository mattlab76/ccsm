#!/bin/bash
# ccsm Uninstaller
set -e

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

echo -e "${BOLD}ccsm Uninstaller${RESET}"
echo ""

read -rp "ccsm wirklich deinstallieren? (j/n): " confirm
[ "$confirm" != "j" ] && [ "$confirm" != "J" ] && { echo "Abgebrochen."; exit 0; }

echo ""

# Dateien entfernen
FILES=(
    "$HOME/.local/bin/ccsm"
    "$HOME/.claude/hooks/ccsm_session_end.sh"
    "$HOME/.local/share/zsh/site-functions/_ccsm"
)

for f in "${FILES[@]}"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo -e "  ${GREEN}✓${RESET} Entfernt: $f"
    fi
done

# Temp-Verzeichnis
if [ -d "/tmp/ccsm" ]; then
    rm -rf "/tmp/ccsm"
    echo -e "  ${GREEN}✓${RESET} Entfernt: /tmp/ccsm"
fi

echo ""
echo -e "${YELLOW}Nicht entfernt (manuell prüfen):${RESET}"
echo "  ~/.claude/ccsm.conf        (Konfiguration)"
echo "  ~/.claude/session_log.tsv   (Session-Daten)"
echo "  ~/.claude/settings.json     (Hook-Eintrag manuell entfernen)"
echo ""
echo -e "${GREEN}ccsm deinstalliert.${RESET}"

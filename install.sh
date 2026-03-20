#!/bin/bash
# ccsm Installer
set -e

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"
HOOK_DIR="${HOME}/.claude/hooks"
COMPLETION_DIR_ZSH="${HOME}/.local/share/zsh/site-functions"
SETTINGS_FILE="${HOME}/.claude/settings.json"
CONFIG_FILE="${HOME}/.claude/ccsm.conf"

echo -e "${BOLD}ccsm Installer${RESET}"
echo ""

# Abhängigkeiten prüfen
echo -e "${BOLD}Prüfe Abhängigkeiten...${RESET}"

if ! command -v claude &>/dev/null; then
    echo -e "${RED}Claude Code ist nicht installiert.${RESET}"
    echo "Installation: https://docs.anthropic.com/en/docs/claude-code/overview"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} Claude Code"

if ! command -v jq &>/dev/null; then
    echo -e "${RED}jq ist nicht installiert.${RESET}"
    echo "Installation: sudo pacman -S jq  /  sudo apt install jq  /  brew install jq"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} jq"

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}python3 ist nicht installiert.${RESET}"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} python3"

if command -v fzf &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} fzf (optional, Fuzzy-Search aktiv)"
else
    echo -e "  ${YELLOW}○${RESET} fzf (optional, nicht installiert — Fuzzy-Search deaktiviert)"
fi

echo ""

# Verzeichnisse erstellen
mkdir -p "$INSTALL_DIR" "$HOOK_DIR" "$COMPLETION_DIR_ZSH"

# ccsm installieren
echo -e "${BOLD}Installiere ccsm...${RESET}"
cp "$SCRIPT_DIR/ccsm" "$INSTALL_DIR/ccsm"
chmod +x "$INSTALL_DIR/ccsm"
echo -e "  ${GREEN}✓${RESET} ${INSTALL_DIR}/ccsm"

# Hook installieren
cp "$SCRIPT_DIR/hooks/session_end.sh" "$HOOK_DIR/ccsm_session_end.sh"
chmod +x "$HOOK_DIR/ccsm_session_end.sh"
echo -e "  ${GREEN}✓${RESET} ${HOOK_DIR}/ccsm_session_end.sh"

# Zsh-Completion installieren (falls zsh vorhanden)
if command -v zsh &>/dev/null; then
    cp "$SCRIPT_DIR/completions/_ccsm" "$COMPLETION_DIR_ZSH/_ccsm"
    echo -e "  ${GREEN}✓${RESET} ${COMPLETION_DIR_ZSH}/_ccsm"
fi

# Konfiguration (nur wenn noch nicht vorhanden)
if [ ! -f "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/ccsm.conf.example" "$CONFIG_FILE"
    echo -e "  ${GREEN}✓${RESET} ${CONFIG_FILE} (neu erstellt)"
else
    echo -e "  ${YELLOW}○${RESET} ${CONFIG_FILE} (bereits vorhanden, nicht überschrieben)"
fi

# Hook in settings.json eintragen
echo ""
echo -e "${BOLD}Konfiguriere Claude Code Hook...${RESET}"

if [ -f "$SETTINGS_FILE" ]; then
    # Prüfen ob Hook schon existiert
    if grep -q "ccsm_session_end" "$SETTINGS_FILE" 2>/dev/null; then
        echo -e "  ${YELLOW}○${RESET} Hook bereits in settings.json vorhanden"
    else
        # Hook zu bestehender settings.json hinzufügen
        tmp_settings="${SETTINGS_FILE}.tmp"
        jq '.hooks.SessionEnd += [{"matcher": "", "hooks": [{"type": "command", "command": "bash '"${HOOK_DIR}"'/ccsm_session_end.sh", "timeout": 5}]}]' "$SETTINGS_FILE" > "$tmp_settings" 2>/dev/null
        if [ $? -eq 0 ]; then
            mv "$tmp_settings" "$SETTINGS_FILE"
            echo -e "  ${GREEN}✓${RESET} Hook zu settings.json hinzugefügt"
        else
            rm -f "$tmp_settings"
            echo -e "  ${YELLOW}!${RESET} Konnte Hook nicht automatisch hinzufügen."
            echo "    Bitte manuell in ${SETTINGS_FILE} eintragen:"
            echo '    "hooks": {"SessionEnd": [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/ccsm_session_end.sh", "timeout": 5}]}]}'
        fi
    fi
else
    # Neue settings.json erstellen
    cat > "$SETTINGS_FILE" <<'SETTINGSEOF'
{
  "hooks": {
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/ccsm_session_end.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
    echo -e "  ${GREEN}✓${RESET} ${SETTINGS_FILE} erstellt"
fi

# PATH prüfen
echo ""
if echo "$PATH" | tr ':' '\n' | grep -q "$INSTALL_DIR"; then
    echo -e "${GREEN}${BOLD}Installation abgeschlossen!${RESET}"
    echo ""
    echo -e "Starte mit: ${CYAN}ccsm${RESET}"
else
    echo -e "${YELLOW}${BOLD}Installation abgeschlossen!${RESET}"
    echo ""
    echo -e "${YELLOW}Hinweis:${RESET} ${INSTALL_DIR} ist nicht im PATH."
    echo "Füge folgende Zeile zu ~/.bashrc oder ~/.zshrc hinzu:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo -e "Danach: ${CYAN}ccsm${RESET}"
fi

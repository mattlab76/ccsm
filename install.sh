#!/bin/bash
# ccsm Installer
set -e

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

# Language detection
case "${CCSM_LANG:-${LC_ALL:-${LANG:-}}}" in
    de*) L="de" ;;
    *)   L="en" ;;
esac

# Translations
if [[ "$L" == "de" ]]; then
    T_TITLE="ccsm Installer"
    T_CHECKING="Prüfe Abhängigkeiten..."
    T_NOT_INSTALLED="ist nicht installiert."
    T_OPTIONAL="optional, Fuzzy-Suche aktiv"
    T_OPTIONAL_MISS="optional, nicht installiert — Fuzzy-Suche deaktiviert"
    T_INSTALLING="Installiere ccsm..."
    T_CONFIG_HOOK="Konfiguriere Claude Code Hook..."
    T_HOOK_EXISTS="Hook bereits in settings.json vorhanden"
    T_HOOK_ADDED="Hook zu settings.json hinzugefügt"
    T_HOOK_MANUAL="Konnte Hook nicht automatisch hinzufügen. Bitte manuell eintragen:"
    T_HOOK_CREATED="erstellt"
    T_CONFIG_NEW="neu erstellt"
    T_CONFIG_EXISTS="bereits vorhanden, nicht überschrieben"
    T_DONE="Installation abgeschlossen!"
    T_NOT_IN_PATH="ist nicht im PATH."
    T_ADD_PATH="Füge folgende Zeile zu ~/.bashrc oder ~/.zshrc hinzu:"
    T_THEN="Danach"
    T_START="Starte mit"
else
    T_TITLE="ccsm Installer"
    T_CHECKING="Checking dependencies..."
    T_NOT_INSTALLED="is not installed."
    T_OPTIONAL="optional, fuzzy search active"
    T_OPTIONAL_MISS="optional, not installed — fuzzy search disabled"
    T_INSTALLING="Installing ccsm..."
    T_CONFIG_HOOK="Configuring Claude Code hook..."
    T_HOOK_EXISTS="Hook already in settings.json"
    T_HOOK_ADDED="Hook added to settings.json"
    T_HOOK_MANUAL="Could not add hook automatically. Please add manually:"
    T_HOOK_CREATED="created"
    T_CONFIG_NEW="created"
    T_CONFIG_EXISTS="already exists, not overwritten"
    T_DONE="Installation complete!"
    T_NOT_IN_PATH="is not in PATH."
    T_ADD_PATH="Add the following line to ~/.bashrc or ~/.zshrc:"
    T_THEN="Then run"
    T_START="Start with"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"
HOOK_DIR="${HOME}/.claude/hooks"
COMPLETION_DIR_ZSH="${HOME}/.local/share/zsh/site-functions"
SETTINGS_FILE="${HOME}/.claude/settings.json"
CONFIG_FILE="${HOME}/.claude/ccsm.conf"

echo -e "${BOLD}${T_TITLE}${RESET}"
echo ""

# Check dependencies
echo -e "${BOLD}${T_CHECKING}${RESET}"

if ! command -v claude &>/dev/null; then
    echo -e "${RED}Claude Code ${T_NOT_INSTALLED}${RESET}"
    echo "Installation: https://docs.anthropic.com/en/docs/claude-code/overview"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} Claude Code"

if ! command -v jq &>/dev/null; then
    echo -e "${RED}jq ${T_NOT_INSTALLED}${RESET}"
    echo "Install: sudo pacman -S jq  /  sudo apt install jq  /  brew install jq"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} jq"

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}python3 ${T_NOT_INSTALLED}${RESET}"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} python3"

if ! command -v dialog &>/dev/null; then
    echo -e "${RED}dialog ${T_NOT_INSTALLED}${RESET}"
    echo "Install: sudo pacman -S dialog  /  sudo apt install dialog  /  brew install dialog"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} dialog"

if command -v fzf &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} fzf (${T_OPTIONAL})"
else
    echo -e "  ${YELLOW}○${RESET} fzf (${T_OPTIONAL_MISS})"
fi

echo ""

# Create directories
mkdir -p "$INSTALL_DIR" "$HOOK_DIR" "$COMPLETION_DIR_ZSH"

# Install ccsm
echo -e "${BOLD}${T_INSTALLING}${RESET}"
cp "$SCRIPT_DIR/ccsm" "$INSTALL_DIR/ccsm"
chmod +x "$INSTALL_DIR/ccsm"
echo -e "  ${GREEN}✓${RESET} ${INSTALL_DIR}/ccsm"

# Install hook
cp "$SCRIPT_DIR/hooks/session_end.sh" "$HOOK_DIR/ccsm_session_end.sh"
chmod +x "$HOOK_DIR/ccsm_session_end.sh"
echo -e "  ${GREEN}✓${RESET} ${HOOK_DIR}/ccsm_session_end.sh"

# Zsh completion
if command -v zsh &>/dev/null; then
    cp "$SCRIPT_DIR/completions/_ccsm" "$COMPLETION_DIR_ZSH/_ccsm"
    echo -e "  ${GREEN}✓${RESET} ${COMPLETION_DIR_ZSH}/_ccsm"
fi

# Config
if [ ! -f "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/ccsm.conf.example" "$CONFIG_FILE"
    echo -e "  ${GREEN}✓${RESET} ${CONFIG_FILE} (${T_CONFIG_NEW})"
else
    echo -e "  ${YELLOW}○${RESET} ${CONFIG_FILE} (${T_CONFIG_EXISTS})"
fi

# Hook in settings.json
echo ""
echo -e "${BOLD}${T_CONFIG_HOOK}${RESET}"

if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "ccsm_session_end" "$SETTINGS_FILE" 2>/dev/null; then
        echo -e "  ${YELLOW}○${RESET} ${T_HOOK_EXISTS}"
    else
        tmp_settings="${SETTINGS_FILE}.tmp"
        jq '.hooks.SessionEnd += [{"matcher": "", "hooks": [{"type": "command", "command": "bash '"${HOOK_DIR}"'/ccsm_session_end.sh", "timeout": 5}]}]' "$SETTINGS_FILE" > "$tmp_settings" 2>/dev/null
        if [ $? -eq 0 ]; then
            mv "$tmp_settings" "$SETTINGS_FILE"
            echo -e "  ${GREEN}✓${RESET} ${T_HOOK_ADDED}"
        else
            rm -f "$tmp_settings"
            echo -e "  ${YELLOW}!${RESET} ${T_HOOK_MANUAL}"
            echo '    "hooks": {"SessionEnd": [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/ccsm_session_end.sh", "timeout": 5}]}]}'
        fi
    fi
else
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
    echo -e "  ${GREEN}✓${RESET} ${SETTINGS_FILE} (${T_HOOK_CREATED})"
fi

# PATH check
echo ""
if echo "$PATH" | tr ':' '\n' | grep -q "$INSTALL_DIR"; then
    echo -e "${GREEN}${BOLD}${T_DONE}${RESET}"
    echo ""
    echo -e "${T_START}: ${CYAN}ccsm${RESET}"
else
    echo -e "${YELLOW}${BOLD}${T_DONE}${RESET}"
    echo ""
    echo -e "${YELLOW}${INSTALL_DIR} ${T_NOT_IN_PATH}${RESET}"
    echo "${T_ADD_PATH}"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo -e "${T_THEN}: ${CYAN}ccsm${RESET}"
fi

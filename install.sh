#!/usr/bin/env bash
# ccsm Installer
set -e

# Require bash 4+
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: ccsm requires bash 4.0 or later (you have $BASH_VERSION)."
    [[ "$(uname -s)" == "Darwin" ]] && echo "Run: brew install bash"
    exit 1
fi

CCSM_OS="$(uname -s)"

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

# Detect if this is an update or fresh install
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_FILE="${HOME}/.claude/ccsm.conf"
IS_UPDATE=false
if command -v ccsm &>/dev/null || [ -f "$INSTALL_DIR/ccsm" ]; then
    IS_UPDATE=true
fi

# Language detection
L="en"
CCSM_LANG_SETTING=""

if $IS_UPDATE && [ -f "$CONFIG_FILE" ]; then
    # Update: read language from existing config
    CCSM_LANG_SETTING=$(grep -E '^CCSM_LANG=' "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ')
    [ "$CCSM_LANG_SETTING" = "de" ] && L="de"
else
    # Fresh install: ask interactively
    DETECTED_LOCALE="${CCSM_LANG:-${LC_ALL:-${LANG:-}}}"
    case "$DETECTED_LOCALE" in
        de*)
            echo -e "${BOLD}Sprache / Language${RESET}"
            echo -e "  Deutsche Locale erkannt (${DETECTED_LOCALE})"
            echo -ne "  ${BOLD}Deutsche Sprache verwenden?${RESET} [j/n] "
            read -r -n 1 lang_choice
            echo ""
            if [[ "${lang_choice,,}" == "j" ]] || [[ -z "$lang_choice" ]]; then
                L="de"
                CCSM_LANG_SETTING="de"
            else
                CCSM_LANG_SETTING="en"
            fi
            echo ""
            ;;
        en*)
            CCSM_LANG_SETTING="en"
            ;;
        *)
            echo -e "${YELLOW}Note: Your locale (${DETECTED_LOCALE}) is not supported.${RESET}"
            echo -e "  ccsm supports English and German. Using English (default)."
            echo ""
            CCSM_LANG_SETTING="en"
            ;;
    esac
fi

# Translations
if [[ "$L" == "de" ]]; then
    T_TITLE="ccsm Installer"
    T_CHECKING="Prüfe Abhängigkeiten..."
    T_NOT_INSTALLED="ist nicht installiert."
    T_MISSING_HEADER="Fehlende Abhängigkeiten:"
    T_MISSING_INSTALL="Bitte die fehlenden Pakete installieren bevor ccsm genutzt werden kann."
    T_MISSING_CONTINUE="Trotzdem fortfahren? [j/n]"
    T_MISSING_ABORT="Installation abgebrochen."
    T_UPDATE_DETECTED="ccsm ist bereits installiert — wird aktualisiert."
    T_UPDATE_RESTART="Hinweis: Falls ccsm gerade läuft, bitte beenden und neu starten damit die Änderungen wirksam werden."
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
    T_MISSING_HEADER="Missing dependencies:"
    T_MISSING_INSTALL="Please install the missing packages before using ccsm."
    T_MISSING_CONTINUE="Continue anyway? [y/n]"
    T_MISSING_ABORT="Installation cancelled."
    T_UPDATE_DETECTED="ccsm is already installed — updating."
    T_UPDATE_RESTART="Note: If ccsm is currently running, please quit and restart it for changes to take effect."
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
HOOK_DIR="${HOME}/.claude/hooks"
COMPLETION_DIR_ZSH="${HOME}/.local/share/zsh/site-functions"
SETTINGS_FILE="${HOME}/.claude/settings.json"

echo -e "${BOLD}${T_TITLE}${RESET}"
echo ""

# Check dependencies — collect all missing, then report
echo -e "${BOLD}${T_CHECKING}${RESET}"

MISSING=()

if command -v claude &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} Claude Code"
else
    echo -e "  ${RED}✗${RESET} Claude Code"
    MISSING+=("claude")
fi

if command -v jq &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} jq"
else
    echo -e "  ${RED}✗${RESET} jq"
    MISSING+=("jq")
fi

if command -v python3 &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} python3"
else
    echo -e "  ${RED}✗${RESET} python3"
    MISSING+=("python3")
fi

# Show missing dependencies and install hints
if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}${BOLD}${T_MISSING_HEADER}${RESET}"
    echo ""
    for dep in "${MISSING[@]}"; do
        case "$dep" in
            claude)
                echo -e "  ${RED}•${RESET} Claude Code"
                echo "    https://docs.anthropic.com/en/docs/claude-code/overview"
                ;;
            jq)
                echo -e "  ${RED}•${RESET} jq"
                case "$CCSM_OS" in
                    Linux)   echo "    sudo pacman -S jq  /  sudo apt install jq" ;;
                    Darwin)  echo "    brew install jq" ;;
                    FreeBSD) echo "    sudo pkg install jq" ;;
                    *)       echo "    https://jqlang.github.io/jq/download/" ;;
                esac
                ;;
            python3)
                echo -e "  ${RED}•${RESET} python3"
                case "$CCSM_OS" in
                    Linux)   echo "    sudo pacman -S python  /  sudo apt install python3" ;;
                    Darwin)  echo "    brew install python3" ;;
                    FreeBSD) echo "    sudo pkg install python3" ;;
                    *)       echo "    https://www.python.org/downloads/" ;;
                esac
                ;;
        esac
    done
    echo ""
    echo -e "${T_MISSING_INSTALL}"
    echo -ne "${T_MISSING_CONTINUE} "
    read -r -n 1 dep_choice
    echo ""
    if [[ "${dep_choice,,}" == "n" ]]; then
        echo -e "${T_MISSING_ABORT}"
        exit 1
    fi
    echo ""
fi

# Show update notice
if $IS_UPDATE; then
    echo ""
    echo -e "${YELLOW}${T_UPDATE_DETECTED}${RESET}"
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
    # Write chosen language to config
    if [ -n "$CCSM_LANG_SETTING" ]; then
        echo "CCSM_LANG=$CCSM_LANG_SETTING" >> "$CONFIG_FILE"
    fi
    echo -e "  ${GREEN}✓${RESET} ${CONFIG_FILE} (${T_CONFIG_NEW}, CCSM_LANG=${CCSM_LANG_SETTING})"
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
    if $IS_UPDATE; then
        echo ""
        echo -e "${YELLOW}${T_UPDATE_RESTART}${RESET}"
    fi
    echo ""
    echo -e "${T_START}: ${CYAN}ccsm${RESET}"
else
    echo -e "${YELLOW}${BOLD}${T_DONE}${RESET}"
    echo ""
    echo -e "${YELLOW}${INSTALL_DIR} ${T_NOT_IN_PATH}${RESET}"
    echo "${T_ADD_PATH}"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    if [[ "$CCSM_OS" == "Darwin" ]]; then
        echo "  (add to ~/.zshrc or ~/.bash_profile)"
    else
        echo "  (add to ~/.bashrc or ~/.zshrc)"
    fi
    echo ""
    echo -e "${T_THEN}: ${CYAN}ccsm${RESET}"
fi

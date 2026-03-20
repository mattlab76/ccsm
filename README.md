# ccsm — Claude Code Session Manager

A terminal-based session manager for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview). Save, tag, search, and resume your Claude Code sessions with an interactive TUI menu.

[Deutsch](#deutsch) | [English](#english)

---

## Screenshot

```
╭──────────────────────────────────────────────────────────────────────────────╮
│                                                                              │
│                              ┌─┐┌─┐┌─┐┌┬┐                                  │
│                              │  │  └─┐│││                                   │
│                              └─┘└─┘└─┘┴ ┴                                   │
│                                                                              │
│                    Claude Code Session Manager v1.0.0                        │
│                                                                              │
│                          3 gespeicherte Session(s)                           │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│      Letzte Sessions  (a-e zum Direktstart)                                  │
│                                                                              │
│      a) 2026-03-20  PV Dashboard Responsive Fix  ~/appsDev/energie-webapp   │
│      b) 2026-03-19  Vaultwarden Docker Setup  ~/mattlab-infra               │
│      c) 2026-03-18  OPNsense Firewall Audit  ~/opnsense-audit              │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│      1)  Neue Session starten                                                │
│      2)  Alle Sessions anzeigen / suchen                                     │
│      3)  Session löschen                                                     │
│      4)  Statistiken                                                         │
│      q)  Beenden                                                             │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
```

---

<a id="english"></a>

## English

### Features

- **Interactive TUI menu** — Quick overview and session launcher
- **Session history** — Save sessions with custom subjects and tags
- **Quick resume (a-e)** — Jump back into recent sessions directly from the menu
- **Auto-cd** — Automatically switch to the session's working directory on resume
- **Subject suggestions** — Auto-generates subject lines from your conversation
- **fzf integration** — Fuzzy search across all sessions (optional)
- **Tags** — Organize sessions with tags like `#infra`, `#webapp`, `#bugfix`
- **Auto-cleanup** — Configurable review of old sessions on startup
- **Statistics** — Session count, top directories, top tags
- **Search** — Find sessions by subject, directory, or tag
- **Zsh completion** — Tab completion for all CLI flags

### Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) (CLI)
- `jq`
- `python3`
- `fzf` (optional, enables fuzzy search)
- `bash` 4+

### Installation

```bash
git clone https://github.com/mattlab76/ccsm.git
cd ccsm
git submodule update --init --recursive
bash install.sh
```

The installer will:
1. Check dependencies (claude, jq, python3, fzf)
2. Copy `ccsm` to `~/.local/bin/`
3. Install the SessionEnd hook to `~/.claude/hooks/`
4. Configure the hook in `~/.claude/settings.json`
5. Install zsh completion (if zsh is available)
6. Create a default config at `~/.claude/ccsm.conf`

### Usage

#### Interactive menu

```bash
ccsm
```

#### CLI commands

```bash
ccsm --search <text>   # Search sessions by subject, directory, or tag
ccsm --stats           # Show statistics
ccsm --cleanup         # Manually review old sessions
ccsm --version         # Show version
ccsm --help            # Show help
```

#### Menu shortcuts

| Key | Action |
|-----|--------|
| `a-e` | Resume one of the last 5 sessions directly |
| `1` | Start a new Claude Code session |
| `2` | Browse/search all sessions (uses fzf if available) |
| `3` | Delete a session |
| `4` | Show statistics |
| `q` | Quit |

### Configuration

Edit `~/.claude/ccsm.conf`:

```bash
# Days after which a session is considered "old" (0 = disabled)
CLEANUP_DAYS=30

# Maximum number of sessions to keep (0 = unlimited)
MAX_SESSIONS=0
```

### How it works

1. **ccsm** wraps the `claude` CLI command
2. A **SessionEnd hook** fires when Claude Code exits, saving session metadata (ID, working directory, first prompt) to a temp file
3. After Claude exits, the wrapper reads the temp file and prompts you to save the session with a subject and tags
4. Sessions are stored in `~/.claude/session_log.tsv`
5. On resume, ccsm automatically `cd`s into the session's directory and runs `claude --resume <id>`

### Running tests

```bash
git submodule update --init --recursive
bash test/run_tests.sh
```

### Uninstall

```bash
cd ccsm
bash uninstall.sh
```

---

<a id="deutsch"></a>

## Deutsch

### Funktionen

- **Interaktives TUI-Menü** — Schnellübersicht und Session-Starter
- **Session-Historie** — Sessions mit Betreff und Tags speichern
- **Schnellstart (a-e)** — Letzte Sessions direkt aus dem Menü fortsetzen
- **Auto-cd** — Automatisch ins Arbeitsverzeichnis der Session wechseln
- **Betreff-Vorschläge** — Automatische Betreffzeilen aus der Konversation
- **fzf-Integration** — Fuzzy-Suche über alle Sessions (optional)
- **Tags** — Sessions mit Tags wie `#infra`, `#webapp`, `#bugfix` organisieren
- **Auto-Cleanup** — Konfigurierbares Review alter Sessions beim Start
- **Statistiken** — Anzahl Sessions, Top-Verzeichnisse, Top-Tags
- **Suche** — Sessions nach Betreff, Verzeichnis oder Tag finden
- **Zsh-Completion** — Tab-Vervollständigung für alle CLI-Flags

### Voraussetzungen

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) (CLI)
- `jq`
- `python3`
- `fzf` (optional, aktiviert Fuzzy-Suche)
- `bash` 4+

### Installation

```bash
git clone https://github.com/mattlab76/ccsm.git
cd ccsm
git submodule update --init --recursive
bash install.sh
```

Der Installer macht folgendes:
1. Prüft Abhängigkeiten (claude, jq, python3, fzf)
2. Kopiert `ccsm` nach `~/.local/bin/`
3. Installiert den SessionEnd-Hook nach `~/.claude/hooks/`
4. Konfiguriert den Hook in `~/.claude/settings.json`
5. Installiert Zsh-Completion (falls zsh vorhanden)
6. Erstellt die Konfigurationsdatei `~/.claude/ccsm.conf`

### Nutzung

#### Interaktives Menü

```bash
ccsm
```

#### CLI-Befehle

```bash
ccsm --search <text>   # Sessions nach Betreff, Verzeichnis oder Tag suchen
ccsm --stats           # Statistiken anzeigen
ccsm --cleanup         # Alte Sessions manuell prüfen
ccsm --version         # Version anzeigen
ccsm --help            # Hilfe anzeigen
```

#### Menü-Tasten

| Taste | Aktion |
|-------|--------|
| `a-e` | Eine der letzten 5 Sessions direkt fortsetzen |
| `1` | Neue Claude Code Session starten |
| `2` | Alle Sessions anzeigen / suchen (nutzt fzf wenn vorhanden) |
| `3` | Session löschen |
| `4` | Statistiken |
| `q` | Beenden |

### Konfiguration

Bearbeite `~/.claude/ccsm.conf`:

```bash
# Tage nach denen eine Session als "alt" gilt (0 = deaktiviert)
CLEANUP_DAYS=30

# Maximale Anzahl Sessions (0 = unbegrenzt)
MAX_SESSIONS=0
```

### So funktioniert es

1. **ccsm** ist ein Wrapper um den `claude` CLI-Befehl
2. Ein **SessionEnd-Hook** wird beim Beenden von Claude Code ausgelöst und speichert Session-Metadaten (ID, Arbeitsverzeichnis, erster Prompt) in eine Temp-Datei
3. Nach dem Beenden liest der Wrapper die Temp-Datei und fragt nach Betreff und Tags
4. Sessions werden in `~/.claude/session_log.tsv` gespeichert
5. Beim Fortsetzen wechselt ccsm automatisch ins Verzeichnis und startet `claude --resume <id>`

### Tests ausführen

```bash
git submodule update --init --recursive
bash test/run_tests.sh
```

### Deinstallation

```bash
cd ccsm
bash uninstall.sh
```

---

## License / Lizenz

MIT

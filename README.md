# ccsm — Claude Code Session Manager

A terminal-based session manager for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview). Save, tag, search, and resume your Claude Code sessions with an interactive TUI menu.

[![Tests](https://github.com/mattlab76/ccsm/actions/workflows/test.yml/badge.svg)](https://github.com/mattlab76/ccsm/actions/workflows/test.yml)

[Deutsch](#deutsch) | [English](#english)

---

## Screenshot

```
  ╭──────────────────────────────────────────────────────────────────────────╮
  │                                                                          │
  │   ╔═╗ ╔═╗ ╔═╗ ╔╦╗   Claude Code Session Manager v1.5.0   3 session(s)  │
  │   ║   ║   ╚═╗ ║║║                                                       │
  │   ╚═╝ ╚═╝ ╚═╝ ╩ ╩                                                       │
  │                                                                          │
  │  ══════════════════════════════════════════════════════════════════════   │
  │   Recent Sessions (enter 1-5 to resume)                                  │
  │                                                                          │
  │   ┌───┬────────────┬──────────────────┬──────────────┬──────────┬──────┐ │
  │   │ # │ Date       │ Subject          │ Directory    │ Total In │ ...  │ │
  │   ├───┼────────────┼──────────────────┼──────────────┼──────────┼──────┤ │
  │   │ 1 │ 2026-03-21 │ Cross-platform.. │ ~/appsDev/c..│    1.3M  │ ...  │ │
  │   │ 2 │ 2026-03-20 │ Docker Setup     │ ~/infra      │  456.2k  │ ...  │ │
  │   │ 3 │ 2026-03-19 │ Firewall Audit   │ ~/opnsense   │  234.1k  │ ...  │ │
  │   └───┴────────────┴──────────────────┴──────────────┴──────────┴──────┘ │
  │                                                                          │
  │  ══════════════════════════════════════════════════════════════════════   │
  │   What would you like to do?                                             │
  │                                                                          │
  │   [n] Start new session                                                  │
  │   [s] Browse / search sessions                                           │
  │   [d] Delete session                                                     │
  │   [i] Statistics                                                         │
  │   [q] Quit                                                               │
  │                                                                          │
  ╰──────────────────────────────────────────────────────────────────────────╯
```

---

<a id="english"></a>

## English

### Features

- **Interactive TUI menu** — Colored box-drawing UI with session table and quick actions
- **Session history** — Save sessions with custom subjects and tags
- **Quick resume (1-5)** — Jump back into recent sessions directly from the main menu
- **Auto-cd** — Automatically switches to the session's working directory on resume
- **Subject suggestions** — Auto-generates subject lines from your conversation transcript
- **Token tracking** — Input/output token usage per session + lifetime counter with visual bars
- **Tags** — Organize sessions with tags like `#infra`, `#webapp`, `#bugfix`
- **Search** — Find sessions by subject, directory, or tag (case-insensitive)
- **Auto-cleanup** — Configurable review of old sessions on startup
- **Statistics** — Token usage, session count, top directories, top tags
- **Bilingual** — Full English and German UI (auto-detected, configurable)
- **Cross-platform** — Runs on Linux, macOS, and FreeBSD
- **Zsh completion** — Tab completion for all CLI flags
- **Parallel-safe** — File locking prevents data loss with concurrent sessions

### Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) (CLI)
- `bash` 4+ (macOS: `brew install bash`)
- `jq`
- `python3`

### Installation

#### From source

```bash
git clone https://github.com/mattlab76/ccsm.git
cd ccsm
bash install.sh
```

#### Arch Linux (AUR)

```bash
yay -S ccsm-git
```

The installer will:
1. Detect your language and ask for preference (German/English)
2. Check all dependencies and report missing ones with install hints
3. Copy `ccsm` to `~/.local/bin/`
4. Install the SessionEnd hook to `~/.claude/hooks/`
5. Configure the hook in `~/.claude/settings.json`
6. Install zsh completion (if zsh is available)
7. Create a default config at `~/.claude/ccsm.conf`

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
| `1-5` | Resume one of the last 5 sessions directly |
| `n` | Start a new Claude Code session (with optional subject + directory) |
| `s` | Browse/search all sessions |
| `d` | Delete sessions (comma-separated, e.g. 1,3,5) |
| `i` | Show statistics (tokens, top dirs, top tags) |
| `q` | Quit |

#### New session flow

When starting a new session (`n`), ccsm guides you through:
1. **Subject** — Optional, will be auto-suggested from transcript after session ends
2. **Directory** — Use current directory or enter a custom path (`q` to cancel)
3. **Claude starts** — Your session runs normally
4. **Save prompt** — After Claude exits, save with subject and tags

### Configuration

Edit `~/.claude/ccsm.conf`:

```bash
# Language (en, de) — auto-detected from system locale if not set
CCSM_LANG=en

# Days after which a session is considered "old" (0 = disabled)
CLEANUP_DAYS=30
```

### How it works

1. **ccsm** wraps the `claude` CLI command
2. A **SessionEnd hook** fires when Claude Code exits, saving session metadata (ID, working directory, transcript path, token usage) to a temp file
3. After Claude exits, ccsm reads the temp file and prompts you to save the session with a subject and tags
4. Sessions are stored in `~/.claude/session_log.tsv` (tab-separated)
5. On resume, ccsm automatically `cd`s into the session's directory and runs `claude --resume <id>`
6. Token usage (input + output) is tracked per session and accumulated over the session's lifetime

### Running tests

```bash
git submodule update --init --recursive
bash test/run_tests.sh
```

92 tests covering: CLI arguments, search, statistics, cleanup, TSV operations, edge cases, hook, cross-platform wrappers.

### Uninstall

```bash
bash uninstall.sh
```

Your session data (`~/.claude/session_log.tsv`) and config (`~/.claude/ccsm.conf`) are preserved.

---

<a id="deutsch"></a>

## Deutsch

### Funktionen

- **Interaktives TUI-Menü** — Farbige Box-Drawing UI mit Session-Tabelle und Schnellaktionen
- **Session-Historie** — Sessions mit Betreff und Tags speichern
- **Schnellstart (1-5)** — Letzte Sessions direkt aus dem Hauptmenü fortsetzen
- **Auto-cd** — Automatisch ins Arbeitsverzeichnis der Session wechseln
- **Betreff-Vorschläge** — Automatische Betreffzeilen aus dem Gesprächsverlauf
- **Token-Tracking** — Input/Output-Token pro Session + Lifetime-Zähler mit visuellen Balken
- **Tags** — Sessions mit Tags wie `#infra`, `#webapp`, `#bugfix` organisieren
- **Suche** — Sessions nach Betreff, Verzeichnis oder Tag finden (Groß/Kleinschreibung egal)
- **Auto-Cleanup** — Konfigurierbares Review alter Sessions beim Start
- **Statistiken** — Token-Verbrauch, Anzahl Sessions, Top-Verzeichnisse, Top-Tags
- **Zweisprachig** — Vollständige englische und deutsche Oberfläche (automatisch erkannt, konfigurierbar)
- **Cross-Platform** — Läuft auf Linux, macOS und FreeBSD
- **Zsh-Completion** — Tab-Vervollständigung für alle CLI-Flags
- **Parallel-sicher** — File-Locking verhindert Datenverlust bei gleichzeitigen Sessions

### Voraussetzungen

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) (CLI)
- `bash` 4+ (macOS: `brew install bash`)
- `jq`
- `python3`

### Installation

#### Aus dem Quellcode

```bash
git clone https://github.com/mattlab76/ccsm.git
cd ccsm
bash install.sh
```

#### Arch Linux (AUR)

```bash
yay -S ccsm-git
```

Der Installer:
1. Erkennt die Systemsprache und fragt nach Präferenz (Deutsch/Englisch)
2. Prüft alle Abhängigkeiten und listet fehlende mit Install-Hinweisen je OS
3. Kopiert `ccsm` nach `~/.local/bin/`
4. Installiert den SessionEnd-Hook nach `~/.claude/hooks/`
5. Konfiguriert den Hook in `~/.claude/settings.json`
6. Installiert Zsh-Completion (falls zsh vorhanden)
7. Erstellt die Konfiguration `~/.claude/ccsm.conf`

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
| `1-5` | Eine der letzten 5 Sessions direkt fortsetzen |
| `n` | Neue Claude Code Session starten (mit optionalem Betreff + Verzeichnis) |
| `s` | Alle Sessions anzeigen / durchsuchen |
| `d` | Sessions löschen (kommagetrennt, z.B. 1,3,5) |
| `i` | Statistiken anzeigen (Tokens, Top-Verzeichnisse, Top-Tags) |
| `q` | Beenden |

#### Neue Session starten

Beim Starten einer neuen Session (`n`) führt ccsm durch:
1. **Betreff** — Optional, wird nach Session-Ende automatisch aus dem Transcript vorgeschlagen
2. **Verzeichnis** — Aktuelles verwenden oder eigenen Pfad eingeben (`q` zum Abbrechen)
3. **Claude startet** — Die Session läuft normal
4. **Speichern** — Nach dem Beenden: Betreff und Tags vergeben

### Konfiguration

Bearbeite `~/.claude/ccsm.conf`:

```bash
# Sprache (en, de) — wird automatisch aus System-Locale erkannt wenn nicht gesetzt
CCSM_LANG=de

# Tage nach denen eine Session als "alt" gilt (0 = deaktiviert)
CLEANUP_DAYS=30
```

### So funktioniert es

1. **ccsm** ist ein Wrapper um den `claude` CLI-Befehl
2. Ein **SessionEnd-Hook** wird beim Beenden von Claude Code ausgelöst und speichert Session-Metadaten (ID, Arbeitsverzeichnis, Transcript-Pfad, Token-Verbrauch) in eine Temp-Datei
3. Nach dem Beenden liest ccsm die Temp-Datei und fragt nach Betreff und Tags
4. Sessions werden in `~/.claude/session_log.tsv` gespeichert (Tab-separiert)
5. Beim Fortsetzen wechselt ccsm automatisch ins Verzeichnis und startet `claude --resume <id>`
6. Token-Verbrauch (Input + Output) wird pro Session erfasst und über die Lebensdauer der Session akkumuliert

### Tests ausführen

```bash
git submodule update --init --recursive
bash test/run_tests.sh
```

92 Tests decken ab: CLI-Argumente, Suche, Statistiken, Cleanup, TSV-Operationen, Edge Cases, Hook, Cross-Platform-Wrapper.

### Deinstallation

```bash
bash uninstall.sh
```

Session-Daten (`~/.claude/session_log.tsv`) und Konfiguration (`~/.claude/ccsm.conf`) bleiben erhalten.

---

## License / Lizenz

MIT

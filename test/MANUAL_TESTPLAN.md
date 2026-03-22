# ccsm — Manueller Testplan

Dieses Dokument beschreibt alle manuellen Tests die vor einem Release durchgeführt werden sollten.
Die automatischen Tests (`test/run_tests.sh`) decken Funktionslogik ab, aber interaktive UI-Flows und Terminal-Verhalten müssen manuell geprüft werden.

**Voraussetzung:** ccsm ist installiert (`./install.sh`) und mindestens 2-3 gespeicherte Sessions vorhanden.

---

## 1. Installation

### 1.1 Neuinstallation
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `bash uninstall.sh` (falls installiert) | Saubere Deinstallation |
| 2 | `rm -f ~/.claude/ccsm.conf` | Config entfernen |
| 3 | `bash install.sh` | Sprachauswahl erscheint (bei DE-Locale) |
| 4 | Sprache mit `j` bestätigen | Installer läuft auf Deutsch weiter |
| 5 | | Alle Dependencies werden geprüft (✓ oder ✗) |
| 6 | | ccsm wird nach `~/.local/bin/` kopiert |
| 7 | | Hook wird installiert und in settings.json eingetragen |
| 8 | | Config wird erstellt mit gewählter Sprache |
| 9 | `cat ~/.claude/ccsm.conf` | Enthält `CCSM_LANG=de` |

### 1.2 Update-Installation
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `bash install.sh` (ccsm bereits installiert) | "ccsm ist bereits installiert — wird aktualisiert" |
| 2 | | Keine Sprachauswahl (wird aus Config gelesen) |
| 3 | | Config wird nicht überschrieben |
| 4 | | Hinweis: "Falls ccsm gerade läuft, bitte beenden und neu starten" |

### 1.3 Fehlende Dependencies
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | jq temporär umbenennen: `sudo mv /usr/bin/jq /usr/bin/jq.bak` | |
| 2 | `bash install.sh` | jq wird als ✗ angezeigt mit Install-Hinweis |
| 3 | "Trotzdem fortfahren?" | Bei `n` → Abbruch, bei `j` → Installation läuft |
| 4 | jq zurück: `sudo mv /usr/bin/jq.bak /usr/bin/jq` | |

---

## 2. Hauptmenü

### 2.1 Anzeige
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | `ccsm` starten | Logo, Versionsnummer, Session-Anzahl korrekt |
| 2 | Letzte 5 Sessions | Tabelle mit #, Date (inkl. Uhrzeit), Subject, Directory, Tokens |
| 3 | Menüoptionen | [n] [s] [d] [i] [l] [c] [q] sichtbar |
| 4 | Spalten-Ausrichtung | Alle Spalten korrekt ausgerichtet, keine Verschiebung |
| 5 | Terminal verkleinern (60 Spalten) | Tabelle passt sich an, kein Overflow |
| 6 | Terminal vergrößern (200+ Spalten) | Tabelle skaliert, Subject/Dir werden breiter |

### 2.2 Quick Resume (1-5)
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | Nummer einer gültigen Session eingeben | Claude startet im richtigen Verzeichnis |
| 2 | Claude beenden | Save-Dialog erscheint |
| 3 | Session speichern | Datum/Uhrzeit wird aktualisiert, Session steht oben in der Liste |

### 2.3 Navigation
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `q` eingeben | ccsm beendet sich sauber, Terminal ist sauber |
| 2 | Enter (leer) eingeben | ccsm beendet sich |
| 3 | Ungültige Eingabe (z.B. `x`) | Kein Crash, Menü wird neu angezeigt |

---

## 3. Neue Session [n]

### 3.1 Normaler Flow
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `n` im Hauptmenü | "Subject for this session" Prompt |
| 2 | Subject eingeben (z.B. "Test Session") | |
| 3 | "Start in current directory?" → `j` | Claude startet im aktuellen Verzeichnis |
| 4 | Claude beenden | Save-Dialog mit Auto-Subject Vorschlag |
| 5 | Subject akzeptieren → `j` | |
| 6 | Tags eingeben (z.B. "#test") | Session gespeichert mit Subject + Tags |

### 3.2 Anderes Verzeichnis
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `n` → Subject → "Start in current directory?" → `n` | Pfad-Eingabe erscheint |
| 2 | Gültigen Pfad eingeben | Claude startet in dem Verzeichnis |
| 3 | Ungültigen Pfad eingeben | "Directory not found. Create it?" |
| 4 | Bei Anlegen → `j` | Verzeichnis wird erstellt, Claude startet |

### 3.3 Abbrechen
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | Pfad-Eingabe → `q` | Zurück zum Hauptmenü |
| 2 | Pfad-Eingabe → Enter (leer) | Zurück zum Hauptmenü |
| 3 | Subject leer lassen → Enter | Subject wird übersprungen (Auto-Subject nach Session) |

---

## 4. Browse / Search [s]

### 4.1 Session-Liste
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | `s` im Hauptmenü | Alle Sessions in voller Tabelle (8 Spalten) |
| 2 | Sessions in umgekehrter Reihenfolge | Neueste zuerst |
| 3 | Nummer eingeben | Session wird resumed |
| 4 | `q` | Zurück zum Hauptmenü |

### 4.2 Suche
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `/suchbegriff` eingeben | Nur passende Sessions angezeigt |
| 2 | Suche nach Subject | Treffer korrekt |
| 3 | Suche nach Verzeichnisname | Treffer korrekt |
| 4 | Suche nach Tag (z.B. `/#test`) | Treffer korrekt |
| 5 | Suche ohne Treffer | "No matches found" |
| 6 | Suche ist case-insensitiv | `DOCKER` findet "Docker Setup" |

---

## 5. Session löschen [d]

### 5.1 Normales Löschen
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `d` im Hauptmenü | Alle Sessions mit Nummern angezeigt |
| 2 | Einzelne Nummer eingeben (z.B. `3`) | Bestätigung: "Really delete?" |
| 3 | `j` bestätigen | Session gelöscht, Meldung erscheint |
| 4 | Mehrere Nummern (z.B. `1,3,5`) | Alle ausgewählten werden gelöscht |

### 5.2 Abbrechen
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `q` bei Session-Auswahl | Zurück zum Hauptmenü |
| 2 | `n` bei Bestätigung | Nichts wird gelöscht |

---

## 6. Statistiken [i]

| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | `i` im Hauptmenü | Statistik-Seite erscheint |
| 2 | Overview | Version, Session-Anzahl, Oldest/Newest (mit Uhrzeit), Cleanup-Tage |
| 3 | Token Usage | Active + Lifetime Tokens, Balkendiagramm |
| 4 | Token Info | Amber-farbige Erklärung der Token-Werte |
| 5 | Top Directories | Top 5 Verzeichnisse mit Anzahl |
| 6 | Top Tags | Tags mit Häufigkeit (nur wenn Tags vorhanden) |
| 7 | All Sessions | Vollständige Tabelle unten |
| 8 | `q` | Zurück zum Hauptmenü |

---

## 7. Activity Log [l]

| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | `l` im Hauptmenü | Log-Einträge angezeigt (neueste zuerst) |
| 2 | Farbcodierung | [NEW] grün, [RESUME] teal, [SAVE] violett, [DELETE] amber, [SETTINGS] dim |
| 3 | Log nach Aktionen | NEW, RESUME, SAVE, DELETE, CLEANUP, SETTINGS sichtbar |
| 4 | Leeres Log | "No log entries." |
| 5 | `q` | Zurück zum Hauptmenü |

---

## 8. Einstellungen [c]

### 8.1 Anzeige
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | `c` im Hauptmenü | Settings-Seite mit 3 Optionen |
| 2 | Aktuelle Werte | Sprache, Cleanup-Tage, Log-Tage werden angezeigt |

### 8.2 Sprache ändern
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `1` → `de` eingeben | "Einstellungen gespeichert" |
| 2 | Settings-Seite wird neu angezeigt | Aktuell: de |
| 3 | `q` → Hauptmenü | Menü ist auf Deutsch |
| 4 | `c` → `1` → `en` | Zurück auf Englisch |

### 8.3 Cleanup-Tage ändern
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `2` → `60` eingeben | "Settings saved" |
| 2 | Settings-Seite zeigt aktuellen Wert | Current: 60 |
| 3 | Ungültige Eingabe (z.B. `abc`) | "Invalid input, keeping current value" |

### 8.4 Log-Tage ändern
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `3` → `180` eingeben | "Settings saved" |
| 2 | Settings-Seite zeigt aktuellen Wert | Current: 180 |
| 3 | `3` → `0` eingeben | Logging wird deaktiviert |

### 8.5 Navigation
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | Nach Änderung | Bleibt in Settings (nicht zurück zum Hauptmenü) |
| 2 | `q` | Zurück zum Hauptmenü |
| 3 | `cat ~/.claude/ccsm.conf` | Alle geänderten Werte korrekt gespeichert |

---

## 9. Session speichern (Save-Dialog)

### 9.1 Neue Session
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | Nach Claude-Beendigung | Save-Dialog mit Dir + Token-Info |
| 2 | "Save this session?" → `j` | Auto-Subject wird vorgeschlagen |
| 3 | Subject akzeptieren → `j` | Subject übernommen |
| 4 | Subject ändern → `n` → eigenen eingeben | Eigener Subject wird verwendet |
| 5 | Tags eingeben | Tags werden gespeichert |
| 6 | Tags leer lassen | `-` als Platzhalter |
| 7 | "Save?" → `n` | Session wird nicht gespeichert |

### 9.2 Bestehende Session (Resume + Save)
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | Resumed Session beenden | "Current subject: ..." angezeigt |
| 2 | "Accept this subject?" → `j` | Subject bleibt, Datum/Uhrzeit wird aktualisiert |
| 3 | "Accept?" → `n` → neuen eingeben | Neuer Subject wird gespeichert |
| 4 | Session steht danach oben in der Liste | Position wurde aktualisiert |

---

## 10. Fehlerbehandlung: Verzeichnis fehlt

### 10.1 Beim Resumieren
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | Verzeichnis einer Session manuell löschen | |
| 2 | Session resumieren | "Directory no longer exists: /pfad" |
| 3 | Option [1] Neu anlegen | Verzeichnis wird erstellt, Claude startet |
| 4 | Option [2] Session löschen | Session wird entfernt + im Log protokolliert |
| 5 | Option [q] Abbrechen | Zurück zum Hauptmenü |

### 10.2 Markierung in Tabellen
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | Session mit fehlendem Verzeichnis | `[?]` Marker in Amber vor dem Subject |
| 2 | Marker in Hauptmenü | Sichtbar in kompakter Tabelle |
| 3 | Marker in Browse [s] | Sichtbar in voller Tabelle |
| 4 | Marker in Delete [d] | Sichtbar |
| 5 | Marker in Search | Sichtbar |

---

## 11. Fehlerbehandlung: Session bei Claude Code abgelaufen

### 11.1 Beim Resumieren
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | Session resumieren die bei Claude Code nicht mehr existiert | Claude zeigt "No conversation found" |
| 2 | ccsm zeigt danach | "✗ Session no longer exists at Claude Code" |
| 3 | Option [1] Neue Session | Alte wird gelöscht, neue startet mit gleichem Subject + Dir |
| 4 | Option [2] Löschen | Session wird entfernt |
| 5 | Option [q] Behalten | Session bleibt in ccsm (als Referenz) |

### 11.2 Markierung in Tabellen
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | Abgelaufene Session | `[!]` Marker in Rot vor dem Subject |
| 2 | Spalten bleiben korrekt ausgerichtet | Kein Verschieben durch Marker |

### 11.3 Legende
| # | Prüfpunkt | Erwartung |
|---|-----------|-----------|
| 1 | Wenn markierte Sessions existieren | Legende unter der Tabelle: `[!] = ...` / `[?] = ...` |
| 2 | Wenn keine markierten Sessions | Keine Legende angezeigt |

---

## 12. Startup-Checks

### 12.1 Auto-Cleanup alter Sessions
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | Session mit Datum > CLEANUP_DAYS erstellen | |
| 2 | ccsm starten | Cleanup-Dialog erscheint |
| 3 | Nummer eingeben | Ausgewählte Sessions gelöscht |
| 4 | `q` oder Enter | Sessions behalten |

### 12.2 Ungültige Sessions erkennen
| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | ccsm starten mit ungültigen Sessions | Warnung mit Anzahl + Liste (Subject + Dir) |
| 2 | `[!]` rot + `[?]` amber korrekt | Je nach Typ |
| 3 | "Remove invalid sessions now?" → `j` | Alle entfernt, im Log protokolliert |
| 4 | "Remove?" → `n` | Sessions bleiben, werden beim nächsten Start nicht mehr gefragt |
| 5 | Neue ungültige Session hinzufügen | Nur die neue wird beim nächsten Start angezeigt |

---

## 13. CLI-Befehle

| # | Befehl | Erwartung |
|---|--------|-----------|
| 1 | `ccsm --version` | `ccsm v1.5.0` |
| 2 | `ccsm -v` | `ccsm v1.5.0` |
| 3 | `ccsm --help` | Hilfetext mit Usage + Configuration |
| 4 | `ccsm -h` | Gleich wie --help |
| 5 | `ccsm --search Docker` | Sucht und zeigt Treffer |
| 6 | `ccsm --search nichtvorhanden` | "No matches found" |
| 7 | `ccsm --stats` | Statistiken |
| 8 | `ccsm --cleanup` | Cleanup-Dialog (oder nichts wenn keine alten) |

---

## 14. Sprache / Lokalisierung

| # | Schritt | Erwartung |
|---|---------|-----------|
| 1 | `CCSM_LANG=de ccsm` | Alles auf Deutsch |
| 2 | `CCSM_LANG=en ccsm` | Alles auf Englisch |
| 3 | Alle Menü-Labels | Kein englischer Text in DE-Modus und umgekehrt |
| 4 | Hilfe (`--help`) | Sprache passend zum CCSM_LANG |
| 5 | Bestätigungen | `[j/n]` auf Deutsch, `[y/n]` auf Englisch |

---

## 15. Edge Cases

| # | Test | Erwartung |
|---|------|-----------|
| 1 | ccsm ohne Sessions starten | Leeres Menü, "No saved sessions" bei [s] |
| 2 | Sehr langer Subject (200+ Zeichen) | Wird mit `..` gekürzt in Tabelle |
| 3 | Sonderzeichen im Subject (`äöü`, `&`, `"`) | Korrekt gespeichert und angezeigt |
| 4 | Tabs im Subject | Werden durch Leerzeichen ersetzt |
| 5 | Parallele ccsm-Instanzen | File-Locking verhindert Datenverlust |
| 6 | `~/.claude/ccsm.conf` manuell kaputt machen | Defaults werden verwendet, kein Crash |
| 7 | `~/.claude/session_log.tsv` löschen | Wird automatisch neu erstellt |
| 8 | ccsm in sehr schmalem Terminal (< 60 Spalten) | Mindestbreite greift, kein Crash |
| 9 | Alte Sessions ohne Uhrzeit im Datum | Zeigen `00:01` als Default-Zeit |

---

## 16. Cross-Platform (falls macOS/FreeBSD verfügbar)

| # | Test | Erwartung |
|---|------|-----------|
| 1 | Bash-Version-Check mit `/bin/bash` (macOS 3.2) | Fehlermeldung + Hinweis auf brew |
| 2 | Bash-Version mit brew-bash (5.x) | ccsm startet normal |
| 3 | `_tac` Fallback | Sessions in umgekehrter Reihenfolge (via `tail -r`) |
| 4 | `days_since` mit BSD date | Cleanup-Alter korrekt berechnet |
| 5 | `with_lock` mkdir-Fallback | Parallele Sessions sicher |
| 6 | `sed` ANSI-Stripping | Box-Rahmen korrekt ausgerichtet |
| 7 | Kompletter Flow | Menü → Session → Save → Resume → Delete |

---

## Testergebnis-Vorlage

```
Datum:       ____-__-__
Tester:      ____________
ccsm Version: ____________
OS:          ____________
Bash:        ____________
Terminal:    ____________

Abschnitt 1:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 2:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 3:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 4:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 5:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 6:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 7:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 8:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 9:  [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 10: [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 11: [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 12: [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 13: [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 14: [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 15: [ ] OK  [ ] FAIL  Notizen: ___
Abschnitt 16: [ ] OK  [ ] FAIL  Notizen: ___
```

# Changelog

## [1.6.0] - 2026-03-22

### Added
- **Settings menu** `[c]` — Language, cleanup days, log retention configurable from TUI
- **Activity Log** `[l]` — Color-coded log viewer (NEW, RESUME, SAVE, DELETE, CLEANUP, SETTINGS)
- **Log rotation** — Configurable retention (default 90 days, `LOG_DAYS` setting)
- **Date + time** — Sessions now store `YYYY-MM-DD HH:MM` (legacy entries show `00:01`)
- **Session validation** — Checks if sessions still exist at Claude Code (JSONL in `~/.claude/projects/`)
- **Status markers** in all tables: `[!]` red = expired at Claude Code, `[?]` amber = directory missing
- **Legend** — Shown below tables only when marked sessions exist
- **Startup check** — Detects invalid sessions, lists details, offers auto-purge or dismiss
- **Dismissed list** — Previously dismissed invalid sessions are not asked again
- **Resume: dir missing** — Options: recreate directory, delete session, or cancel
- **Resume: session expired** — Options: start new session (same subject+dir), delete, or keep
- **"No conversation found" detection** — Catches Claude Code's error and offers recovery options
- **Installer update detection** — Skips language selection, shows restart hint
- **Manual test plan** — `test/MANUAL_TESTPLAN.md` with 100+ test points
- **12 new automated tests** (total: 104) — ccsm_log, _rotate_log, _save_config, lookup_sid, days_since with time

### Changed
- Resumed sessions move to end of TSV (appear at top of "recent" list)
- `is_session_valid` results are cached (`_VALID_CACHE`) for performance
- `ask_path` simplified to alias for `ask_input` (tab completion was removed in v1.5.0)
- `_do_expired_delete` deduplicated (was copy-pasted twice)
- Claude output captured via temp file instead of RAM variable
- `sed -i` replaced with portable `grep + mv` for macOS compatibility
- ANSWER input sanitized (`tr -d '\r'`) to fix stty sane artifacts
- Status markers unified to ASCII `[!]`/`[?]` (Unicode symbols caused column misalignment)
- Help text updated: `MAX_SESSIONS` replaced with `LOG_DAYS`

### Removed
- Unused translations: `err_no_dir`, `expired_mark`
- Dead code: duplicate `row_color` assignment
- `MAX_SESSIONS` references in help text

## [1.5.0] - 2026-03-21

### Added
- **Cross-platform support** — runs on Linux, macOS, and FreeBSD
- **Bash 4+ version check** — clear error message on unsupported systems (e.g. macOS default bash 3.2)
- **OS detection** (`CCSM_OS`) with platform-specific wrappers for `tac`, `date`, `flock`
- **Interactive language selection** during installation (German prompt for `de*` locales, English default, unsupported locale warning)
- **Dependency report** — installer checks all dependencies first, lists missing ones with install hints per OS, asks to continue
- **File locking** (`flock` on Linux, `mkdir`-based fallback on macOS/FreeBSD) prevents data loss with parallel sessions
- **Session lookup** via `awk` (`lookup_sid`) instead of `grep` — safe against regex injection from session IDs
- **Cancel path input** — press `q` or Enter to abort directory selection when starting a new session
- **Token tracking** — lifetime token counter (survives session deletion), per-session input/output tokens with visual bars
- **`save_current_subject`** translation key (was missing)
- **`cleanup_select_prompt`** translation key for cleanup dialog
- **92 automated tests** (bats) including cross-platform wrapper tests
- **GitHub Actions CI** — automated tests on Linux and macOS

### Changed
- **Shebang** changed from `#!/bin/bash` to `#!/usr/bin/env bash` (all scripts)
- **Config loading** — safe parser instead of `source` (only `CLEANUP_DAYS` and `CCSM_LANG` allowed)
- **Token formatting** — pure bash arithmetic, `bc` dependency removed
- **Search** uses `grep -qiF` (fixed string match, no regex injection)
- **Delete confirmation** uses locale-aware `ask_yn` + `is_yes` instead of hardcoded y/j
- **`cd` after session** — returns to original directory after each session ends
- **`stty sane`** after `read -n 1` in `ask_yn` for terminal state recovery
- **BSD sed compatibility** — `\x1b` replaced with `$'\033'` for ANSI stripping
- **`TMPDIR`** renamed to `CCSM_TMPDIR` to avoid conflicts with system variable
- **Hook** now checks for `jq` and `python3` before running, logs errors to stderr
- **All UI strings** now use translation keys (cleanup dialog, delete page, stats "Back" label)
- **Installer** shows cross-platform install hints (pacman/apt/brew/pkg)

### Removed
- **`gum` dependency** — was defined but never actually used; entire UI is echo/read based
- **`fzf` references** — was listed as optional but never called in code
- **`bc` dependency** — replaced with pure bash arithmetic
- **`MAX_SESSIONS` config option** — was never implemented
- **Dead code** — `build_choice_rows()`, unused translation keys, dialog fallback stub
- **`C_WARN`/`A_WARN`** — unified to `A_AMBER`
- **Hex color constants** (`C_PRIMARY`, `C_SECONDARY`, etc.) — only used for removed GUM exports

## [1.0.0] - 2026-03-20

### Added
- Interactive TUI menu with ASCII art
- Session save/resume with auto-cd to working directory
- Subject suggestions from conversation transcript
- Quick resume from menu
- Tag support (#infra, #webapp, etc.)
- Auto-cleanup of old sessions (configurable)
- Statistics (top directories, top tags)
- Search (--search flag and interactive)
- Zsh tab completion
- install.sh and uninstall.sh
- SessionEnd hook with per-session temp files (parallel session safe)

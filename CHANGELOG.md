# Changelog

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

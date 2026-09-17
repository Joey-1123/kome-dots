#!/usr/bin/env bash
# kome installer — shared helpers, logging, and dry-run-aware execution.
# Sourced by install/main.sh; not executable on its own.

set -euo pipefail

# --- resolved paths ----------------------------------------------------------
KOME_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
KOME_CONFIG_SRC="${KOME_ROOT}/config"
KOME_STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kome"
KOME_PROVIDERS_FILE="${KOME_STATE_DIR}/providers.env"
KOME_STATE_FILE="${KOME_STATE_DIR}/state.env"
KOME_BIN_DIR="${HOME}/.local/bin"
KOME_BACKUP_ROOT="${KOME_STATE_DIR}/backups"

# --- run options (overridden by main.sh argument parsing) --------------------
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
KOME_PROFILE="${KOME_PROFILE:-standard}"
KOME_SHELL_CHOICE="${KOME_SHELL_CHOICE:-bash}"

# --- colors ------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
    C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'
    C_BLU=$'\033[34m'; C_DIM=$'\033[2m'
else
    C_RESET=""; C_BOLD=""; C_RED=""; C_GRN=""; C_YLW=""; C_BLU=""; C_DIM=""
fi

log()   { printf '%s\n' "${C_BLU}::${C_RESET} $*"; }
ok()    { printf '%s\n' "${C_GRN}ok${C_RESET}: $*"; }
warn()  { printf '%s\n' "${C_YLW}warn${C_RESET}: $*" >&2; }
err()   { printf '%s\n' "${C_RED}error${C_RESET}: $*" >&2; }
die()   { err "$*"; exit 1; }
section() { printf '\n%s\n' "${C_BOLD}== $* ==${C_RESET}"; }

# --- guards ------------------------------------------------------------------
need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# run <cmd...> — honors DRY_RUN.
run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s\n' "${C_DIM}[dry-run]${C_RESET} $*"
        return 0
    fi
    "$@"
}

# run_sh <string> — run a shell string, honoring DRY_RUN.
run_sh() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s\n' "${C_DIM}[dry-run]${C_RESET} $1"
        return 0
    fi
    bash -c "$1"
}

have_sudo() { [[ "$(id -u)" -eq 0 ]] || command -v sudo >/dev/null 2>&1; }

# root_run <cmd...> — run with sudo when not already root.
root_run() {
    if [[ "$(id -u)" -eq 0 ]]; then
        run "$@"
    elif command -v sudo >/dev/null 2>&1; then
        run sudo "$@"
    else
        die "need root for: $* (install sudo or run as root)"
    fi
}

# --- state helpers -----------------------------------------------------------
read_providers() {
    [[ -f "$KOME_PROVIDERS_FILE" ]] || return 1
    # shellcheck disable=SC1090
    source "$KOME_PROVIDERS_FILE"
}

provider_of() {
    local component="$1" var
    var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
    printf '%s' "${!var:-}"
}

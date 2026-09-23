#!/usr/bin/env bash
# kome installer — backup of existing configuration.
# Sourced by install/main.sh.

# Sets up the timestamped backup directory.
backup_init() {
    KOME_BACKUP_DIR="${KOME_BACKUP_ROOT}/$(date +%Y%m%d-%H%M%S)"
    KOME_MANIFEST="${KOME_BACKUP_DIR}/manifest"
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s\n' "${C_DIM}[dry-run]${C_RESET} mkdir -p $KOME_BACKUP_DIR"
        return 0
    fi
    mkdir -p "$KOME_BACKUP_DIR"
    : >"$KOME_MANIFEST"
    ok "backups will be written to $KOME_BACKUP_DIR"
}

# record_manifest <line> — append to the manifest (real runs only).
record_manifest() {
    [[ "${DRY_RUN:-0}" == "1" ]] && return 0
    [[ -n "${KOME_MANIFEST:-}" ]] || return 0
    printf '%s\n' "$1" >>"$KOME_MANIFEST"
}

# backup_target <absolute-path> — move an existing path into the backup dir,
# preserving its location relative to $HOME. No-op when the path is already a
# symlink into this repository.
backup_target() {
    local target="$1" rel dest
    [[ -e "$target" || -L "$target" ]] || return 0

    if [[ -L "$target" ]]; then
        local resolved
        resolved="$(readlink -f "$target" || true)"
        case "$resolved" in
            "$KOME_ROOT"/*) return 0 ;;
        esac
    fi

    rel="${target#"$HOME"/}"
    dest="${KOME_BACKUP_DIR}/${rel}"
    run mkdir -p "$(dirname "$dest")"
    run mv "$target" "$dest"
    record_manifest "M ${rel}"
    log "backed up ${target} -> ${dest}"
}

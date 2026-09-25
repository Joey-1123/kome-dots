#!/usr/bin/env bash
# kome installer — orchestration. Run via ./install.sh.

_MAIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_MAIN_DIR}/lib/common.sh"
# shellcheck source=lib/ui.sh
source "${_MAIN_DIR}/lib/ui.sh"
# shellcheck source=lib/detect.sh
source "${_MAIN_DIR}/lib/detect.sh"
# shellcheck source=lib/providers.sh
source "${_MAIN_DIR}/lib/providers.sh"
# shellcheck source=lib/packages.sh
source "${_MAIN_DIR}/lib/packages.sh"
# shellcheck source=lib/backup.sh
source "${_MAIN_DIR}/lib/backup.sh"
# shellcheck source=lib/link.sh
source "${_MAIN_DIR}/lib/link.sh"
# shellcheck source=lib/system.sh
source "${_MAIN_DIR}/lib/system.sh"

SKIP_SYSTEM=0
DAILY_PROMPT=0
PROFILE_EXPLICIT=0
SHELL_EXPLICIT=0

usage() {
    cat <<'EOF'
kome installer

Usage: ./install.sh [options]

Options:
  -p, --profile <minimal|standard|full>   Package profile (default: standard)
  -s, --shell <bash|zsh|fish>             Login shell to configure (default: bash)
      --dry-run                           Print actions without changing anything
  -y, --yes                               Accept defaults, no prompts
      --no-profile-prompt                 Use the default profile without asking
      --skip-system                       Skip optional system integration steps
  -h, --help                              Show this help

The interactive flow lets you pick a provider for each component (bar, lock,
idle, wallpaper, notifications, launcher, OSD, screenshot, clipboard, file
manager). Defaults are the kome defaults; alternatives are offered too.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)        KOME_PROFILE="$2"; PROFILE_EXPLICIT=1; shift 2 ;;
            -s|--shell)          KOME_SHELL_CHOICE="$2"; SHELL_EXPLICIT=1; shift 2 ;;
            --dry-run)           DRY_RUN=1; shift ;;
            -y|--yes)            ASSUME_YES=1; shift ;;
            --no-profile-prompt) DAILY_PROMPT=1; shift ;;
            --skip-system)       SKIP_SYSTEM=1; shift ;;
            -h|--help)           usage; exit 0 ;;
            *)                   die "unknown option: $1 (try --help)" ;;
        esac
    done
    case "$KOME_PROFILE" in
        minimal|standard|full) ;;
        *) die "invalid profile: $KOME_PROFILE" ;;
    esac
    case "$KOME_SHELL_CHOICE" in
        bash|zsh|fish) ;;
        *) die "invalid shell: $KOME_SHELL_CHOICE" ;;
    esac
}

choose_profile() {
    if [[ "$PROFILE_EXPLICIT" == "1" || "$DAILY_PROMPT" == "1" || "$ASSUME_YES" == "1" ]]; then return 0; fi
    local choice
    choice="$(ui_choose "Package profile" minimal standard full)"
    KOME_PROFILE="${choice:-standard}"
}

choose_shell() {
    if [[ "$SHELL_EXPLICIT" == "1" || "$ASSUME_YES" == "1" ]]; then return 0; fi
    local choice
    choice="$(ui_choose "Login shell to configure" bash zsh fish)"
    KOME_SHELL_CHOICE="${choice:-bash}"
}

choose_providers() {
    local component
    for component in "${KOME_COMPONENTS[@]}"; do
        local var
        var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
        # Respect pre-set env (e.g. KOME_BAR=quickshell) — don't clobber.
        if [[ -n "${!var:-}" ]]; then continue; fi
        local -a options
        read -r -a options <<<"$(providers_for "$component")"
        local label choice
        label="$(kome_component_label "$component")"
        choice="$(ui_choose "Choose $label" "${options[@]}")"
        choice="${choice:-${options[0]}}"
        printf -v "$var" '%s' "$choice"
        export "${var?}"
    done
}

# init_provider_defaults — fill any unset KOME_<COMPONENT> with the default.
init_provider_defaults() {
    local component var
    for component in "${KOME_COMPONENTS[@]}"; do
        var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
        if [[ -z "${!var:-}" ]]; then
            printf -v "$var" '%s' "$(provider_default "$component")"
            export "${var?}"
        fi
    done
}

summarize() {
    section "Plan"
    log "profile : ${KOME_PROFILE}"
    log "shell   : ${KOME_SHELL_CHOICE}"
    local component var
    for component in "${KOME_COMPONENTS[@]}"; do
        var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
        log "$(printf '%-14s' "$(kome_component_label "$component")"): ${!var}"
    done
    if [[ "$DRY_RUN" == "1" ]]; then warn "dry-run: no changes will be made"; fi
}

main() {
    parse_args "$@"

    section "Environment"
    detect_distro
    if [[ "$DRY_RUN" != "1" ]]; then
        assert_arch_family
    fi
    print_environment

    choose_profile
    choose_shell
    choose_providers
    init_provider_defaults
    summarize

    if [[ "$DRY_RUN" == "1" ]]; then
        warn "dry-run: skipping confirmation, previewing actions"
    elif ! ui_confirm "Proceed with installation?" yes; then
        die "aborted by user"
    fi

    section "Packages"
    local -a official=()
    mapfile -t official < <(profile_packages; shell_packages; provider_packages_all)
    if [[ ${#official[@]} -gt 0 ]]; then
        mapfile -t official < <(
            printf '%s\n' "${official[@]}" | tr ' ' '\n' | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++'
        )
    fi
    install_official "${official[@]}"

    local -a aur=()
    mapfile -t aur < <(provider_aur_packages_all | tr ' ' '\n' | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++')
    install_aur "${aur[@]}"

    section "Configuration"
    ensure_user_dirs
    backup_init
    write_providers_file
    link_selected

    section "Theme"
    seed_theme

    section "User services"
    enable_user_services

    if [[ "$SKIP_SYSTEM" != "1" ]]; then
        section "Optional system integration"
        ui_confirm "Install GPU drivers for detected hardware?" no && install_gpu_drivers
        ui_confirm "Enable Plymouth boot splash?" no && setup_plymouth
        ui_confirm "Configure GRUB (splash + regenerate)?" no && setup_grub
        ui_confirm "Install kome system sounds?" no && setup_sounds
        ui_confirm "Set up greetd + tuigreet login?" no && setup_greetd
    fi

    section "Done"
    if [[ "$DRY_RUN" == "1" ]]; then
        ok "dry-run complete"
    else
        ok "kome installed. Log out and back in to start Hyprland."
        log "theme  : kome-theme set dark|light  |  kome-theme toggle"
        log "wall   : kome-wallpaper pick|random|set <file>"
        log "verify : hyprland --verify-config"
        log "backups: ${KOME_BACKUP_DIR}"
    fi
}

main "$@"

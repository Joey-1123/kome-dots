#!/usr/bin/env bash
# kome installer — environment and hardware detection.
# Sourced by install/main.sh.

# Populates KOME_DISTRO, KOME_DISTRO_LIKE, KOME_DISTRO_NAME.
detect_distro() {
    KOME_DISTRO="unknown"
    KOME_DISTRO_LIKE=""
    KOME_DISTRO_NAME="unknown"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        KOME_DISTRO="${ID:-unknown}"
        KOME_DISTRO_LIKE="${ID_LIKE:-}"
        KOME_DISTRO_NAME="${PRETTY_NAME:-$KOME_DISTRO}"
    fi
}

is_arch_family() {
    [[ "$KOME_DISTRO" == "arch" ]] && return 0
    [[ -f /etc/arch-release ]] && return 0
    [[ " $KOME_DISTRO_LIKE " == *" arch "* ]] && return 0
    [[ "$KOME_DISTRO" =~ ^(cachyos|endeavouros|manjaro|garuda|artix)$ ]] && return 0
    return 1
}

assert_arch_family() {
    is_arch_family || die "unsupported distribution: ${KOME_DISTRO_NAME}. kome targets Arch and Arch-based systems."
}

# detect_aur_helper — prints yay, paru, or an empty string.
detect_aur_helper() {
    local helper
    for helper in yay paru; do
        if command -v "$helper" >/dev/null 2>&1; then
            printf '%s' "$helper"
            return 0
        fi
    done
    printf ''
}

# detect_gpu — prints a space-separated vendor list from lspci/other sources.
detect_gpu() {
    local out="" line
    if command -v lspci >/dev/null 2>&1; then
        while IFS= read -r line; do
            case "$line" in
                *NVIDIA*|*nvidia*) out="$out nvidia" ;;
                *Advanced\ Micro\ Devices*|*AMD*|*Radeon*) out="$out amd" ;;
                *Intel*) out="$out intel" ;;
            esac
        done < <(lspci 2>/dev/null | grep -Ei 'vga|3d|display')
    fi
    # remove duplicates, keep stable order
    printf '%s\n' $out | awk '!seen[$0]++' | paste -sd' ' -
}

detect_virt() {
    local v=""
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        v="$(systemd-detect-virt 2>/dev/null || true)"
    fi
    printf '%s' "${v:-none}"
}

is_uefi() { [[ -d /sys/firmware/efi ]]; }

has_battery() {
    compgen -G '/sys/class/power_supply/BAT*' >/dev/null 2>&1
}

# print a compact environment summary
print_environment() {
    local gpu
    gpu="$(detect_gpu)"
    log "distro : ${KOME_DISTRO_NAME} (${KOME_DISTRO})"
    log "gpu    : ${gpu:-unknown}"
    log "virt   : $(detect_virt)"
    log "firmware: $(is_uefi && echo uefi || echo bios)"
    log "aur    : $(detect_aur_helper || true)"
}

#!/usr/bin/env bash
# kome installer — package resolution and installation.
# Sourced by install/main.sh.

# read_package_list <file> — prints package names, stripping comments/blanks.
read_package_list() {
    local file="$1"
    [[ -r "$file" ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]\+/ /g' -e '/^[[:space:]]*$/d' "$file"
}

# profile_packages — base + selected profile.
profile_packages() {
    read_package_list "${KOME_ROOT}/profiles/base.txt"
    read_package_list "${KOME_ROOT}/profiles/${KOME_PROFILE}.txt"
}

# shell_packages — extra packages for the chosen shell.
shell_packages() {
    case "$KOME_SHELL_CHOICE" in
        zsh)  echo "zsh zsh-completions" ;;
        fish) echo "fish" ;;
        *)    echo "" ;;
    esac
}

# provider_packages_all — official packages for every selected provider.
provider_packages_all() {
    local component
    for component in "${KOME_COMPONENTS[@]}"; do
        local var provider
        var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
        provider="${!var:-}"
        [[ -n "$provider" ]] || continue
        provider_packages "$component" "$provider"
    done
}

provider_aur_packages_all() {
    local component
    for component in "${KOME_COMPONENTS[@]}"; do
        local var provider
        var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
        provider="${!var:-}"
        [[ -n "$provider" ]] || continue
        provider_aur_packages "$component" "$provider"
    done
}

# missing_official <pkg...> — prints the subset not installed.
missing_official() {
    [[ $# -gt 0 ]] || return 0
    pacman -T "$@" 2>/dev/null || true
}

# install_official <pkg...> — accepts space- or newline-separated names.
install_official() {
    local -a wanted=() split=() p
    for p in "$@"; do
        read -r -a split <<<"$p"
        wanted+=("${split[@]}")
    done
    [[ ${#wanted[@]} -gt 0 ]] || return 0

    local -a pkgs=()
    mapfile -t pkgs < <(missing_official "${wanted[@]}")
    [[ ${#pkgs[@]} -gt 0 ]] || { ok "official packages already installed"; return 0; }
    log "installing ${#pkgs[@]} official package(s): ${pkgs[*]}"
    root_run pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_aur() {
    local -a wanted=() split=() p
    for p in "$@"; do
        read -r -a split <<<"$p"
        wanted+=("${split[@]}")
    done
    [[ ${#wanted[@]} -gt 0 ]] || return 0
    local helper
    helper="$(detect_aur_helper)"
    if [[ -z "$helper" ]]; then
        warn "no AUR helper (yay/paru) found; skipping AUR packages: ${wanted[*]}"
        warn "install yay or paru and re-run, or install them manually."
        return 0
    fi
    log "installing ${#wanted[@]} AUR package(s) via ${helper}: ${wanted[*]}"
    run "$helper" -S --needed --noconfirm "${wanted[@]}"
}

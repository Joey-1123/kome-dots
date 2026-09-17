#!/usr/bin/env bash
# kome installer — optional system integration (opt-in steps).
# Sourced by install/main.sh.

ensure_user_dirs() {
    run mkdir -p "$KOME_STATE_DIR"
    run mkdir -p "${HOME}/.local/state/kome"
    run mkdir -p "${HOME}/.local/bin"
    run mkdir -p "${HOME}/Pictures/Wallpapers"
}

enable_user_services() {
    if ! command -v systemctl >/dev/null 2>&1; then
        warn "systemctl not found; skipping user services"
        return 0
    fi
    local unit
    for unit in pipewire pipewire-pulse wireplumber; do
        run systemctl --user enable --now "$unit" || warn "could not enable $unit"
    done
}

# install_gpu_drivers — opt-in only. Proposes vendor-appropriate packages.
install_gpu_drivers() {
    local gpu
    gpu="$(detect_gpu)"
    [[ -n "$gpu" ]] || { warn "no GPU detected; skipping"; return 0; }

    local -a pkgs=()
    case " $gpu " in
        *" intel "*) pkgs+=(mesa vulkan-intel intel-media-driver) ;;
        *" amd "*)   pkgs+=(mesa vulkan-radeon libva-mesa-driver mesa-vdpau) ;;
        *" nvidia "*)
            ui_msg "NVIDIA detected. Choose one driver: nvidia-open-dkms (Turing+, recommended) or nvidia-dkms (older GPUs)."
            if ui_confirm "Install nvidia-open-dkms + utils?" no; then
                pkgs+=(nvidia-open-dkms nvidia-utils libva-nvidia-driver nvidia-settings)
            elif ui_confirm "Install nvidia-dkms (legacy) + utils?" no; then
                pkgs+=(nvidia-dkms nvidia-utils libva-nvidia-driver nvidia-settings)
            else
                warn "skipped NVIDIA driver install"
                return 0
            fi
            ;;
    esac
    [[ ${#pkgs[@]} -gt 0 ]] || return 0
    install_official "${pkgs[@]}"
    ui_msg "Hyprland works best with NVIDIA env vars. If needed, add them to modules/local.lua (see README)."
}

setup_plymouth() {
    install_official plymouth
    if [[ -f "${KOME_CONFIG_SRC}/plymouth/kome.plymouth" ]]; then
        root_run install -Dm644 "${KOME_CONFIG_SRC}/plymouth/kome.plymouth" /usr/share/plymouth/themes/kome/kome.plymouth
        root_run plymouth-set-default-theme -R kome
    else
        root_run plymouth-set-default-theme -R spinner
    fi
    if [[ -f /etc/mkinitcpio.conf ]] && ! grep -q '\bplymouth\b' /etc/mkinitcpio.conf; then
        run_root_sh "sed -i 's/^HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf"
        root_run mkinitcpio -P
    fi
}

setup_grub() {
    [[ -f /etc/default/grub ]] || { warn "GRUB config not found; skipping"; return 0; }
    if ui_confirm "Add 'splash' to the kernel command line for Plymouth?" yes; then
        run_root_sh "grep -q 'splash' /etc/default/grub || sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 splash\"/' /etc/default/grub"
        root_run grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

setup_sounds() {
    local theme_src="${KOME_CONFIG_SRC}/sounds"
    [[ -d "$theme_src" ]] || { warn "no bundled sounds; skipping"; return 0; }
    run mkdir -p "${HOME}/.local/share/sounds/kome"
    run cp -r "${theme_src}/." "${HOME}/.local/share/sounds/kome/"
    ok "installed kome system sounds"
}

setup_greetd() {
    install_official greetd greetd-tuigreet
    if [[ -f "${KOME_CONFIG_SRC}/greetd/config.toml" ]]; then
        root_run install -Dm644 "${KOME_CONFIG_SRC}/greetd/config.toml" /etc/greetd/config.toml
    fi
    root_run systemctl enable greetd
    ui_msg "greetd enabled. It will take over the login prompt on next boot."
}

# root_write_file <repo-relative-src> <dest> [mode]
root_install_file() {
    local src="$1" dest="$2" mode="${3:-644}"
    [[ -f "$src" ]] || { warn "missing $src"; return 1; }
    if [[ -e "$dest" && "$DRY_RUN" != "1" ]]; then
        run root_run cp -a "$dest" "${dest}.kome.bak"
    fi
    root_run install -Dm"$mode" "$src" "$dest"
}

# run_root_sh <string> — run a shell string as root, honoring DRY_RUN.
run_root_sh() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s\n' "${C_DIM}[dry-run]${C_RESET} (root) $1"
        return 0
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
        bash -c "$1"
    else
        sudo bash -c "$1"
    fi
}

# seed_theme — generate the first palette from a bundled wallpaper.
seed_theme() {
    local mode="dark"
    local wall
    wall="$(find "${KOME_ROOT}/wallpapers/${mode}" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.svg' \) 2>/dev/null | head -1 || true)"
    if [[ -z "$wall" ]]; then
        warn "no bundled wallpaper found; skipping initial theme generation"
        return 0
    fi
    run "${HOME}/.local/bin/kome-theme" set "$mode" --wallpaper "$wall" --no-reload || warn "initial theme generation failed"
}

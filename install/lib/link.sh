#!/usr/bin/env bash
# kome installer — symlinking of selected configuration.
#
# Config is linked per file into real ~/.config/<app> directories. This keeps
# generated theme files (written by matugen into the same dirs) out of the
# repository, and leaves any unrelated user files in place.
# Sourced by install/main.sh.

# link_tree <name> — link every file under config/<name> to ~/.config/<name>,
# preserving the relative layout.
link_tree() {
    local name="$1"
    local src_root="${KOME_CONFIG_SRC}/${name}"
    local dest_root="${XDG_CONFIG_HOME:-$HOME/.config}/${name}"
    [[ -d "$src_root" ]] || return 0

    local src rel dest
    while IFS= read -r -d '' src; do
        rel="${src#"$src_root"/}"
        dest="${dest_root}/${rel}"
        if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            continue
        fi
        backup_target "$dest"
        run mkdir -p "$(dirname "$dest")"
        run ln -sfn "$src" "$dest"
    done < <(find "$src_root" -type f -print0)
    ok "linked ~/.config/$name"
}

# link_scripts — symlink scripts/kome-* into ~/.local/bin.
link_scripts() {
    local script base
    run mkdir -p "$KOME_BIN_DIR"
    for script in "${KOME_ROOT}"/scripts/kome-*; do
        [[ -e "$script" ]] || continue
        base="$(basename "$script")"
        backup_target "${KOME_BIN_DIR}/${base}"
        run ln -sfn "$script" "${KOME_BIN_DIR}/${base}"
    done
    ok "linked kome scripts into ~/.local/bin"
}

# link_shell — link shell dotfiles for the chosen login shell.
# .zshrc lives at $HOME (not ~/.config), so it gets its own step.
link_shell() {
    case "${KOME_SHELL_CHOICE:-bash}" in
        zsh)
            local src="${KOME_CONFIG_SRC}/shell/zshrc" dest="${HOME}/.zshrc"
            [[ -f "$src" ]] || return 0
            backup_target "$dest"
            run ln -sfn "$src" "$dest"
            ok "linked ~/.zshrc"
            ;;
    esac
}

# link_selected — link core config, selected provider config, and scripts.
link_selected() {
    local core=(hypr kitty matugen starship btop cava fastfetch gtk-3.0 gtk-4.0 qt6ct kvantum)
    local name
    for name in "${core[@]}"; do link_tree "$name"; done

    local component var provider configs
    for component in "${KOME_COMPONENTS[@]}"; do
        var="KOME_$(printf '%s' "$component" | tr '[:lower:]' '[:upper:]')"
        provider="${!var:-}"
        [[ -n "$provider" ]] || continue
        while IFS= read -r configs; do
            [[ -n "$configs" ]] && link_tree "$configs"
        done < <(provider_configs "$component" "$provider")
    done

    link_scripts
    link_shell
}

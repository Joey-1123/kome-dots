#!/usr/bin/env bash
# kome installer — UI layer. Prefers gum, falls back to whiptail, then plain
# prompts. Honors ASSUME_YES by returning defaults without prompting.
# Sourced by install/main.sh.

UI_BACKEND="plain"
if [[ -t 0 && -t 1 ]]; then
    if command -v gum >/dev/null 2>&1; then
        UI_BACKEND="gum"
    elif command -v whiptail >/dev/null 2>&1; then
        UI_BACKEND="whiptail"
    fi
fi

ui_backend() { printf '%s' "$UI_BACKEND"; }

# ui_choose <prompt> <option>... — prints the chosen option.
ui_choose() {
    local prompt="$1"; shift
    local -a options=("$@")
    [[ ${#options[@]} -gt 0 ]] || die "ui_choose: no options"

    if [[ "$ASSUME_YES" == "1" || "$UI_BACKEND" == "plain" ]]; then
        printf '%s' "${options[0]}"
        return 0
    fi

    case "$UI_BACKEND" in
        gum)
            gum choose --header "$prompt" --selected "${options[0]}" "${options[@]}"
            ;;
        whiptail)
            local -a args=()
            local i
            for i in "${!options[@]}"; do args+=("$i" "${options[$i]}"); done
            local choice
            choice=$(whiptail --title "kome" --default-item "0" \
                --menu "$prompt" 20 74 10 "${args[@]}" 3>&1 1>&2 2>&3) || return 1
            printf '%s' "${options[$choice]}"
            ;;
    esac
}

# ui_multi <prompt> <option>... — prints chosen options, one per line.
ui_multi() {
    local prompt="$1"; shift
    local -a options=("$@")
    [[ ${#options[@]} -gt 0 ]] || return 0

    if [[ "$ASSUME_YES" == "1" || "$UI_BACKEND" == "plain" ]]; then
        printf '%s\n' "${options[@]}"
        return 0
    fi

    case "$UI_BACKEND" in
        gum)
            gum choose --no-limit --header "$prompt" --selected "${options[0]}" "${options[@]}"
            ;;
        whiptail)
            local -a args=()
            local i
            for i in "${!options[@]}"; do args+=("$i" "${options[$i]}" ON); done
            whiptail --title "kome" --checklist "$prompt" 20 74 10 "${args[@]}" \
                3>&1 1>&2 2>&3 | tr -d '"' | tr ' ' '\n' | while read -r idx; do
                    [[ -n "$idx" ]] && printf '%s\n' "${options[$idx]}"
                done
            ;;
    esac
}

# ui_confirm <prompt> [default:no] — exit status 0 = yes.
ui_confirm() {
    local prompt="$1" default="${2:-no}"
    if [[ "$ASSUME_YES" == "1" ]]; then
        [[ "$default" == "yes" ]]
        return
    fi
    case "$UI_BACKEND" in
        gum)
            if [[ "$default" == "yes" ]]; then
                gum confirm --default=yes "$prompt"
            else
                gum confirm --default=no "$prompt"
            fi
            ;;
        whiptail)
            if [[ "$default" == "yes" ]]; then
                whiptail --title "kome" --defaultyes --yesno "$prompt" 12 74
            else
                whiptail --title "kome" --yesno "$prompt" 12 74
            fi
            ;;
        plain)
            local reply
            read -r -p "$prompt [y/N] " reply
            [[ "$reply" =~ ^[Yy] ]]
            ;;
    esac
}

# ui_input <prompt> [default] — prints the entered value.
ui_input() {
    local prompt="$1" default="${2:-}"
    if [[ "$UI_BACKEND" == "plain" || ! -t 0 ]]; then
        printf '%s' "$default"
        return 0
    fi
    case "$UI_BACKEND" in
        gum) gum input --header "$prompt" --value "$default" ;;
        whiptail) whiptail --title "kome" --inputbox "$prompt" 12 74 "$default" 3>&1 1>&2 2>&3 ;;
    esac
}

ui_msg() {
    if [[ "$ASSUME_YES" == "1" || "$UI_BACKEND" == "plain" ]]; then
        printf '%s\n' "$1"
        return 0
    fi
    case "$UI_BACKEND" in
        gum) gum style --border rounded --padding "0 1" "$1" ;;
        whiptail) whiptail --title "kome" --msgbox "$1" 20 74 ;;
    esac
}

# ui_spin <title> <cmd...> — run cmd with a spinner when supported, else plain.
ui_spin() {
    local title="$1"; shift
    if [[ "$DRY_RUN" == "1" || "$UI_BACKEND" != "gum" ]]; then
        log "$title"
        "$@"
        return
    fi
    gum spin --spinner dot --title "$title" -- "$@"
}

# Plan: `kome` Hyprland rice

Ticket: thoughts/tickets/feature_hyprland_rice.md
Research: thoughts/research/2026-09-17_hyprland_lua_kome.md

## Architecture

```
rice/                                (~/.config symlink source)
├── install.sh                       entry point
├── install/
│   ├── main.sh                      orchestration
│   └── lib/{common,ui,detect,providers,packages,backup,link,system}.sh
├── profiles/{minimal,standard,full}.txt
├── config/                          symlinked selectively into ~/.config
│   ├── hypr/  hyprland.lua + modules/*.lua + providers/{hyprlock,hypridle,hyprpaper}
│   ├── waybar/ rofi/ kitty/ swaync/ mako/ dunst/ wofi/ fuzzel/ yazi/
│   ├── matugen/config.toml + templates/
│   ├── gtk-3.0/ gtk-4.0/ qt6ct/ kvantum/
│   └── kome/                        (installed state lives in ~/.config/kome)
├── scripts/                         installed to ~/.local/bin as kome-*
├── wallpapers/{dark,light}/
├── tests/{verify-config.sh,lint.sh,vm/}
└── .github/workflows/ci.yml
```

## Provider system

`install/lib/providers.sh` holds the registry: for each component, a default
and alternatives, each with official packages, AUR packages, config dirs, and
the command scripts use to reload or act. The installer prompts per component
(default preselected, `--yes` accepts defaults), installs only the chosen
packages, symlinks only the chosen config dirs, and writes
`~/.config/kome/providers.env`. Runtime scripts source that file and dispatch.

## Hyprland Lua layout

- `hyprland.lua` sets `mainMod`, requires modules in order, and does
  `pcall(require, "modules.local")` last.
- `modules/`: `env`, `monitors` (wildcard + optional `monitors.local`),
  `look`, `animations`, `input`, `binds`, `rules`, `autostart`.
- Themed values (colors) are read from generated Lua
  (`~/.config/hypr/theme/colors.lua`) written by matugen so reload picks up
  new colors without touching tracked files.

## Theming pipeline

`kome-theme` sets mode + wallpaper, runs `matugen image ... --mode`, which
regenerates waybar/rofi/kitty/swaync/hypr/gtk/qt, then reloads each.
Mechanisms: keybind toggle, systemd user timer (scheduled), per-wallpaper
mode (wallpapers/dark, wallpapers/light), CLI set, static presets.

## Phases

- Ph0 scaffold + CI + profiles.
- Ph1 installer core (dry-run, idempotent, backup, symlink, provider prompt).
- Ph2 Hyprland Lua core.
- Ph3 companion configs incl. alternatives.
- Ph4 matugen + `kome-{theme,wallpaper,mode}`.
- Ph5 system theming + opt-in Plymouth/GRUB/sounds.
- Ph6 greetd/tuigreet opt-in.
- Ph7 tests (verify-config matrix, shellcheck, VM) + docs.

## Risks

- 0.56 Lua is young; verify every key with `hyprland --verify-config`.
- Provider matrix multiplies config surface → keep each provider's config dir
  self-contained and verify each in CI.
- No sudo/root in this environment → the installer's system steps are written
  but cannot be executed here; syntax-checked and dry-run verified instead.

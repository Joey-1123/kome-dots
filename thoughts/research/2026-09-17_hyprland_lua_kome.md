# Research: Hyprland Lua config, matugen, and providers (2026)

Date: 2026-09-17
Ticket: thoughts/tickets/feature_hyprland_rice.md
Verified on: local Arch box, Hyprland 0.56.2

## 1. Hyprland config is Lua (since 0.55)

- Config file: `~/.config/hypr/hyprland.lua`. Legacy `hyprland.conf` /
  hyprlang is deprecated and slated for removal.
- Global `hl` table. Entry point runs as a Lua 5.4 script.
- `require("modules.foo")` splits config; the config watcher tracks required
  modules so live reload works across files.
- `hl.config({ general = {...}, decoration = {...}, input = {...}, ... })`
  nested tables mirror the 0.54 groups. Colors support gradients:
  `col = { active_border = { colors = {"rgba(...)", "rgba(...)"}, angle = 45 },
  inactive_border = "rgba(...)" }`.
- `hl.monitor({ output = "", mode = "preferred", position = "auto",
  scale = "auto" })`. `output = ""` is the wildcard → hardware-agnostic.
- `hl.env(name, value, dbus?)`.
- `hl.bind("SUPER + Q", hl.dsp.window.close(), { flags })`.
  Dispatchers exposed under `hl.dsp.*` (`hl.dsp.exec_cmd`, `hl.dsp.window.close`,
  `hl.dsp.window.float({ action = "toggle" })`, `hl.dsp.layout("togglesplit")`,
  `hl.dsp.exit()`, ...). `hl.bind` returns a handle with `:set_enabled(bool)`.
- `hl.window_rule({ match = { class = "..." }, ... })`,
  `hl.workspace_rule(...)`, `hl.layer_rule(...)`,
  `hl.device({ name = ..., ... })`, `hl.gesture(...)`.
- Autostart: `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` runs
  once at boot and survives reload (preferred over `exec-once` semantics).
- `hyprland --verify-config` (`--verify-config`) validates a config without
  starting the Wayland server → usable in CI and headless. Confirmed on
  0.56.2 (`hyprland --help` lists `--config FILE` and `--verify-config`).
- Moved/renamed keys to watch: `misc.vfr` → `debug.vfr`,
  `misc.no_direct_scanout` → `render.direct_scanout` (inverted, 0/1/2),
  `general.no_cursor_warps` → `cursor.no_warps`.
- uwsm is no longer recommended (experimental). Without uwsm, env vars go in
  `hl.env()`, not uwsm env files.

## 2. matugen (dynamic theming)

- Package in Arch **extra** (`sudo pacman -S matugen`), v4.x.
- `matugen image <path> --mode light|dark|amoled` generates colors from a
  wallpaper. `config.toml` maps `[templates]` source/dest pairs, and each
  template block supports its own `mode` (per-template light/dark) and
  `input_path`.
- Common consumer set: waybar, rofi, kitty, swaync, hyprland borders,
  GTK3/GTK4, qt6ct/kvantum, hyprlock.
- Reference template packs: `InioX/matugen-themes`.

## 3. Package availability (verified via `pacman -Si`, Arch extra)

extra: hyprland, waybar, rofi 2.0 (Wayland-capable), wofi, fuzzel, quickshell,
swaync, mako, dunst, hyprlock, hypridle, hyprpaper, awww, swayosd, hyprshot,
swaylock, swayidle, yazi, grim, slurp, wl-clipboard, cliphist, kitty,
polkit-gnome, xdg-desktop-portal-hyprland, matugen, nwg-look, qt6ct, kvantum,
papirus-icon-theme, ttf-jetbrains-mono-nerd, pipewire, wireplumber,
network-manager-applet, blueman, brightnessctl, playerctl, plymouth,
grub-btrfs, starship, zsh, fish, eza, bat, fd, ripgrep, fzf, zoxide,
gnome-keyring.

AUR only: bibata-cursor-theme, (some cursor/icon variants).

Note: `rofi-wayland` is **not** a separate package now; `rofi` (2.0.0)
supports Wayland. Use `rofi`.

## 4. Provider alternatives (from approval)

Default chosen, alternatives retained:

| component     | default   | alternatives      |
|---------------|-----------|-------------------|
| bar           | waybar    | quickshell        |
| lock          | hyprlock  | swaylock          |
| idle          | hypridle  | swayidle          |
| wallpaper     | hyprpaper | awww              |
| notifications | swaync    | mako, dunst       |
| launcher      | rofi      | wofi, fuzzel      |
| osd           | swayosd   | none              |
| screenshot    | grim      | hyprshot          |
| clipboard     | cliphist  | none              |
| file manager  | yazi      | thunar            |

Scripts dispatch on the recorded provider (`~/.config/kome/providers.env`).

## 5. Verification strategy on a real Arch box

- `hyprland --verify-config -c config/hypr/hyprland.lua` for syntax.
- Config matrix: verify each provider's config variant loads (where the
  provider is a Hyprland-adjacent config, e.g. hyprlock/hypridle/hyprpaper).
- shellcheck (install during dev) for installer + scripts.
- VM harness retained for clean-install testing: Arch cloud image qcow2
  (`geo.mirror.pkgbuild.com/images/latest/`) + cloud-init seed, QEMU
  `-enable-kvm -nographic`, SSH `hostfwd=tcp::2222-:22`.

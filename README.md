# kome

A hardware-agnostic Hyprland rice for Arch Linux and Arch-based distributions (CachyOS, EndeavourOS, Manjaro).

Clean, minimal, with dynamic light/dark theming via matugen.

```
kome/
├── config/              # ~/.config symlink source
│   ├── hypr/            # Hyprland Lua config + modules (hyprlock, hypridle, hyprpaper)
│   ├── waybar/          # Status bar (default)
│   ├── quickshell/      # Wallpaper picker + volume OSD (alternative)
│   ├── rofi/            # Launcher (default)
│   ├── wofi/            # Alternative launcher
│   ├── fuzzel/          # Alternative launcher
│   ├── swaync/          # Notifications (default)
│   ├── mako/            # Alternative notifications
│   ├── dunst/           # Alternative notifications
│   ├── kitty/           # Terminal
│   ├── yazi/            # File manager (default)
│   ├── wlogout/         # Logout menu
│   ├── btop/            # System monitor
│   ├── cava/            # Audio visualizer
│   ├── fastfetch/       # System info
│   ├── shell/           # zshrc (links to ~/.zshrc)
│   ├── starship/        # Prompt
│   ├── matugen/         # Theming engine + templates
│   ├── gtk-3.0/         # GTK3 theming
│   ├── gtk-4.0/         # GTK4 theming
│   ├── qt6ct/           # Qt6 theming
│   ├── kvantum/         # Kvantum theme
│   └── greetd/          # Greetd config (opt-in)
├── install.sh           # Entry point
├── install/
│   ├── main.sh          # Orchestration
│   └── lib/*.sh         # Shared modules
├── scripts/             # ~/.local/bin/kome-*
│   ├── kome-session     # Session daemons
│   ├── kome-theme       # Theme manager
│   ├── kome-wallpaper   # Wallpaper picker
│   ├── kome-lock        # Lock screen
│   ├── kome-powermenu   # Power menu
│   ├── kome-bar         # Bar toggle
│   ├── kome-screenshot  # Screenshots
│   ├── kome-record      # Screen recording
│   ├── kome-clipboard   # Clipboard history
│   ├── kome-opacity     # Window opacity toggle
│   ├── kome-gammastep   # Night light toggle
│   ├── kome-mpris-marquee # Waybar media ticker
│   ├── kome-active-player # Media player detection
│   ├── kome-now-playing # Lock-screen media info
│   ├── kome-password-cursor # Lock-screen cursor blink
│   ├── kome-files       # File manager
│   ├── kome-osd         # Volume/brightness OSD
│   ├── kome-doctor      # Diagnostics
│   ├── kome-notify      # Test notification
│   └── kome-browser     # Default browser
├── wallpapers/          # Starter placeholders (dark/light) — drop your own in
├── profiles/            # Package profiles (minimal/standard/full)
└── tests/               # Lint, verify, VM harness
```

## Features

- **Lua-native Hyprland 0.56+** — `hyprland.lua` with modular `modules/*.lua`, `hl.*` API, `hyprland --verify-config` support
- **Provider alternatives** — Swap components at install: bar (waybar/quickshell), lock (hyprlock/swaylock), idle (hypridle/swayidle), wallpaper (hyprpaper/awww), notifications (swaync/mako/dunst), launcher (rofi/wofi/fuzzel), OSD (swayosd/none), screenshot (grim/hyprshot), clipboard (cliphist/none), file manager (yazi/thunar)
- **Dynamic theming** — matugen v4 generates colors for all components; 5 light/dark mechanisms: keybind toggle (`SUPER+SHIFT+T`), scheduled timer, per-wallpaper mode, CLI (`kome-theme set light|dark`), static presets
- **Hardware-agnostic** — Wildcard monitor (`output=""`), runtime GPU detect, opt-in driver install only, no hardcoded monitor names or vendor env
- **System-wide scope** — GTK/Qt theming, icons, cursor, fonts, Plymouth/GRUB/sounds opt-in
- **Installer** — Interactive TUI (gum/whiptail), profiles (minimal/standard/full), idempotent per-file symlinks, backup + restore, dry-run
- **Publishable** — MIT license, own git repo, no stow/chezmoi

## Quick Start

```bash
git clone https://github.com/Joey-1123/kome-dots.git
cd kome-dots
./install.sh --dry-run --profile standard   # preview
./install.sh --profile standard              # install
```

Then log out and select Hyprland from greetd (or run `Hyprland` from TTY).

## Keybinds (SUPER = `mainMod`)

| Key | Action |
|-----|--------|
| `SUPER + T` | Terminal (kitty) |
| `SUPER + D` | App launcher (rofi) |
| `SUPER + E` | File manager (yazi) |
| `SUPER + W` | Wallpaper picker |
| `SUPER + V` | Clipboard history |
| `SUPER + Q` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + SPACE` | Toggle float |
| `SUPER + TAB` | Lock screen |
| `SUPER + GRAVE` | Power menu |
| `SUPER + SHIFT + T` | Toggle light/dark theme |
| `SUPER + SHIFT + G` | Toggle night light |
| `SUPER + SHIFT + B` | Toggle bar |
| `PRINT` | Screenshot region |
| `SHIFT + PRINT` | Screenshot full |
| `SUPER + PRINT` | Screenshot window |
| `SUPER + R` | Toggle screen recording |
| `SUPER + O` | Toggle window opacity |
| `SUPER + B` | Browser |
| `SUPER + X` | Next keyboard layout |
| `SUPER + 1-0` | Switch workspace |
| `SUPER + SHIFT + 1-0` | Move to workspace |

## Theming

```bash
kome-theme set dark          # set dark mode
kome-theme set light         # set light mode
kome-theme toggle            # toggle
kome-theme apply             # re-apply current mode
kome-theme schedule on       # auto-toggle at 06:00/20:00
kome-wallpaper pick          # interactive picker
kome-wallpaper random        # random from mode dir
```

## Provider Overrides

Edit `~/.config/kome/providers.env` to swap components:

```bash
KOME_BAR=waybar           # or quickshell
KOME_LOCK=hyprlock        # or swaylock
KOME_IDLE=hypridle        # or swayidle
KOME_WALLPAPER=hyprpaper  # or awww
KOME_NOTIFICATIONS=swaync # or mako, dunst
KOME_LAUNCHER=rofi        # or wofi, fuzzel
KOME_OSD=swayosd          # or none
KOME_SCREENSHOT=grim      # or hyprshot
KOME_CLIPBOARD=cliphist   # or none
KOME_FILEMANAGER=yazi     # or thunar
```

Then run `kome-session restart` to apply.

## Machine-Specific Overrides

Hyprland loads `~/.config/hypr/modules/local.lua` last (if present). Add GPU env, monitor layouts, or per-device input:

```lua
-- ~/.config/hypr/modules/local.lua
hl.env("AQ_DRM_DEVICES", "/dev/dri/card0:/dev/dri/card1")  -- multi-GPU
hl.monitor({ output = "DP-1", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", position = "1920x0", scale = 1 })
hl.device({ name = "logitech-g-pro", sensitivity = -0.3 })
```

## Requirements

- Arch Linux or derivative (CachyOS, EndeavourOS, Manjaro)
- Hyprland ≥ 0.56 (Lua config)
- `gum` or `whiptail` for installer TUI
- `yay` or `paru` for AUR packages

## Testing

```bash
bash tests/lint.sh              # shellcheck + bash -n + luac
bash tests/verify-config.sh     # hyprland --verify-config
bash tests/vm/run-vm.sh         # headless QEMU VM (requires KVM)
```

## License

MIT — see [LICENSE](LICENSE).
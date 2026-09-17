# Ticket: `kome` — hardware-agnostic Hyprland rice

Status: approved
Created: 2026-09-17
Reference: https://github.com/43PR/dotfiles (aesthetic/structural inspiration; Lua-based)

## Summary

Build a distributable Hyprland "rice" for Arch Linux and Arch derivatives
(CachyOS, EndeavourOS, Manjaro). Dotfiles repo plus a bash installer that
symlinks configs, with dynamic light/dark theming and swappable component
providers.

## Requirements

- Arch + Arch derivatives. Not specific to any hardware.
- Deliverable: dotfiles repo + bash installer (symlinks, no stow/chezmoi).
- Publishable repo, MIT licensed.
- Session: greetd + tuigreet (opt-in).
- Theming: dynamic via matugen, clean/minimal, BOTH light and dark.
- Hardware: generic wildcards + runtime detection; GPU driver install is opt-in.
- Components: Waybar (default, alternatives supported), Rofi (Wayland),
  Kitty, multi-shell (zsh/fish/bash chosen at install), notifications,
  lock+idle, clipboard, screenshots, wallpaper, file manager (yazi),
  system applets, portals + polkit.
- Light/dark mechanisms: keybind toggle, scheduled auto, mode-per-wallpaper,
  CLI (`kome-theme set light|dark`), static presets.
- System-wide scope: GTK/Qt theming, icons+cursor, fonts, Plymouth, GRUB,
  system sounds.
- AUR via yay + pacman; do not block other AUR helpers; user may choose.
- Backup existing `~/.config` then symlink.
- Installer UX: interactive TUI (gum, whiptail fallback).
- Profiles: minimal / standard / full.
- Monitors: wildcard + optional local override.
- Bundle a few license-clean wallpapers.
- Verification: VM install test (plus real `hyprland --verify-config`).

## Constraint (added at approval)

Waybar is the default bar, but keep an **alternatives provider system** so
other components (hyprlock, hyprpaper, notification daemon, launcher, lock,
idle, OSD, screenshot, clipboard) can be swapped at install time. Only the
selected provider's config is symlinked and its packages installed.

## Out of scope

- Installing user applications (browsers, editors, Spotify).
- GPU vendor tuning beyond an opt-in driver package step.
- Non-Arch distributions.

## Acceptance criteria

1. `./install.sh --dry-run --profile standard` prints a complete plan without
   mutating the system.
2. Real install on a clean Arch installs profile packages, backs up existing
   config, symlinks the selected dotfiles, and seeds a matugen theme.
3. `hyprland --verify-config -c <linked hyprland.lua>` returns 0 for every
   supported provider combination.
4. `kome-theme toggle`, `kome-theme set light|dark`, and `kome-wallpaper set`
   regenerate and reload all themed components.
5. Tracked configs contain no concrete monitor names or GPU-specific env;
   overrides live in untracked `local.lua` / `monitors.local.lua`.
6. Installer is idempotent: re-running does not duplicate or corrupt symlinks.
7. CI runs shellcheck + `hyprland --verify-config` on the config matrix.

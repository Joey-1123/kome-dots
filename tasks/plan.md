# Implementation Plan: Port remaining 43PR gaps into kome

## Overview

`ref/` (43PR/dotfiles) is the upstream. Kome already carries its keybinds, waybar shape, and quickshell apps, but 5 quickshell files drifted, 6 waybar scripts have no direct counterpart, rofi `colors.rasi` is missing, one bind (screen recorder) never made it over, and shell/app configs (zsh, starship, btop, cava, fastfetch, GTK) have no home in the profiles. This plan closes each gap behind a provider or profile so kome stays portable.

## Architecture Decisions

- Ref behavior lands behind existing seams: `kome-*` wrapper scripts, provider registry, profiles. No ref file gets symlinked raw.
- Host-specific values stay out. Ref hardcodes `HDMI-A-1`, `hwmon5`, `Skylake-H GT2`. Ports read the active output/sensor at runtime or drop the module.
- Recorder uses `gpu-screen-recorder` only when installed, records the focused monitor, saves to `~/Videos` with timestamp. Same keys as ref (`SUPER+R` toggle).
- Shell choice (`bash/zsh/fish`) already exists in the installer. Zsh extras (starship, autosuggestions, syntax-highlighting, eza aliases) ship as dotfiles the installer links, not inline shell edits.

## Task List

### Phase 1: Audits (read-only, no behavior change)

- [ ] Task 1: Reconcile 5 quickshell diffs
- [ ] Task 2: Waybar scripts parity audit
- [ ] Task 3: Rofi + hypr scripts parity audit

### Checkpoint: Audits
- [ ] Each diff has a keep/port/drop verdict written down
- [ ] `bash tests/lint.sh` still passes (nothing changed yet)

### Phase 2: Binds + runtime

- [ ] Task 4: Port screen-recorder bind on generic output
- [ ] Task 5: Shell dotfiles for zsh/starship/eza

### Checkpoint: Runtime
- [ ] `hyprland --verify-config` passes
- [ ] `bash tests/install-args.sh` passes
- [ ] Recorder toggles on a multi-monitor box without hardcoded outputs

### Phase 3: Apps + docs

- [ ] Task 6: Desktop app configs into profiles
- [ ] Task 7: Docs + regression tests for ported behavior

### Checkpoint: Complete
- [ ] Full suite green, README keybind table matches `binds.lua`
- [ ] Ready for review

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Quickshell drift is theming-only noise | Low | Task 1 verdict first; only port behavior diffs |
| gpu-screen-recorder missing on target | Med | Recorder bind checks `command -v`, warns via notify when absent |
| waybar hwmon path differs per machine | Med | Drop host-specific temp/gpu modules or read sensor at runtime |

## Open Questions

- Gammastep toggle: port as `kome` script or drop in favor of `hyprsunset`?
- `custom-gpu.txt` + `gpu_usage.sh`: drop (host-specific) or rewrite with `nvtop`/sysfs auto-detect?
- Keep ref `SHIFT+W` waybar toggle alongside kome `SHIFT+B`, or document the change and move on?

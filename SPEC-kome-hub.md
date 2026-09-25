# Spec: Kome Control Hub

## Objective

Turn the existing Quickshell settings window into a dotfiles control hub while preserving the current System, Audio, Display, Network, Bluetooth, Storage, and Configs pages.

The hub must provide one place to:

- launch common desktop actions;
- inspect and change appearance;
- search the installed keybinds;
- control dotfiles-specific desktop behavior;
- run maintenance checks;
- perform session actions safely.

Success means every visible control either performs its action, reports a failure, or explains why it is unavailable. No placeholder controls are included.

## Capability Map

| Capability | Responsibility | Depends on |
|---|---|---|
| `panel-motion` | Restrained entrance, pointer response, page transition, reduced-motion behavior | — |
| `overview` | Status summary and common launcher actions | `panel-motion` |
| `appearance` | Presets, light/dark mode, wallpaper state and actions | `panel-motion` |
| `shortcuts` | Searchable keybind reference from the canonical cheat-sheet | `panel-motion` |
| `desktop-controls` | Bar, game mode, night light, opacity, update, and doctor actions | `overview` |
| `session` | Lock and confirmed disruptive power/session actions | `overview` |

Build order: `panel-motion` → `overview` → `appearance` → `shortcuts` → `desktop-controls` → `session`.

## Tech Stack

- Quickshell 0.3.1
- Qt 6 / QML
- Hyprland 0.56.2
- Existing `kome-*` command-line tools
- Matugen-generated `Theme.qml` singleton

Quickshell APIs are implemented against the 0.3.1 documentation:

- `Process.command` and `Process.exec`: argument arrays; no implicit shell.
- `Quickshell.execDetached`: detached argument-array execution.
- `Quickshell.reload(true)`: hard shell reload after generated theme output changes.
- `IpcHandler`: typed `settings` functions and `showPage(name: string): void` for deterministic navigation and live verification.

Sources:

- https://quickshell.org/docs/v0.3.1/types/Quickshell/Quickshell
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/Process
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/IpcHandler

## Commands

```bash
# Full repository checks
bash tests/lint.sh
bash tests/ported-scripts.sh
bash tests/verify-config.sh

# Shell checks for changed command files
shellcheck -x scripts/kome-theme scripts/kome-updates tests/*.sh

# Live Quickshell parse/startup smoke check
QS_NO_RELOAD_POPUP=1 timeout 5 qs -n -p config/quickshell/shell.qml

# Runtime IPC inspection
qs ipc show

# Open and navigate the live hub
qs ipc call settings show
qs ipc call settings showPage kome
qs ipc call settings showPage shortcuts
```

Destructive runtime checks are manual only. Automated tests must never log out, suspend, reboot, or power off the machine.

## Project Structure

```text
config/quickshell/
  PerspectivePanel.qml       # panel motion and reduced-motion behavior
  SettingsWindow.qml          # shell, navigation, page transitions, IPC
  SettingsPages/
    KomePage.qml              # overview, appearance, controls, session
    ShortcutsPage.qml         # searchable keybind reference
    SystemPage.qml            # existing hardware overview
    ...                       # existing settings pages remain unchanged

scripts/
  kome-theme                   # theme state interfaces
  kome-updates                 # machine-readable update count
  kome-doctor                  # plain diagnostic output

tests/
  kome-hub.sh                  # static hub contract and script regressions
```

No `tasks/plan.md` or `tasks/todo.md` will be created.

## Code Style

Use token-driven inline QML components, explicit command arrays, and state held by the component that owns it.

```qml
Process {
    id: wallpaperNext
    command: ["kome-wallpaper", "next"]
    running: false
    stdout: StdioCollector {
        onStreamFinished: page.currentWallpaper = text.trim()
    }
}
```

Conventions:

- Colors, radii, and motion durations come from `Theme.qml`.
- Commands use argument arrays unless a feature genuinely needs `sh -c`.
- User-controlled values are validated before becoming command arguments.
- Action buttons expose hover, pressed, focus, disabled, busy, selected, and destructive states as applicable.
- Status text explains asynchronous success and failure.
- Existing page filenames and IPC target remain compatible.

## Testing Strategy

### Automated

- Shell syntax and ShellCheck for every changed script.
- Static contract test for all hub actions and both new pages.
- Existing keybind/preset/provider regression tests remain green.
- Hyprland Lua verification remains green.
- Quickshell startup emits no QML parse or runtime errors.

### Live desktop

- Open the hub with `SUPER+I` and via IPC.
- Confirm the Kome overview and Shortcuts pages render.
- Search and clear the keybind filter.
- Exercise non-destructive quick actions.
- Apply a theme preset and confirm the panel reloads with the new palette.
- Change wallpaper and confirm the preview refreshes.
- Toggle bar/game mode/night light/opacity and confirm external state changes.
- Run update and doctor checks and confirm readable output.
- Open each destructive confirmation without executing the action.
- Check the panel at the current desktop resolution.
- Repeat with `KOME_REDUCED_MOTION=1` in an isolated Quickshell smoke run.

## Boundaries

### Always

- Preserve all seven existing settings pages.
- Use `Theme.danger` for logout, reboot, and shutdown confirmation/actions.
- Require confirmation for logout, suspend, reboot, and shutdown.
- Keep command arguments separately quoted and validate page/action identifiers.
- Keep the panel usable by mouse and keyboard.
- Commit and push each verified increment; leave no untracked plans or temporary artifacts.

### Ask first

- Adding dependencies.
- Changing default keybinds or provider defaults.
- Making a destructive action immediate.
- Executing logout, suspend, reboot, shutdown, or uninstall during automated verification.

### Never

- Run destructive power actions as part of tests.
- Interpolate untrusted text into shell command strings.
- Add a second volume OSD or bypass the selected providers.
- Claim visual, accessibility, or runtime success without checking the live result.
- Recreate the deleted `tasks/` plan documents.

## Success Criteria

- The settings window presents Kome and Shortcuts before the existing settings pages.
- Panel entrance uses a short transform/opacity transition without bounce; reduced-motion mode removes transforms and pointer tilt.
- The Kome page exposes quick actions, appearance controls, desktop controls, maintenance actions, and session controls.
- Theme presets use the existing authentic palettes and matching wallpapers.
- Light/dark mode and wallpaper state refresh after commands complete.
- The keybind page loads the same data as `kome-keybinds --list` and filters by key or description.
- Every asynchronous control has busy and feedback behavior.
- Disruptive session actions require visible confirmation and use destructive styling.
- Existing settings pages remain reachable and retain their IPC behavior.
- Repository tests, ShellCheck, Hyprland verification, and Quickshell startup checks pass.
- The live panel is visually inspected; unverified areas are reported explicitly.
- Work is committed and pushed with a clean working tree.

## Open Questions

None. The user approved the full six-capability scope and preservation of existing pages.

## Implementation Slices

### 1. Panel foundation

**Acceptance criteria:**

- The panel opens with a short transform/opacity entrance and no bounce.
- Pointer response is subtle and disabled by `KOME_REDUCED_MOTION=1`.
- Page selection is explicit, clickable, keyboard-focusable, and animated without shifting surrounding layout.

**Verification:**

- Static QML contract test.
- Live open/close and reduced-motion smoke run.

**Files:** `config/quickshell/PerspectivePanel.qml`, `config/quickshell/SettingsWindow.qml`, `tests/kome-hub.sh`.

### 2. Machine-readable dotfiles state

**Acceptance criteria:**

- Theme mode and active preset can be queried without parsing human prose.
- Pending update count can be queried as a number.
- Doctor output can be rendered without terminal ANSI escapes.
- Existing command behavior remains backward compatible.

**Verification:**

- ShellCheck, Bash syntax checks, and isolated CLI assertions.

**Files:** `scripts/kome-theme`, `scripts/kome-updates`, `scripts/kome-doctor`, `tests/kome-hub.sh`.

### 3. Kome overview and appearance

**Acceptance criteria:**

- The first page shows current time, theme, wallpaper, and pending-update state.
- Common launcher/file/browser/clipboard/notification/screenshot/record actions invoke existing scripts.
- The three shipped presets and light/dark mode can be applied.
- Wallpaper picker, next, and random actions work and refresh the preview/state.

**Verification:**

- Non-destructive live actions.
- One reversible preset change followed by restoration of the original theme.

**Files:** `config/quickshell/SettingsPages/KomePage.qml`, `config/quickshell/SettingsWindow.qml`, `tests/kome-hub.sh`.

### 4. Searchable shortcuts

**Acceptance criteria:**

- The Shortcuts page loads `kome-keybinds --list` as its single source of truth.
- Filtering matches key combinations and descriptions.
- Empty, loading, and ready states are distinct and keyboard accessible.

**Verification:** Static contract test and live search/clear interaction.

**Files:** `config/quickshell/SettingsPages/ShortcutsPage.qml`, `config/quickshell/SettingsWindow.qml`, `tests/kome-hub.sh`.

### 5. Desktop controls, maintenance, and session safety

**Acceptance criteria:**

- Bar, game mode, night light, opacity, update check, and doctor actions have live feedback.
- Lock is immediate; logout, suspend, reboot, and shutdown require confirmation.
- Destructive triggers and confirmations use `Theme.danger`.
- Automated verification never executes a disruptive action.

**Verification:** Toggle each reversible control live and open/close each confirmation without confirming it.

**Files:** `config/quickshell/SettingsPages/KomePage.qml`, `tests/kome-hub.sh`.

### 6. End-to-end verification and delivery

**Acceptance criteria:**

- All automated checks pass.
- Every page renders in the live panel and existing pages remain reachable.
- The working tree contains no temporary or untracked artifacts.
- Verified changes are committed in logical increments and pushed to `origin/master`.

**Verification:** Full command set from this spec, live screenshots/manual inspection, `git status`, and remote comparison.

**Files:** Only files changed to fix issues found by verification.

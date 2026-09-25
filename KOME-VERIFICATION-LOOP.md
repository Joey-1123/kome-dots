# Kome Verification Loop

This document records the repeatable verification loop used while building the Kome control hub. It is intentionally a practical runbook rather than a task list: it explains how to verify a Quickshell change, why each layer is needed, and where the safety boundaries are.

## Why the loop exists

A static QML grep can prove that a component or command exists, but it cannot prove that:

- a dynamically linked Quickshell type is available;
- a default-property slot lays out children at a real width and position;
- an asynchronous model arrives after the page has opened;
- a live desktop command changes the external desktop state;
- a confirmation is visible without executing the destructive action behind it;
- a multi-page navigation sweep does not introduce runtime warnings.

The loop therefore combines contracts, isolated runtimes, the real Desktop, and reversible end-to-end actions.

## The loop

### 1. Add a contract before implementation

Start with a focused assertion in `tests/settings-pages.sh`, `tests/kome-hub.sh`, or the relevant script test. Make the assertion describe behavior rather than a cosmetic detail.

Examples of useful contracts:

- the page uses the shared frame and semantic components;
- the selected monitor is explicit and `monitors[0]` is not used;
- the keybind service runs `kome-keybinds --list` and parses both key and description;
- credentials are passed as separate command arguments and never stored;
- a destructive action has a confirmation path;
- a service uses a fixed command allowlist rather than a page-provided shell string.

Run the new test once to establish the expected red state, then implement only enough code to satisfy it.

### 2. Run an isolated Quickshell harness

Copy the QML tree to a temporary directory and copy the generated `Theme.qml` into it. Keep all temporary files outside the repository.

```bash
rm -rf /tmp/opencode/kome-page-smoke
cp -a config/quickshell /tmp/opencode/kome-page-smoke
cp "$HOME/.config/quickshell/Theme.qml" /tmp/opencode/kome-page-smoke/Theme.qml

cat > /tmp/opencode/kome-page-smoke/harness.qml <<'EOF'
import Quickshell
import Quickshell.Wayland
import QtQuick
import "SettingsPages"

ShellRoot {
    PanelWindow {
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        SomePage { anchors.fill: parent }
    }
}
EOF

QS_NO_RELOAD_POPUP=1 timeout --signal=TERM 7s \
    qs -n -p /tmp/opencode/kome-page-smoke/harness.qml
```

The harness must be checked for both successful loading and absence of `WARN`, `ERROR`, `ReferenceError`, `TypeError`, and `SyntaxError` output. A timeout is expected because the harness is intentionally long-lived.

This layer catches errors before touching the user's active panel. It is especially useful for newly added root QML types, nested `Repeater` delegates, and nonvisual `Process`/`Timer` children.

### 3. Install only the new runtime types, then restart

Quickshell may need a restart to discover newly added root types. Link the new files into the live config tree, restart the shell, and wait for configuration load:

```bash
for file in NewService.qml NewComponent.qml; do
    ln -sfn "$PWD/config/quickshell/$file" "$HOME/.config/quickshell/$file"
done
pkill -x qs
scripts/kome-session start
sleep 4
```

A missing live symlink is a real installation failure even when the isolated harness passes. Always inspect the live Quickshell log after the restart.

### 4. Navigate through the typed IPC surface

Use the deterministic `settings` IPC functions rather than relying on mouse coordinates:

```bash
pid=$(pgrep -x qs)
qs ipc --pid "$pid" call settings showPage system
qs ipc --pid "$pid" call settings isShowing
```

Use `toggle` or `hide` to change panel visibility. The `show` function has special CLI behavior and is not the reliable visibility toggle.

For actions, use `runQuickAction` only for actions that are safe to exercise in the current verification context. The typed switch makes the test repeatable and avoids depending on a particular sidebar coordinate.

### 5. Capture and inspect real screenshots

Use `grim` for the live Desktop. Store captures in `/tmp`, never in the repository:

```bash
mkdir -p /tmp/opencode/kome-final-pages
qs ipc --pid "$pid" call settings showPage system
sleep 2
grim /tmp/opencode/kome-final-pages/system.png
```

For a multi-page pass, navigate through every page, capture one frame per page, and build a contact sheet for quick comparison:

```bash
montage /tmp/opencode/kome-final-pages/*.png \
    -thumbnail 420x260 -tile 3x3 -geometry +8+8 \
    -background '#111111' /tmp/opencode/kome-final-pages/contact.png
```

Inspect the contact sheet for missing headers, clipped cards, incorrect spacing, stale scroll positions, missing empty/error states, and controls that disappeared at the viewport edge. Then inspect individual frames when the contact sheet identifies a problem.

### 6. Verify asynchronous loading and search

For pages backed by a process or model, verify both the initial and post-load states. A page can pass a static contract and still open at the wrong scroll position if its model arrives after the first layout.

The reusable pattern is:

1. load the page;
2. wait for the real data;
3. reset the shared scroll position after the model changes;
4. apply a search query;
5. verify the filtered result and the search field remain visible;
6. clear the query and verify the full list returns.

A temporary harness may set a page property after a timer to exercise this path. It must remain under `/tmp` and must not call a destructive action.

### 7. Exercise reversible controls on the real Desktop

Use a toggle/restore pair and verify the external state independently:

```bash
qs ipc --pid "$pid" call settings runQuickAction bar
sleep 3
pgrep -x waybar
qs ipc --pid "$pid" call settings runQuickAction bar

qs ipc --pid "$pid" call settings runQuickAction game
sleep 3
qs ipc --pid "$pid" call settings runQuickAction game

qs ipc --pid "$pid" call settings runQuickAction night
sleep 3
qs ipc --pid "$pid" call settings runQuickAction night

qs ipc --pid "$pid" call settings runQuickAction opacity
sleep 3
hyprctl getoption decoration:active_opacity -j
qs ipc --pid "$pid" call settings runQuickAction opacity
```

Wait for each asynchronous action to finish before sending its inverse. A second action sent while the first is busy can legitimately be rejected; verify the resulting state and send a final restore command if needed.

The verification must end in the original state: bar visible, game mode off, night light off, and opacity back to its original value.

### 8. Open confirmations without confirming them

Destructive controls are tested by making the confirmation visible and then cancelling or abandoning the harness. Never invoke the confirm callback and never run logout, suspend, reboot, shutdown, uninstall, or cleanup commands as part of automated verification.

A temporary harness can set a pending action directly and render the dialog:

```qml
KomePage {
    anchors.fill: parent
    pendingSessionAction: "reboot"
}
```

The screenshot proves the dialog is visible and styled with the danger state. It does not authorize running the action.

### 9. Finish with repository and runtime gates

Run the complete relevant suite after the live pass:

```bash
bash tests/settings-pages.sh
bash tests/kome-hub.sh
bash tests/ported-scripts.sh
bash tests/verify-config.sh
bash tests/lint.sh
git diff --check
git status --short
```

Run one final full-shell smoke from a temporary copy with the generated theme present. The working tree must be clean, and the local commit must match `origin/master` before delivery.

## Safety boundaries

- Never automate a destructive power or session action.
- Never put untrusted text into a shell command string.
- Keep credentials in transient input fields and pass them as separate process arguments.
- Use confirmation dialogs for cleanup, logout, suspend, reboot, and shutdown.
- Treat a missing file, provider, or command as an explicit unavailable/error state, not as a successful action.
- Keep screenshots, harnesses, and generated diagnostics in `/tmp`; do not commit verification artifacts.
- Do not use a destructive action to prove that a button works. Visible confirmation plus static command contracts is the safe proof.

## Common failure patterns found with this loop

- A static test passed while a new root QML type was not linked into the live config tree.
- A default-property content slot left children at zero width until `forceLayout()` was called.
- A telemetry `Timer` had an interval but omitted `running: true`.
- An async model opened the page at the previous scroll extent; the page now resets scroll after model load and search changes.
- A Quickshell Bluetooth model was an `UntypedObjectModel`, so `.values.filter(...)` was required instead of `.filter(...)`.
- A stale config path looked active even though the target was not installed; existence probing now renders a disabled missing state.
- `opacity` is a final `Item` property, so a service state property with that name was renamed to `windowOpacity`.
- An empty stderr stream can still emit a completion signal; status handlers must ignore empty text before reporting an error.

## Completion checklist

- [ ] Contract test added and passing.
- [ ] Isolated QML harness loads without warnings.
- [ ] New live root types are linked and the shell restarted cleanly.
- [ ] Every affected page is reachable through typed IPC.
- [ ] Real screenshots and a contact sheet were inspected.
- [ ] Async/search states were checked after data arrived.
- [ ] Reversible controls were toggled and restored.
- [ ] Destructive confirmations were opened but not executed.
- [ ] Full tests, config verification, shell smoke, and `git diff --check` pass.
- [ ] No temporary artifacts are tracked and `origin/master` matches the final commit.

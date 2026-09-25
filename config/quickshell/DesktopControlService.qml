import QtQuick
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property bool barRunning: false
    property bool gameMode: false
    property bool nightLight: false
    property real windowOpacity: 1
    property int updateCount: -1
    property string statusText: "Loading"
    property string actionOutput: ""
    property string doctorOutput: ""
    property bool actionFailed: false
    readonly property bool busy: actionRunner.running

    function refreshAll() {
        if (!barReader.running) barReader.running = true
        if (!gameReader.running) gameReader.running = true
        if (!nightReader.running) nightReader.running = true
        if (!opacityReader.running) opacityReader.running = true
        if (!updatesReader.running) updatesReader.running = true
    }

    function run(command, label) {
        if (actionRunner.running) {
            statusText = "Another desktop action is running"
            actionFailed = true
            return
        }
        statusText = label + "..."
        actionOutput = ""
        actionFailed = false
        actionRunner.command = command
        actionRunner.running = true
    }

    function toggleBar() { run(["kome-bar", "toggle"], "Bar toggle") }
    function toggleGameMode() { run(["kome-gamemode", "toggle"], "Game mode") }
    function toggleNightLight() { run(["kome-gammastep"], "Night light") }
    function toggleOpacity() { run(["kome-opacity"], "Opacity") }
    function checkUpdates() { run(["kome-updates", "check"], "Update check") }
    function runDoctor() { run(["kome-doctor"], "Doctor") }

    Process {
        id: barReader
        command: [
            "sh", "-c",
            ". \"${XDG_CONFIG_HOME:-$HOME/.config}/kome/providers.env\" 2>/dev/null || true; " +
            "if [ \"${KOME_BAR:-waybar}\" = quickshell ]; then pgrep -x quickshell; else pgrep -x waybar; fi"
        ]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => service.barRunning = exitCode === 0
    }

    Process {
        id: gameReader
        command: ["sh", "-c", "test -f \"${XDG_STATE_HOME:-$HOME/.local/state}/kome/gamemode\""]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => service.gameMode = exitCode === 0
    }

    Process {
        id: nightReader
        command: ["pgrep", "-x", "gammastep"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => service.nightLight = exitCode === 0
    }

    Process {
        id: opacityReader
        command: ["hyprctl", "getoption", "decoration:active_opacity", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = JSON.parse(text).float
                    if (typeof value === "number") service.windowOpacity = value
                } catch (error) {}
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: updatesReader
        command: ["kome-updates", "count"]
        stdout: StdioCollector {
            onStreamFinished: {
                const count = parseInt(text.trim())
                if (!isNaN(count)) service.updateCount = count
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: actionRunner
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                if (output) service.actionOutput = output
                if (service.statusText === "Doctor...") service.doctorOutput = output
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                if (output) service.actionOutput = output
            }
        }
        onExited: exitCode => {
            service.statusText = exitCode === 0
                ? (service.actionOutput ? "Desktop action complete" : "Ready")
                : "Desktop action failed"
            service.actionFailed = exitCode !== 0
            service.refreshAll()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: service.refreshAll()
    }

    Component.onCompleted: service.refreshAll()
}

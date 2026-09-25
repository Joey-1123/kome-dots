import QtQuick
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property string statusText: "Ready"
    property string actionOutput: ""
    property bool actionFailed: false
    readonly property bool busy: actionRunner.running

    function run(command, label) {
        if (actionRunner.running) {
            statusText = "Another session action is running"
            actionFailed = true
            return
        }
        statusText = label + "..."
        actionOutput = ""
        actionFailed = false
        actionRunner.command = command
        actionRunner.running = true
    }

    function lock() {
        run(["kome-lock"], "Lock")
    }

    function runDisruptive(action) {
        switch (action) {
        case "logout":
            run(["hyprctl", "dispatch", "exit", "0"], "Logout")
            break
        case "suspend":
            run(["systemctl", "suspend"], "Suspend")
            break
        case "reboot":
            run(["systemctl", "reboot"], "Reboot")
            break
        case "shutdown":
            run(["systemctl", "poweroff"], "Shutdown")
            break
        }
    }

    Process {
        id: actionRunner
        stdout: StdioCollector { onStreamFinished: service.actionOutput = text.trim() }
        stderr: StdioCollector { onStreamFinished: service.actionOutput = text.trim() }
        onExited: exitCode => {
            service.statusText = exitCode === 0 ? "Session action complete" : "Session action failed"
            service.actionFailed = exitCode !== 0
        }
    }
}

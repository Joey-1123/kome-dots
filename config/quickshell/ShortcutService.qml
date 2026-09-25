import QtQuick
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property var binds: []
    property bool loading: true
    property string errorText: ""

    function parseLine(line) {
        const divider = line.indexOf("|")
        if (divider < 0) return null
        const key = line.slice(0, divider).trim()
        const description = line.slice(divider + 1).trim()
        return key && description ? { key: key, description: description } : null
    }

    function filtered(query) {
        const needle = query.trim().toLowerCase()
        if (!needle) return binds
        return binds.filter(bind =>
            bind.key.toLowerCase().includes(needle)
            || bind.description.toLowerCase().includes(needle)
        )
    }

    Process {
        id: keybindReader
        command: ["kome-keybinds", "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = []
                for (const line of text.split("\n")) {
                    const bind = service.parseLine(line)
                    if (bind) result.push(bind)
                }
                service.binds = result
                service.loading = false
                service.errorText = ""
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.errorText = text.trim()
                service.loading = false
            }
        }
        onExited: exitCode => {
            service.loading = false
            if (exitCode !== 0 && service.binds.length === 0) {
                service.errorText = "Could not load keybinds"
            }
        }
    }

    Component.onCompleted: keybindReader.running = true
}

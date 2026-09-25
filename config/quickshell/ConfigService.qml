import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property string statusText: "Ready"
    property var availability: ({})
    property bool checked: false
    readonly property string homeDir: Quickshell.env("HOME") || "~"

    readonly property var sections: [
        {
            title: "HYPRLAND",
            description: "Compositor, input, rules, and monitor behavior",
            items: [
                { label: "PROGRAMS · AUTOSTART · INPUT", path: "~/.config/hypr/hyprland.lua" },
                { label: "LOOK AND FEEL", path: "~/.config/hypr/modules/look.lua" },
                { label: "KEYBINDS", path: "~/.config/hypr/modules/binds.lua" },
                { label: "RULES", path: "~/.config/hypr/modules/rules.lua" },
                { label: "MONITORS", path: "~/.config/hypr/modules/monitors.lua" },
                { label: "LOCK SCREEN", path: "~/.config/hypr/hyprlock.conf" },
                { label: "SETTINGS THEME", path: "~/.config/quickshell/Theme.qml" }
            ]
        },
        {
            title: "WAYBAR",
            description: "Panel layout and visual styling",
            items: [
                { label: "CONFIG", path: "~/.config/waybar/config.jsonc" },
                { label: "STYLE", path: "~/.config/waybar/style.css" }
            ]
        },
        {
            title: "WLOGOUT",
            description: "Session menu layout and styling",
            items: [
                { label: "STYLE", path: "~/.config/wlogout/style.css" },
                { label: "LAYOUT", path: "~/.config/wlogout/layout" }
            ]
        }
    ]

    function resolve(path) {
        if (path.indexOf("~/") === 0) return homeDir + path.slice(1)
        return path
    }

    function filteredSections(query) {
        const needle = query.trim().toLowerCase()
        if (!needle) return sections
        return sections.map(section => ({
            title: section.title,
            description: section.description,
            items: section.items.filter(item =>
                item.label.toLowerCase().includes(needle)
                || item.path.toLowerCase().includes(needle)
            )
        })).filter(section => section.items.length > 0)
    }

    function pathExists(path) {
        return !checked || service.availability[path] !== false
    }

    function checkFiles() {
        const command = [
            "sh", "-c",
            "for path in \"$@\"; do if [ -f \"$path\" ]; then printf '1\\t%s\\n' \"$path\"; else printf '0\\t%s\\n' \"$path\"; fi; done",
            "kome-config-check"
        ]
        for (const section of service.sections) {
            for (const item of section.items) command.push(service.resolve(item.path))
        }
        checkProcess.command = command
        checkProcess.running = true
    }

    function open(path) {
        if (!pathExists(path)) {
            service.statusText = "Config is not installed"
            return
        }
        const resolved = resolve(path)
        service.statusText = "Opening " + path.split("/").pop()
        Quickshell.execDetached(["xdg-open", resolved])
    }

    Process {
        id: checkProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const result = {}
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const parts = line.split("\t")
                    result[parts[1]] = parts[0] === "1"
                }
                service.availability = result
                service.checked = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.statusText = "Could not inspect config paths"
            }
        }
    }

    Component.onCompleted: service.checkFiles()
}

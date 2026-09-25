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
    property var kittyThemes: []
    property string kittyTheme: "unknown"
    property string pendingTheme: ""
    property var barThemes: []
    property string barTheme: "unknown"
    property string pendingBarTheme: ""
    readonly property bool busy: applyRunner.running || barApplyRunner.running
    readonly property string homeDir: Quickshell.env("HOME") || "~"

    readonly property var fileSections: [
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

    readonly property var sections: fileSections.concat(themeSections())

    // Theme lists come from the installed libraries, so the picker stays truthful
    // when a machine ships more or fewer schemes than the repo does.
    function themeSections() {
        const found = []
        if (kittyThemes.length > 0) {
            found.push({
                title: "TERMINAL",
                description: "Kitty colour theme. Open windows recolour immediately.",
                items: kittyThemes.map(theme => themeItem(theme, "kitty-theme", {
                    description: theme.name === "generated"
                        ? "Generated from the active wallpaper palette"
                        : "Background " + (theme.background || "unknown")
                            + " - text " + (theme.foreground || "unknown")
                            + " - cursor " + (theme.cursor || "unknown"),
                    accent: theme.cursor
                }))
            })
        }
        if (barThemes.length > 0) {
            found.push({
                title: "STATUS BAR",
                description: "Waybar theme. The bar reloads without restarting.",
                items: barThemes.map(theme => themeItem(theme, "bar-theme", {
                    description: theme.name === "kome"
                        ? "Default kome bar surface"
                        : "Palette " + (theme.background || "unknown")
                            + " - accent " + (theme.accent || "unknown"),
                    accent: theme.accent
                }))
            })
        }
        return found
    }

    function themeItem(theme, action, extra) {
        return Object.assign({
            label: theme.name.replace(/_/g, " ").toUpperCase(),
            path: themePath(action, theme.name),
            action: action,
            value: theme.name,
            background: theme.background,
            foreground: theme.foreground
        }, extra)
    }

    function themePath(action, name) {
        if (action === "bar-theme") {
            return name === "kome"
                ? "~/.config/waybar/bar-theme.css"
                : "~/.config/waybar/themes/" + name + ".css"
        }
        return name === "generated"
            ? "~/.config/kitty/colors.conf"
            : "~/.config/kitty/themes/" + name + ".conf"
    }

    function activeTheme(action) {
        return action === "bar-theme" ? service.barTheme : service.kittyTheme
    }

    function pendingThemeFor(action) {
        return action === "bar-theme" ? service.pendingBarTheme : service.pendingTheme
    }

    function refreshKittyThemes() {
        themeListRunner.command = ["kome-kitty-theme", "list", "--json"]
        themeListRunner.running = true
        themeCurrentRunner.command = ["kome-kitty-theme", "current"]
        themeCurrentRunner.running = true
    }

    function refreshBarThemes() {
        barListRunner.command = ["kome-bar-theme", "list", "--json"]
        barListRunner.running = true
        barCurrentRunner.command = ["kome-bar-theme", "current"]
        barCurrentRunner.running = true
    }

    function refreshThemes() {
        service.refreshKittyThemes()
        service.refreshBarThemes()
    }

    function applyKittyTheme(name) {
        service.applyTheme("kitty-theme", name)
    }

    function applyBarTheme(name) {
        service.applyTheme("bar-theme", name)
    }

    function applyTheme(action, name) {
        if (service.busy) {
            service.statusText = "A theme change is already running"
            return
        }
        const isBar = action === "bar-theme"
        const runner = isBar ? barApplyRunner : applyRunner
        const tool = isBar ? "kome-bar-theme" : "kome-kitty-theme"
        const fallback = isBar ? "kome" : "generated"
        if (isBar) {
            service.pendingBarTheme = name
        } else {
            service.pendingTheme = name
        }
        service.statusText = "Applying " + name.replace(/_/g, " ")
        runner.command = name === fallback
            ? [tool, "reset"]
            : [tool, "apply", name]
        applyWatchdog.restart()
        runner.running = true
    }

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

    Process {
        id: themeListRunner
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    service.kittyThemes = Array.isArray(parsed) ? parsed : []
                } catch (error) {
                    service.kittyThemes = []
                    service.statusText = "Could not read terminal themes"
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.kittyThemes = []
                service.statusText = "Terminal themes unavailable"
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                service.kittyThemes = []
                service.statusText = "Terminal themes unavailable"
            }
        }
    }

    Process {
        id: themeCurrentRunner
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value.length > 0) service.kittyTheme = value
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.kittyTheme = "unknown"
            }
        }
    }

    Process {
        id: applyRunner
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                if (output.length > 0) service.statusText = output
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.statusText = text.trim()
            }
        }
        onExited: exitCode => {
            const label = service.pendingTheme.replace(/_/g, " ")
            service.statusText = exitCode === 0 ? label + " applied" : label + " failed"
            service.pendingTheme = ""
            applyWatchdog.stop()
            service.refreshKittyThemes()
        }
    }

    Process {
        id: barListRunner
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    service.barThemes = Array.isArray(parsed) ? parsed : []
                } catch (error) {
                    service.barThemes = []
                    service.statusText = "Could not read bar themes"
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.barThemes = []
                service.statusText = "Bar themes unavailable"
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                service.barThemes = []
                service.statusText = "Bar themes unavailable"
            }
        }
    }

    Process {
        id: barCurrentRunner
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value.length > 0) service.barTheme = value
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.barTheme = "unknown"
            }
        }
    }

    Process {
        id: barApplyRunner
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                if (output.length > 0) service.statusText = output
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) {
                service.statusText = text.trim()
            }
        }
        onExited: exitCode => {
            const label = service.pendingBarTheme.replace(/_/g, " ")
            service.statusText = exitCode === 0 ? label + " applied" : label + " failed"
            service.pendingBarTheme = ""
            applyWatchdog.stop()
            service.refreshBarThemes()
        }
    }

    // A Process whose binary is missing never reports an exit, so the busy state
    // and the empty picker need a deadline instead of waiting on onExited.
    Timer {
        id: applyWatchdog
        interval: 8000
        onTriggered: {
            if (applyRunner.running) {
                applyRunner.running = false
                service.statusText = "Terminal theme change timed out"
                service.pendingTheme = ""
                service.refreshKittyThemes()
            } else if (barApplyRunner.running) {
                barApplyRunner.running = false
                service.statusText = "Bar theme change timed out"
                service.pendingBarTheme = ""
                service.refreshBarThemes()
            }
        }
    }

    Timer {
        interval: 3000
        onTriggered: if (service.kittyThemes.length === 0 && !service.busy) {
            service.statusText = "Terminal themes unavailable"
        } else if (service.barThemes.length === 0 && !service.busy) {
            service.statusText = "Bar themes unavailable"
        }
    }

    Component.onCompleted: {
        service.checkFiles()
        service.refreshThemes()
    }
}

// Kome's overview, launcher shortcuts, appearance controls, and status surface.
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: page

    property string themeMode: "dark"
    property string themePreset: ""
    property string currentWallpaper: ""
    property string updateText: "not checked"
    property string clockText: "--:--"
    property string dateText: ""
    property string statusText: "Ready"
    property string pendingAction: ""
    property string actionOutput: ""
    property bool actionFailed: false
    property bool refreshThemeAfterAction: false
    property bool refreshWallpaperAfterAction: false

    readonly property bool busy: actionRunner.running
    readonly property string themeLabel: themePreset
        ? themePreset.replace("-", " ").replace(/\b\w/g, function(c) { return c.toUpperCase() })
        : themeMode === "dark" ? "Dark" : "Light"

    function refreshTheme() {
        themeReader.running = true
    }

    function refreshWallpaper() {
        wallpaperReader.running = true
    }

    function updateClock() {
        const now = new Date()
        clockText = Qt.formatTime(now, "HH:mm")
        dateText = Qt.formatDate(now, "dddd, d MMMM")
    }

    function runAction(command, label) {
        if (actionRunner.running) {
            statusText = "Another action is still running"
            actionFailed = true
            return
        }

        pendingAction = label
        actionOutput = ""
        actionFailed = false
        statusText = label + "..."
        actionRunner.command = command
        actionRunner.running = true
    }

    function runAfterClosing(command, label) {
        if (actionRunner.running) {
            statusText = "Another action is still running"
            actionFailed = true
            return
        }

        delayedAction.command = command
        delayedAction.label = label
        delayedAction.start()
        Quickshell.execDetached(["qs", "ipc", "call", "settings", "hide"])
    }

    function runLauncher() {
        runAction([
            "sh",
            "-c",
            '. "${XDG_CONFIG_HOME:-$HOME/.config}/kome/providers.env"; ' +
            'case "${KOME_LAUNCHER:-rofi}" in ' +
            'rofi) exec rofi -dmenu ;; ' +
            'wofi) exec wofi --dmenu ;; ' +
            'fuzzel) exec fuzzel --dmenu ;; ' +
            '*) exec rofi -dmenu ;; esac'
        ], "App launcher")
    }

    function runQuickAction(action) {
        switch (action) {
        case "launcher": runLauncher(); break
        case "files": runAction(["kome-files"], "File manager"); break
        case "browser": runAction(["kome-browser"], "Browser"); break
        case "clipboard": runAction(["kome-clipboard"], "Clipboard history"); break
        case "notifications": runAction(["kome-notifications", "toggle"], "Notifications"); break
        case "screenshot":
            runAfterClosing(["kome-screenshot", "region"], "Screenshot")
            break
        case "record": runAction(["kome-record"], "Screen recorder"); break
        }
    }

    function applyPreset(preset) {
        refreshThemeAfterAction = true
        refreshWallpaperAfterAction = true
        runAction(
            ["kome-theme", "preset", preset],
            preset + " preset"
        )
    }

    function applyMode(mode) {
        refreshThemeAfterAction = true
        runAction(
            ["kome-theme", "set", mode],
            mode + " theme"
        )
    }

    function applyWallpaper(action) {
        refreshThemeAfterAction = true
        refreshWallpaperAfterAction = true

        switch (action) {
        case "picker":
            runAfterClosing(
                ["kome-wallpaper", "picker"],
                "Wallpaper picker"
            )
            break
        case "next":
            runAction(["kome-wallpaper", "next"], "Next wallpaper")
            break
        case "random":
            runAction(["kome-wallpaper", "random"], "Random wallpaper")
            break
        }
    }

    Process {
        id: themeReader

        command: ["kome-theme", "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text)
                    page.themeMode = state.mode || "dark"
                    page.themePreset = state.preset || ""
                } catch (error) {
                    page.statusText = "Could not read theme state"
                    page.actionFailed = true
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: page.actionOutput = text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0 && page.statusText === "Ready") {
                page.statusText = "Theme state unavailable"
                page.actionFailed = true
            }
        }
    }

    Process {
        id: wallpaperReader

        command: ["kome-wallpaper", "current"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                page.currentWallpaper = value === "none" ? "" : value
            }
        }
        stderr: StdioCollector {
            onStreamFinished: page.actionOutput = text.trim()
        }
    }

    Process {
        id: actionRunner

        stdout: StdioCollector {
            onStreamFinished: page.actionOutput = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: page.actionOutput = text.trim()
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                page.statusText = page.pendingAction + " complete"
                page.actionFailed = false
            } else {
                page.statusText = page.pendingAction + " failed"
                page.actionFailed = true
            }

            if (page.refreshThemeAfterAction) page.refreshTheme()
            if (page.refreshWallpaperAfterAction) page.refreshWallpaper()
            page.refreshThemeAfterAction = false
            page.refreshWallpaperAfterAction = false
            page.pendingAction = ""
        }
    }

    Timer {
        id: delayedAction

        property var command: []
        property string label: ""
        interval: 220
        onTriggered: page.runAction(command, label)
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: page.updateClock()
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: scroll.width
            spacing: 16
            bottomPadding: 18

            KomeHero {
                width: parent.width
                dateText: page.dateText
                clockText: page.clockText
                themeLabel: page.themeLabel
                updateText: "Updates: " + page.updateText
            }

            KomeQuickActions {
                width: parent.width
                busy: page.busy
                onActionRequested: action => page.runQuickAction(action)
            }

            KomeAppearance {
                width: parent.width
                busy: page.busy
                themePreset: page.themePreset
                themeMode: page.themeMode
                currentWallpaper: page.currentWallpaper
                onPresetRequested: preset => page.applyPreset(preset)
                onModeRequested: mode => page.applyMode(mode)
                onWallpaperRequested: action => page.applyWallpaper(action)
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Row {
                width: parent.width
                height: 28
                spacing: 8

                Rectangle {
                    width: 7
                    height: 7
                    radius: width / 2
                    color: page.actionFailed ? Theme.danger : Theme.ok
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    width: parent.width - 15
                    text: page.actionOutput.length > 0
                        ? page.statusText + " - " + page.actionOutput
                        : page.statusText
                    color: page.actionFailed ? Theme.danger : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component.onCompleted: {
        updateClock()
        refreshTheme()
        refreshWallpaper()
    }
}

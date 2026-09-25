import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property var monitors: []
    property real brightness: 0.6
    property real nightlight: 0.5
    property bool nightlightEnabled: false
    property string errorText: ""
    readonly property string nightlightPath: Quickshell.dataDir + "/display-nightlight.json"

    function refresh() {
        monitorReader.running = true
    }

    function currentMode(monitor) {
        if (!monitor) return ""
        return monitor.width + "x" + monitor.height + "@" + monitor.refreshRate.toFixed(2)
    }

    function luaString(value) {
        return String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
    }

    function monitorLua(monitor, options = {}) {
        if (!monitor) return ""
        const values = ["name = \"" + luaString(monitor.name) + "\""]
        if (options.mode !== undefined) values.push("mode = \"" + luaString(options.mode) + "\"")
        if (options.position !== undefined) {
            values.push("position = \"" + luaString(options.position) + "\"")
        }
        if (options.scale !== undefined) values.push("scale = " + options.scale)
        if (options.disabled !== undefined) values.push("disabled = " + options.disabled)
        if (options.mirrorOf !== undefined) {
            values.push("mirrorOf = \"" + luaString(options.mirrorOf) + "\"")
        }
        return "hl.monitor({" + values.join(",") + "})"
    }

    function apply(monitor, options) {
        if (!monitor || !monitor.name) return
        applyProcess.command = ["hyprctl", "eval", monitorLua(monitor, options)]
        applyProcess.running = true
    }

    function setMode(monitor, mode) {
        apply(monitor, {
            mode: mode,
            position: monitor.x + "x" + monitor.y,
            scale: monitor.scale || 1
        })
    }

    function validScale(monitor, requested) {
        const width = monitor.width
        const height = monitor.height
        let best = requested
        let bestDistance = Infinity

        for (let i = 84; i <= 1560; i++) {
            const scale = i / 120
            if (scale < 0.7 || scale > 1.3) continue
            const logicalWidth = width / scale
            const logicalHeight = height / scale
            if (Math.abs(logicalWidth - Math.round(logicalWidth)) < 0.0001 &&
                Math.abs(logicalHeight - Math.round(logicalHeight)) < 0.0001) {
                const distance = Math.abs(scale - requested)
                if (distance < bestDistance) {
                    best = scale
                    bestDistance = distance
                }
            }
        }
        return best
    }

    function setScale(monitor, requested) {
        apply(monitor, {
            mode: currentMode(monitor),
            position: monitor.x + "x" + monitor.y,
            scale: validScale(monitor, requested)
        })
    }

    function move(monitor, deltaX, deltaY) {
        apply(monitor, {
            mode: currentMode(monitor),
            position: Math.max(0, monitor.x + deltaX) + "x" + Math.max(0, monitor.y + deltaY),
            scale: monitor.scale || 1
        })
    }

    function setEnabled(monitor, enabled) {
        apply(monitor, {
            mode: currentMode(monitor),
            position: monitor.x + "x" + monitor.y,
            scale: monitor.scale || 1,
            disabled: !enabled
        })
    }

    function setMirror(monitor, target) {
        apply(monitor, {
            mode: currentMode(monitor),
            position: monitor.x + "x" + monitor.y,
            scale: monitor.scale || 1,
            mirrorOf: target || ""
        })
    }

    function commitBrightness(value) {
        brightnessProcess.command = ["brightnessctl", "set", Math.round(value * 100) + "%"]
        brightnessProcess.running = true
    }

    function nightlightTemperature() {
        return Math.round(2500 + nightlight * 4000)
    }

    function setNightlight(enabled) {
        nightlightEnabled = enabled
        if (enabled) {
            nightlightProcess.command = [
                "sh",
                "-c",
                "pkill -x gammastep 2>/dev/null; sleep 0.05; " +
                    "nohup gammastep -O " + nightlightTemperature() + " >/dev/null 2>&1 &"
            ]
        } else {
            nightlightProcess.command = ["pkill", "-x", "gammastep"]
        }
        nightlightProcess.running = true
        saveNightlight.restart()
    }

    function commitNightlight(value) {
        nightlight = value
        if (nightlightEnabled) setNightlight(true)
        else saveNightlight.restart()
    }

    Process {
        id: monitorReader
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    service.monitors = JSON.parse(text)
                    service.errorText = ""
                } catch (error) {
                    service.monitors = []
                    service.errorText = "Could not read monitor state"
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
    }

    Process {
        id: applyProcess
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
        onExited: refreshTimer.restart()
    }

    Process {
        id: brightnessGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const percentage = parseInt(parts[3])
                    if (!isNaN(percentage)) service.brightness = percentage / 100
                }
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: brightnessProcess
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
    }

    Process {
        id: nightlightProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: nightlightCheck
        command: ["pgrep", "-x", "gammastep"]
        onExited: exitCode => service.nightlightEnabled = exitCode === 0
    }

    Process {
        id: nightlightLoad
        command: [
            "sh",
            "-c",
            "if [ -f \"$1\" ]; then cat \"$1\"; fi",
            "kome-nightlight",
            service.nightlightPath
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved = JSON.parse(text.trim())
                    if (typeof saved.value === "number") service.nightlight = saved.value
                } catch (error) {}
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: nightlightSave
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Timer {
        id: saveNightlight
        interval: 300
        onTriggered: {
            nightlightSave.command = [
                "sh",
                "-c",
                "mkdir -p \"$(dirname \"$2\")\"; tmp=\"$2.tmp\"; " +
                    "printf '%s' \"$1\" > \"$tmp\"; mv \"$tmp\" \"$2\"",
                "kome-nightlight",
                JSON.stringify({ value: service.nightlight }),
                service.nightlightPath
            ]
            nightlightSave.running = true
        }
    }

    Timer {
        id: refreshTimer
        interval: 250
        onTriggered: service.refresh()
    }

    Component.onCompleted: {
        brightnessGet.running = true
        nightlightCheck.running = true
        nightlightLoad.running = true
        service.refresh()
    }
}

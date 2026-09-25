import QtQuick
import Quickshell.Io

Item {
    id: telemetry

    visible: false
    width: 0
    height: 0

    property string homeDir: ""
    property string hostname: "Loading"
    property string uptime: "Loading"
    property string os: "Loading"
    property string kernel: "Loading"
    property string cpu: "Loading"
    property string gpu: "Loading"
    property string memory: "Loading"
    property string ramSpeed: "Loading"
    property string cpuTemp: "—"
    property string gpuTemp: "—"
    property string telemetryError: ""

    property real cpuUsage: 0
    property real gpuUsage: 0
    property real memoryUsage: 0
    property bool telemetryBusy: false
    property var cpuPrev: null

    property var cpuHistory: []
    property var gpuHistory: []
    property var memoryHistory: []

    readonly property string systemSummary:
        "OS: " + os + "\n" +
        "Kernel: " + kernel + "\n" +
        "Host: " + hostname + "\n" +
        "WM: Hyprland\n" +
        "Uptime: " + uptime + "\n" +
        "CPU: " + cpu + "\n" +
        "GPU: " + gpu + "\n" +
        "Memory: " + memory

    function updateGraph(value, type) {
        const number = parseFloat(value)
        if (isNaN(number)) return
        const normalized = Math.max(0, Math.min(100, number))

        telemetry[type + "Usage"] = normalized
        const history = telemetry[type + "History"].slice()
        history.push(normalized)
        if (history.length > 60) history.shift()
        telemetry[type + "History"] = history
    }

    function updateCpuFromStat(value) {
        const parts = value.trim().split(/\s+/)
        if (parts.length < 5) return

        const user = Number(parts[1])
        const nice = Number(parts[2])
        const system = Number(parts[3])
        const idle = Number(parts[4])
        const iowait = Number(parts[5] || 0)
        const irq = Number(parts[6] || 0)
        const softirq = Number(parts[7] || 0)
        const steal = Number(parts[8] || 0)
        const idleTime = idle + iowait
        const total = user + nice + system + idleTime + iowait + irq + softirq + steal

        if (telemetry.cpuPrev !== null) {
            const totalDelta = total - telemetry.cpuPrev.total
            const idleDelta = idleTime - telemetry.cpuPrev.idle
            if (totalDelta > 0) {
                telemetry.updateGraph(100 * (1 - idleDelta / totalDelta), "cpu")
            }
        }

        telemetry.cpuPrev = { total: total, idle: idleTime }
    }

    function formatMemory(kb) {
        const gib = kb / 1024 / 1024
        return gib >= 1
            ? gib.toFixed(1) + " GiB"
            : Math.round(kb / 1024) + " MiB"
    }

    function updateMemoryFromStat(value) {
        let total = 0
        let available = 0
        const lines = value.trim().split("\n")

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/)
            if (parts[0] === "MemTotal:") total = Number(parts[1])
            if (parts[0] === "MemAvailable:") available = Number(parts[1])
        }

        if (total <= 0) return
        const used = total - available
        telemetry.updateGraph(used / total * 100, "memory")
        telemetry.memory = telemetry.formatMemory(used) + " / " + telemetry.formatMemory(total)
    }

    function formatTemp(value) {
        const temp = parseFloat(value.trim())
        return isNaN(temp) ? "—" : Math.round(temp) + "°C"
    }

    function sensorTempCmd(patterns) {
        return "sensors 2>/dev/null | awk '/" + patterns.join("|") +
            "/ {for(i=1;i<=NF;i++) if($i ~ /\\+?[0-9]+(\\.[0-9]+)?°C/) " +
            "{gsub(/[+°C]/, \"\", $i); print $i; exit}}'"
    }

    function refresh() {
        telemetryBusy = true
        telemetryError = ""
        cpuUsageTimer.running = true
        slowTelemetryTimer.running = true
        uptimeReader.running = true
    }

    function copySummary() {
        copyProcess.command = [
            "sh",
            "-c",
            "printf '%s' \"$1\" | wl-copy",
            "kome-system-summary",
            systemSummary
        ]
        copyProcess.running = true
    }

    Process {
        id: homeReader
        command: ["sh", "-c", "printf '%s' \"$HOME\""]
        stdout: StdioCollector { onStreamFinished: telemetry.homeDir = text.trim() }
    }

    Process {
        id: hostnameReader
        command: ["uname", "-n"]
        stdout: StdioCollector { onStreamFinished: telemetry.hostname = text.trim() || "Unknown" }
    }

    Process {
        id: uptimeReader
        command: ["uptime", "-p"]
        stdout: StdioCollector { onStreamFinished: telemetry.uptime = text.trim() || "Unknown" }
    }

    Process {
        id: osReader
        command: ["sh", "-c", "grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '\"'"]
        stdout: StdioCollector { onStreamFinished: telemetry.os = text.trim() || "Unknown" }
    }

    Process {
        id: kernelReader
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: telemetry.kernel = text.trim() || "Unknown" }
    }

    Process {
        id: cpuReader
        command: ["sh", "-c", "awk -F: '/model name/ {gsub(/^ +/, \"\", $2); print $2; exit}' /proc/cpuinfo"]
        stdout: StdioCollector { onStreamFinished: telemetry.cpu = text.trim() || "Unknown" }
    }

    Process {
        id: gpuReader
        command: [
            "sh",
            "-c",
            "lspci 2>/dev/null | grep -Ei 'VGA|3D|Display' | sed -E 's/.*: //; s/ \\(rev.*\\)//' | head -1"
        ]
        stdout: StdioCollector { onStreamFinished: telemetry.gpu = text.trim() || "Unknown" }
    }

    Process {
        id: memoryReader
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: telemetry.updateMemoryFromStat(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: ramReader
        command: ["sudo", "-n", "/usr/bin/dmidecode", "-t", "memory"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                let speed = ""
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (line.indexOf("Configured Memory Speed:") !== 0) continue
                    const parts = line.split(/\s+/)
                    if (parts.length >= 4 && /^[0-9]+$/.test(parts[3])) {
                        speed = parts[3] + " " + parts[4]
                        break
                    }
                }
                telemetry.ramSpeed = speed || "Unknown"
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: cpuUsageReader
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector { onStreamFinished: telemetry.updateCpuFromStat(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: cpuTempReader
        command: ["sh", "-c", telemetry.sensorTempCmd(["Package id 0:", "Tctl:", "Tdie:"])]
        stdout: StdioCollector { onStreamFinished: telemetry.cpuTemp = telemetry.formatTemp(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: gpuUsageReader
        command: ["sh", "-c", "nvtop -s 2>/dev/null | jq -r '.[0].gpu_util' | tr -d '%'"]
        stdout: StdioCollector { onStreamFinished: telemetry.updateGraph(text, "gpu") }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0) telemetry.telemetryError = "GPU telemetry unavailable"
        }
    }

    Process {
        id: gpuTempReader
        command: ["sh", "-c", telemetry.sensorTempCmd(["GPU Temp:", "edge:", "junction:", "temp1:"])]
        stdout: StdioCollector { onStreamFinished: telemetry.gpuTemp = telemetry.formatTemp(text) }
        stderr: StdioCollector {}
    }

    Process {
        id: copyProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Timer {
        id: cpuUsageTimer
        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuUsageReader.running = true
            memoryReader.running = true
            cpuTempReader.running = true
            telemetry.telemetryBusy = false
        }
    }

    Timer {
        id: slowTelemetryTimer
        running: true
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuUsageReader.running = true
            gpuTempReader.running = true
        }
    }

    Component.onCompleted: {
        homeReader.running = true
        hostnameReader.running = true
        uptimeReader.running = true
        osReader.running = true
        kernelReader.running = true
        cpuReader.running = true
        gpuReader.running = true
        ramReader.running = true
    }
}

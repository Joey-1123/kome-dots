import QtQuick
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property var drives: []
    property var filesystems: []
    property var cleanupInfo: ({ yay: 0, pacman: 0, journal: 0, trash: 0, flatpak: 0 })
    property string statusText: "Loading"
    property string errorText: ""
    readonly property bool busy: pDrives.running || pStorage.running || pCleanup.running || commandProcess.running

    readonly property var cleanupActions: [
        {
            key: "trash",
            label: "TRASH",
            action: "EMPTY",
            title: "Empty trash?",
            message: "This permanently deletes everything in your trash.",
            command: ["sh", "-c", "rm -rf -- \"$HOME/.local/share/Trash/files/\"* \"$HOME/.local/share/Trash/info/\"*"]
        },
        {
            key: "yay",
            label: "YAY CACHE",
            action: "CLEAN",
            title: "Clear yay cache?",
            message: "This permanently removes the downloaded yay package cache.",
            command: ["sh", "-c", "rm -rf -- \"$HOME/.cache/yay/\"*"]
        },
        {
            key: "pacman",
            label: "PACMAN CACHE",
            action: "CLEAN",
            title: "Clean pacman cache?",
            message: "Old package versions will be removed; installed packages stay intact.",
            command: ["sudo", "paccache", "-r"]
        },
        {
            key: "journal",
            label: "JOURNAL",
            action: "7 DAYS",
            title: "Vacuum journal?",
            message: "Only the last seven days of system logs will be kept.",
            command: ["sudo", "journalctl", "--vacuum-time=7d"]
        },
        {
            key: "flatpak",
            label: "FLATPAK UNUSED",
            action: "CLEAN",
            title: "Remove unused Flatpaks?",
            message: "Unused Flatpak runtimes and packages will be removed.",
            command: ["flatpak", "uninstall", "--unused", "--assumeyes"]
        }
    ]

    function formatBytes(bytes) {
        if (!isFinite(bytes) || bytes < 0) return "0 B"
        const units = ["B", "KB", "MB", "GB", "TB"]
        let value = bytes
        let index = 0
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024
            index++
        }
        return (index ? value.toFixed(1) : Math.round(value)) + " " + units[index]
    }

    function parseSize(value) {
        if (!value) return 0
        const parts = value.trim().split(/\s+/)
        const number = parseFloat(parts[0])
        if (isNaN(number)) return 0
        const units = { B: 1, K: 1024, KB: 1024, KIB: 1024, M: 1048576, MB: 1048576, MIB: 1048576, G: 1073741824, GB: 1073741824, GIB: 1073741824, T: 1099511627776, TB: 1099511627776, TIB: 1099511627776 }
        return number * (parts.length > 1 ? units[parts[1].toUpperCase()] || 1 : 1)
    }

    function ignoredMount(mount) {
        return ["/proc", "/sys", "/run", "/dev"].some(prefix => mount.indexOf(prefix) === 0)
    }

    function ignoredFilesystem(filesystem) {
        return ["tmpfs", "devtmpfs", "overlay"].some(prefix => filesystem.indexOf(prefix) === 0)
    }

    function parseDfLine(line) {
        const fields = line.trim().split(/\s+/)
        if (fields.length < 6) return null
        const result = {
            filesystem: fields[0],
            total: parseInt(fields[1]),
            used: parseInt(fields[2]),
            available: parseInt(fields[3]),
            percent: parseInt(fields[4]),
            mount: fields.slice(5).join(" ")
        }
        if ([result.total, result.used, result.available, result.percent].some(isNaN)
            || service.ignoredMount(result.mount)
            || service.ignoredFilesystem(result.filesystem)) return null
        return result
    }

    function parseDriveData(data) {
        const result = []
        try {
            const parsed = JSON.parse(data)
            for (const disk of parsed.blockdevices || []) {
                if (disk.type === "disk") {
                    result.push({
                        name: disk.name || "",
                        model: disk.model || "",
                        size: parseInt(disk.size) || 0,
                        tran: disk.tran || ""
                    })
                }
            }
        } catch (error) {
            service.errorText = "Could not read drive data"
        }
        return result
    }

    function usageForDisk(disk) {
        const prefix = "/dev/" + disk.name
        let used = 0
        let available = 0
        let total = 0
        for (const filesystem of service.filesystems) {
            if (filesystem.filesystem.indexOf(prefix) === 0) {
                used += filesystem.used
                available += filesystem.available
                total += filesystem.total
            }
        }
        return {
            used: used,
            available: available,
            total: total || disk.size,
            percent: total > 0 ? used / total * 100 : 0
        }
    }

    function cleanupMessage(action) {
        if (action.key === "yay") return service.formatBytes(service.cleanupInfo.yay) + " currently in ~/.cache/yay"
        return action.message
    }

    function refreshAll() {
        service.errorText = ""
        pDrives.running = true
        pStorage.running = true
        pCleanup.running = true
    }

    function runCleanup(key) {
        const action = service.cleanupActions.find(item => item.key === key)
        if (!action) return
        service.errorText = ""
        service.statusText = action.label + " cleanup running"
        commandProcess.command = action.command
        commandProcess.running = true
    }

    Process {
        id: pDrives
        command: ["lsblk", "-J", "-b", "-d", "-o", "NAME,MODEL,SIZE,TYPE,TRAN"]
        stdout: StdioCollector { onStreamFinished: service.drives = service.parseDriveData(text) }
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
    }

    Process {
        id: pStorage
        command: ["df", "-P", "-B1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = []
                for (const line of text.trim().split("\n")) {
                    const filesystem = service.parseDfLine(line)
                    if (filesystem) result.push(filesystem)
                }
                service.filesystems = result
            }
        }
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
    }

    Process {
        id: pCleanup
        command: [
            "sh", "-c",
            "printf 'YAY '; du -sb \"$HOME/.cache/yay\" 2>/dev/null | awk '{print $1}'; " +
            "printf 'PACMAN '; du -sb /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}'; " +
            "printf 'JOURNAL '; journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+ (B|K|M|G|T)' | tail -1; " +
            "printf 'TRASH '; du -sb \"$HOME/.local/share/Trash\" 2>/dev/null | awk '{print $1}'; " +
            "printf 'FLATPAK '; flatpak uninstall --unused --assumeno 2>/dev/null | grep -oE '[0-9.]+ (kB|MB|GB|TB)' | tail -1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = { yay: 0, pacman: 0, journal: 0, trash: 0, flatpak: 0 }
                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split(/\s+/)
                    const key = parts[0] ? parts[0].toLowerCase() : ""
                    if (result[key] !== undefined) result[key] = service.parseSize(parts.slice(1).join(" "))
                }
                service.cleanupInfo = result
                service.statusText = "Live"
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: commandProcess
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
        onExited: exitCode => {
            service.statusText = exitCode === 0 ? "Cleanup complete" : "Cleanup failed"
            service.refreshAll()
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: service.refreshAll()
    }

    Component.onCompleted: service.refreshAll()
}

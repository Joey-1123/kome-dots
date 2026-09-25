import QtQuick
import Quickshell.Io

Item {
    id: service

    visible: false
    width: 0
    height: 0

    property bool wifiEnabled: true
    property var networks: []
    property bool ethConnected: false
    property string ethDevice: ""
    property string ipAddress: ""
    property string pendingSsid: ""
    property string statusText: "Starting"
    property string errorText: ""
    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property real lastRx: -1
    property real lastTx: -1
    property real lastSample: 0

    readonly property var activeNetwork: networks.find(network => network.connected) || null
    readonly property string activeDevice: activeNetwork ? activeNetwork.device : ethDevice
    readonly property string connectionName: activeNetwork
        ? activeNetwork.ssid
        : ethConnected ? ethDevice : "Offline"
    readonly property bool connected: activeNetwork !== null || ethConnected

    onActiveDeviceChanged: {
        ipReader.command = [
            "nmcli",
            "-t",
            "-f",
            "IP4.ADDRESS",
            "device",
            "show",
            activeDevice || ""
        ]
        if (activeDevice) ipReader.running = true
        else service.ipAddress = ""
    }

    function parseWifiLine(line) {
        const fields = []
        let current = ""
        let escaped = false
        for (let i = 0; i < line.length; i++) {
            const character = line[i]
            if (escaped) {
                current += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === ":") {
                fields.push(current)
                current = ""
            } else {
                current += character
            }
        }
        fields.push(current)
        if (fields.length < 5 || !fields[2]) return null
        const signal = parseInt(fields[3])
        return {
            connected: fields[0] === "*",
            device: fields[1],
            ssid: fields[2],
            signal: isNaN(signal) ? 0 : signal,
            secured: fields[4] !== "" && fields[4] !== "--"
        }
    }

    function setWifiEnabled(enabled) {
        radioSet.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"]
        radioSet.running = true
    }

    function scan() {
        statusText = "Scanning Wi-Fi"
        rescan.running = true
    }

    function connectOpen(ssid) {
        pendingSsid = ssid
        pConnect.command = ["nmcli", "device", "wifi", "connect", ssid]
        pConnect.running = true
    }

    function connectSecured(ssid, password) {
        pendingSsid = ssid
        pConnect.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        pConnect.running = true
    }

    function disconnect(ssid) {
        pendingSsid = ssid
        pConnect.command = ["nmcli", "connection", "down", "id", ssid]
        pConnect.running = true
    }

    Process {
        id: netReader
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0
                let tx = 0
                const lines = text.split("\n")
                for (let i = 2; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (!line) continue
                    const separator = line.indexOf(":")
                    if (separator < 0) continue
                    const name = line.slice(0, separator).trim()
                    if (name === "lo" || name.startsWith("veth") ||
                        name.startsWith("docker") || name.startsWith("br-") ||
                        name.startsWith("virbr")) continue
                    const values = line.slice(separator + 1).trim().split(/\s+/)
                    rx += parseFloat(values[0]) || 0
                    tx += parseFloat(values[8]) || 0
                }

                const now = Date.now()
                if (service.lastSample > 0) {
                    const seconds = (now - service.lastSample) / 1000
                    if (seconds > 0) {
                        service.downloadSpeed = Math.max(0, (rx - service.lastRx) / seconds)
                        service.uploadSpeed = Math.max(0, (tx - service.lastTx) / seconds)
                    }
                }
                service.lastRx = rx
                service.lastTx = tx
                service.lastSample = now
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: ethernetReader
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                service.ethConnected = false
                service.ethDevice = ""
                const lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const fields = lines[i].split(":")
                    if (fields[1] === "ethernet" && fields[2] === "connected") {
                        service.ethConnected = true
                        service.ethDevice = fields[0]
                        break
                    }
                }
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: radioGet
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                service.wifiEnabled = text.trim() === "enabled"
                if (service.wifiEnabled) wifiReader.running = true
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: radioSet
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
        onExited: exitCode => {
            if (exitCode === 0) radioGet.running = true
            else service.statusText = "Could not change Wi-Fi state"
        }
    }

    Process {
        id: wifiReader
        command: ["nmcli", "-t", "-f", "IN-USE,DEVICE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = []
                const lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i].trim()) continue
                    const network = service.parseWifiLine(lines[i].trim())
                    if (network) result.push(network)
                }
                service.networks = result
                service.statusText = service.connected ? "Connected" : "Scanning Wi-Fi"
            }
        }
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
    }

    Process {
        id: rescan
        command: ["nmcli", "device", "wifi", "rescan"]
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
        onExited: wifiReader.running = true
    }

    Process {
        id: pConnect
        stdout: StdioCollector {}
        stderr: StdioCollector { onStreamFinished: service.errorText = text.trim() }
        onExited: exitCode => {
            service.statusText = exitCode === 0
                ? "Network action complete"
                : "Network action failed"
            service.pendingSsid = ""
            wifiReader.running = true
            ethernetReader.running = true
        }
    }

    Process {
        id: ipReader
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n").find(value => value.includes("IP4.ADDRESS"))
                service.ipAddress = line ? line.split(":").pop().split("/")[0] : ""
            }
        }
        stderr: StdioCollector {}
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!netReader.running) netReader.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!ethernetReader.running) ethernetReader.running = true
            if (service.wifiEnabled && !wifiReader.running) wifiReader.running = true
        }
    }

    Component.onCompleted: {
        radioGet.running = true
        wifiReader.running = true
        ethernetReader.running = true
    }
}

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Item {
    id: service

    visible: false
    width: 0
    height: 0

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property bool scanning: adapter ? adapter.discovering : false
    readonly property var pairedDevices: adapter
        ? adapter.devices.values.filter(device => device.paired)
        : []
    readonly property var availableDevices: adapter
        ? adapter.devices.values.filter(device => !device.paired)
        : []

    property bool pageVisible: false
    property string statusText: ""

    onPageVisibleChanged: updateDiscovery()
    onPoweredChanged: updateDiscovery()

    function filteredDevices(devices, query) {
        const needle = query.trim().toLowerCase()
        if (!needle) return devices
        return devices.filter(device =>
            (device.name || "").toLowerCase().includes(needle)
            || (device.address || "").toLowerCase().includes(needle)
        )
    }

    function updateDiscovery() {
        if (adapter) adapter.discovering = pageVisible && powered
    }

    function setStatus(text) {
        service.statusText = text
        statusTimer.restart()
    }

    function togglePower() {
        if (!adapter) return
        const enabled = !adapter.enabled
        if (!enabled && adapter.discovering) adapter.discovering = false
        adapter.enabled = enabled
        setStatus(enabled ? "Bluetooth enabled" : "Bluetooth disabled")
    }

    function toggleDiscovery() {
        if (!adapter || !powered) return
        adapter.discovering = !adapter.discovering
        setStatus(adapter.discovering ? "Scanning for devices" : "Discovery stopped")
    }

    function deviceAction(device) {
        if (!device) return
        const name = device.name || device.address || "device"

        if (device.state === BluetoothDeviceState.Connected) {
            setStatus("Disconnecting " + name)
            device.disconnect()
            return
        }
        if (device.state === BluetoothDeviceState.Connecting) {
            setStatus("Connecting to " + name)
            return
        }
        if (device.state === BluetoothDeviceState.Disconnecting) {
            setStatus("Disconnecting " + name)
            return
        }

        if (adapter && adapter.discovering) adapter.discovering = false
        device.trusted = true
        setStatus("Connecting to " + name)
        device.connect()
    }

    function forget(device) {
        if (!device) return
        const name = device.name || device.address || "device"
        if (device.state === BluetoothDeviceState.Connected ||
            device.state === BluetoothDeviceState.Connecting ||
            device.state === BluetoothDeviceState.Disconnecting) {
            device.disconnect()
        }
        device.forget()
        setStatus("Forgot " + name)
    }

    function actionLabel(device) {
        if (!device) return ""
        if (device.pairing) return "PAIRING"
        if (device.state === BluetoothDeviceState.Connected) return "DISCONNECT"
        if (device.state === BluetoothDeviceState.Connecting) return "CONNECTING"
        if (device.state === BluetoothDeviceState.Disconnecting) return "DISCONNECTING"
        return device.paired ? "CONNECT" : "PAIR"
    }

    function deviceDescription(device) {
        if (!device) return ""
        const details = [device.address]
        if (device.state === BluetoothDeviceState.Connected) details.push("connected")
        else if (device.paired) details.push("paired")
        if (device.batteryAvailable) {
            details.push(Math.round(device.battery * 100) + "% battery")
        }
        return details.filter(value => value).join("  •  ")
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: service.statusText = ""
    }

    Timer {
        interval: 1500
        repeat: true
        running: service.pageVisible && service.powered
        onTriggered: {
            if (service.adapter && !service.adapter.discovering) {
                service.adapter.discovering = true
            }
        }
    }

    Component.onCompleted: service.updateDiscovery()
    Component.onDestruction: if (service.adapter) service.adapter.discovering = false
}

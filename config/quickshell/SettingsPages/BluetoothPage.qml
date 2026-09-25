import QtQuick
import Quickshell.Bluetooth
import "../"

SettingsPage {
    id: page

    title: "BLUETOOTH"
    subtitle: "Pair, connect, and manage nearby Bluetooth devices"
    statusText: service.statusText
        ? service.statusText.toUpperCase()
        : !service.adapter
            ? "NO ADAPTER"
            : !service.powered ? "OFF" : service.scanning ? "SCANNING" : "READY"
    busy: false

    property string searchText: ""
    property var pendingForget: null

    onSearchTextChanged: resetScroll()
    onVisibleChanged: service.pageVisible = visible
    Component.onCompleted: service.pageVisible = visible
    Component.onDestruction: service.pageVisible = false

    BluetoothService {
        id: service
    }

    SettingsSection {
        width: parent.width
        title: "ADAPTER"
        description: service.adapter
            ? "Bluetooth radio and discovery state"
            : "No Bluetooth adapter is available"

        SettingsRow {
            label: "BLUETOOTH"
            description: service.powered
                ? "Radio is enabled and ready"
                : "Radio is disabled"
            selected: service.powered

            HubButton {
                label: service.powered ? "DISABLE" : "ENABLE"
                selected: service.powered
                onClicked: service.togglePower()
            }
        }

        SettingsRow {
            label: "DISCOVERY"
            description: service.scanning
                ? "Scanning for nearby devices"
                : service.powered ? "Discovery is stopped" : "Enable Bluetooth to scan"
            enabled: service.powered

            HubButton {
                label: service.scanning ? "STOP" : "SCAN"
                enabled: service.powered
                onClicked: service.toggleDiscovery()
            }
        }
    }

    SettingsSearch {
        width: parent.width
        placeholder: "Search paired or nearby devices"
        text: page.searchText
        onTextChanged: page.searchText = text
    }

    SettingsSection {
        width: parent.width
        title: "PAIRED DEVICES"
        description: "Devices trusted by this desktop"

        Repeater {
            id: pairedList
            model: service.filteredDevices(service.pairedDevices, page.searchText)

            delegate: SettingsRow {
                required property BluetoothDevice modelData
                width: parent.width
                label: modelData.name || modelData.address || "Bluetooth device"
                description: service.deviceDescription(modelData)
                selected: modelData.state === BluetoothDeviceState.Connected
                clickable: true
                onClicked: service.deviceAction(modelData)

                Row {
                    spacing: 8

                    StatePill {
                        text: modelData.state === BluetoothDeviceState.Connected
                            ? "CONNECTED" : "PAIRED"
                        tone: modelData.state === BluetoothDeviceState.Connected
                            ? "ok" : "accent"
                    }

                    HubButton {
                        label: service.actionLabel(modelData)
                        selected: modelData.state === BluetoothDeviceState.Connected
                        onClicked: service.deviceAction(modelData)
                    }

                    HubButton {
                        label: "FORGET"
                        destructive: true
                        onClicked: page.pendingForget = modelData
                    }
                }
            }
        }

        EmptyState {
            width: parent.width
            title: service.powered ? "NO PAIRED DEVICES" : "BLUETOOTH IS OFF"
            message: service.powered
                ? "Pair a device below to make it available here"
                : "Enable Bluetooth to see paired devices"
            visible: service.filteredDevices(service.pairedDevices, page.searchText).length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "AVAILABLE DEVICES"
        description: service.scanning
            ? "Nearby devices discovered by Bluetooth"
            : "Start discovery to look for nearby devices"

        Repeater {
            id: availableList
            model: service.filteredDevices(service.availableDevices, page.searchText)

            delegate: SettingsRow {
                required property BluetoothDevice modelData
                width: parent.width
                label: modelData.name || modelData.address || "Bluetooth device"
                description: service.deviceDescription(modelData)
                clickable: true
                onClicked: service.deviceAction(modelData)

                HubButton {
                    label: service.actionLabel(modelData)
                    onClicked: service.deviceAction(modelData)
                }
            }
        }

        EmptyState {
            width: parent.width
            title: service.scanning ? "SEARCHING" : "NO NEARBY DEVICES"
            message: service.powered
                ? "Keep this page open while Bluetooth scans"
                : "Enable Bluetooth and start a scan"
            visible: service.filteredDevices(service.availableDevices, page.searchText).length === 0
        }
    }

    ConfirmDialog {
        parent: page
        open: page.pendingForget !== null
        title: "Forget device"
        message: page.pendingForget
            ? "Remove " + (page.pendingForget.name || page.pendingForget.address) +
              " from this desktop? You will need to pair it again."
            : ""
        confirmText: "FORGET"
        destructive: true
        onCancelled: page.pendingForget = null
        onConfirmed: {
            service.forget(page.pendingForget)
            page.pendingForget = null
        }
    }
}

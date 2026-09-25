import QtQuick
import "../"

SettingsPage {
    id: page

    title: "NETWORK"
    subtitle: "Active connection, Wi-Fi networks, and wired status"
    statusText: service.statusText.toUpperCase()
    busy: service.errorText.length > 0

    property string searchText: ""

    function filteredNetworks() {
        const query = searchText.trim().toLowerCase()
        if (!query) return service.networks
        return service.networks.filter(network =>
            network.ssid.toLowerCase().includes(query)
            || network.device.toLowerCase().includes(query)
        )
    }

    NetworkService {
        id: service
    }

    SettingsSection {
        width: parent.width
        title: "ACTIVE CONNECTION"
        description: service.activeDevice || "No active network device"

        NetworkHero {
            width: parent.width
            connectionName: service.connectionName
            detail: service.activeNetwork
                ? service.activeNetwork.ssid + " · " + service.activeNetwork.signal + "% signal"
                : service.ethConnected ? "Wired network" : "Not connected"
            ipAddress: service.ipAddress
            downloadSpeed: service.downloadSpeed
            uploadSpeed: service.uploadSpeed
            wifi: service.activeNetwork !== null
            status: service.connected ? "CONNECTED" : "OFFLINE"
        }
    }

    SettingsSection {
        width: parent.width
        title: "WI-FI"
        description: "Wireless radio state and scanning"

        SettingsRow {
            label: "WIRELESS RADIO"
            description: service.wifiEnabled ? "Wi-Fi is enabled" : "Wi-Fi is disabled"
            selected: service.wifiEnabled

            HubButton {
                label: service.wifiEnabled ? "DISABLE" : "ENABLE"
                selected: service.wifiEnabled
                onClicked: service.setWifiEnabled(!service.wifiEnabled)
            }
        }

        SettingsRow {
            label: "VISIBLE NETWORKS"
            description: service.networks.length + " discovered"
            clickable: true
            onClicked: service.scan()

            HubButton {
                icon: ""
                label: "RESCAN"
                onClicked: service.scan()
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "AVAILABLE NETWORKS"
        description: "Connect, disconnect, or enter a Wi-Fi password"

        SettingsSearch {
            width: parent.width
            placeholder: "Search SSID or device"
            text: page.searchText
            onTextChanged: page.searchText = text
        }

        Repeater {
            id: networkList
            model: page.filteredNetworks()

            delegate: Column {
                required property var modelData
                width: networkList.width
                spacing: 8

                SettingsRow {
                    width: parent.width
                    label: modelData.ssid
                    description: modelData.device + " · " + modelData.signal + "% signal" +
                        (modelData.secured ? " · secured" : " · open")
                    selected: modelData.connected || service.pendingSsid === modelData.ssid
                    clickable: true
                    onClicked: {
                        if (modelData.connected) {
                            service.disconnect(modelData.ssid)
                        } else if (modelData.secured) {
                            service.pendingSsid = service.pendingSsid === modelData.ssid
                                ? ""
                                : modelData.ssid
                        } else {
                            service.connectOpen(modelData.ssid)
                        }
                    }

                    StatePill {
                        text: modelData.connected
                            ? "CONNECTED"
                            : service.pendingSsid === modelData.ssid ? "PASSWORD" : "CONNECT"
                        tone: modelData.connected ? "ok" : "accent"
                    }
                }

                Rectangle {
                    width: parent.width
                    height: visible ? 66 : 0
                    visible: service.pendingSsid === modelData.ssid && !modelData.connected
                    radius: Theme.radius
                    color: Theme.bgPanel
                    border.width: 1
                    border.color: Theme.accent
                    clip: true

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        TextInput {
                            id: passwordInput
                            width: parent.width - 150
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            echoMode: TextInput.Password
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                text: "Wi-Fi password"
                                visible: passwordInput.text.length === 0
                                color: Theme.textDim
                                font: passwordInput.font
                            }

                            Keys.onReturnPressed: connectButton.clicked()
                            Keys.onEnterPressed: connectButton.clicked()
                        }

                        HubButton {
                            id: connectButton
                            anchors.verticalCenter: parent.verticalCenter
                            label: "CONNECT"
                            onClicked: {
                                service.connectSecured(modelData.ssid, passwordInput.text)
                                passwordInput.text = ""
                            }
                        }
                    }
                }
            }
        }

        EmptyState {
            width: parent.width
            title: service.wifiEnabled ? "NO NETWORKS FOUND" : "WI-FI IS DISABLED"
            message: service.errorText || (
                page.searchText ? "No network matches your search" : "Scan again to discover networks"
            )
            error: service.errorText.length > 0
            visible: page.filteredNetworks().length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "ETHERNET"
        description: "Wired NetworkManager device status"

        SettingsRow {
            label: "WIRED CONNECTION"
            description: service.ethConnected
                ? "Connected through " + service.ethDevice
                : "No wired connection"
            selected: service.ethConnected

            StatePill {
                text: service.ethConnected ? "CONNECTED" : "OFFLINE"
                tone: service.ethConnected ? "ok" : "neutral"
            }
        }
    }
}

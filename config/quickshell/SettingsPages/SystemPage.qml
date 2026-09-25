import QtQuick
import "../"

SettingsPage {
    id: page

    title: "SYSTEM"
    subtitle: "Live hardware and session overview"
    statusText: telemetry.telemetryError ? "PARTIAL" : "LIVE"
    busy: telemetry.telemetryBusy

    SystemTelemetry {
        id: telemetry
    }

    Grid {
        id: metricGrid
        width: parent.width
        columns: 3
        spacing: 10

        MetricCard {
            width: (metricGrid.width - 20) / 3
            label: "CPU"
            valueText: Math.round(telemetry.cpuUsage) + "%"
            detail: telemetry.cpuTemp
            icon: ""
            history: telemetry.cpuHistory
        }

        MetricCard {
            width: (metricGrid.width - 20) / 3
            label: "GPU"
            valueText: Math.round(telemetry.gpuUsage) + "%"
            detail: telemetry.gpuTemp
            icon: ""
            history: telemetry.gpuHistory
        }

        MetricCard {
            width: (metricGrid.width - 20) / 3
            label: "MEMORY"
            valueText: Math.round(telemetry.memoryUsage) + "%"
            detail: telemetry.ramSpeed === "Loading" ? "LIVE" : telemetry.ramSpeed
            icon: ""
            history: telemetry.memoryHistory
        }
    }

    SettingsSection {
        width: parent.width
        title: "IDENTITY"
        description: "The machine currently running the kome desktop"

        Row {
            width: parent.width
            height: 112
            spacing: 18

            Rectangle {
                width: 96
                height: 96
                radius: Theme.radius
                color: Theme.bgPanel
                border.width: 1
                border.color: Theme.border

                Image {
                    anchors.centerIn: parent
                    source: telemetry.homeDir
                        ? "file://" + telemetry.homeDir + "/.config/quickshell/dino.svg"
                        : ""
                    width: 76
                    height: 76
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    asynchronous: true
                }
            }

            Column {
                width: parent.width - 114
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: telemetry.hostname
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: telemetry.os + " · Hyprland"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                StatePill {
                    text: telemetry.telemetryError ? "PARTIAL DATA" : "ALL SYSTEMS LIVE"
                    tone: telemetry.telemetryError ? "warning" : "ok"
                }
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "HARDWARE"
        description: "Detected components and current memory state"

        SettingsRow {
            label: "PROCESSOR"
            description: telemetry.cpu
            value: Math.round(telemetry.cpuUsage) + "%"
        }

        SettingsRow {
            label: "GRAPHICS"
            description: telemetry.gpu
            value: Math.round(telemetry.gpuUsage) + "%"
        }

        SettingsRow {
            label: "MEMORY"
            description: telemetry.ramSpeed
            value: telemetry.memory
        }
    }

    SettingsSection {
        width: parent.width
        title: "SESSION"
        description: "Operating system, kernel, uptime, and exportable summary"

        SettingsRow {
            label: "OPERATING SYSTEM"
            value: telemetry.os
        }

        SettingsRow {
            label: "KERNEL"
            value: telemetry.kernel
        }

        SettingsRow {
            label: "COMPOSITOR"
            value: "Hyprland"
            StatePill {
                text: "ACTIVE"
                tone: "ok"
            }
        }

        SettingsRow {
            label: "UPTIME"
            value: telemetry.uptime
        }

        SettingsRow {
            label: "TELEMETRY"
            description: "Refresh readings or copy a plaintext system summary"
            clickable: true
            onClicked: telemetry.copySummary()

            HubButton {
                icon: ""
                label: "COPY"
                onClicked: telemetry.copySummary()
            }
        }
    }
}

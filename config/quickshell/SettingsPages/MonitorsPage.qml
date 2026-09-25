import QtQuick
import "../"

SettingsPage {
    id: page

    title: "DISPLAY"
    subtitle: "Monitor selection, modes, layout, brightness, and night light"
    statusText: pageService.errorText
        ? "ERROR"
        : page.selectedMonitor ? page.selectedMonitor.name.toUpperCase() : "NO MONITOR"
    busy: pageService.errorText.length > 0

    property var monitors: pageService.monitors
    property string selectedName: ""

    readonly property var selectedMonitor: monitors.find(
        monitor => monitor.name === selectedName
    ) || null

    onMonitorsChanged: ensureSelection()

    function ensureSelection() {
        if (monitors.find(monitor => monitor.name === selectedName)) return
        const candidate = monitors.find(monitor => monitor.focused)
            || monitors.find(monitor => !monitor.disabled)
        selectedName = candidate ? candidate.name : ""
    }

    function isCurrentMode(mode) {
        if (!selectedMonitor || !mode) return false
        const parts = mode.split("@")
        const rate = parts[1]
        const geometry = selectedMonitor.width + "x" + selectedMonitor.height
        return parts[0] === geometry
            && !isNaN(parseFloat(rate))
            && Math.abs(parseFloat(rate) - selectedMonitor.refreshRate) < 0.01
    }

    DisplayService {
        id: pageService
    }
    SettingsSection {
        width: parent.width
        title: "MONITORS"
        description: "Select the monitor you want to configure"

        Repeater {
            model: page.monitors

            delegate: SettingsRow {
                required property var modelData
                label: modelData.name
                description: modelData.description || "Display output"
                selected: modelData.name === page.selectedName
                clickable: true
                onClicked: page.selectedName = modelData.name

                StatePill {
                    text: modelData.disabled
                        ? "OFF"
                        : modelData.focused ? "FOCUSED" : "ACTIVE"
                    tone: modelData.disabled ? "neutral" : modelData.focused ? "accent" : "ok"
                }
            }
        }

        EmptyState {
            width: parent.width
            title: pageService.errorText ? "MONITORS UNAVAILABLE" : "NO MONITORS"
            message: pageService.errorText || "Connect a display and refresh Hyprland"
            error: pageService.errorText.length > 0
            visible: page.monitors.length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "OUTPUT"
        description: page.selectedMonitor
            ? page.selectedMonitor.width + "×" + page.selectedMonitor.height +
              " at " + page.selectedMonitor.refreshRate.toFixed(2) + " Hz"
            : "Select a monitor above"

        visible: page.selectedMonitor !== null

        SettingsRow {
            label: "POWER"
            description: page.selectedMonitor?.disabled ? "Monitor is disabled" : "Monitor is enabled"
            selected: page.selectedMonitor ? !page.selectedMonitor.disabled : false

            HubButton {
                label: page.selectedMonitor?.disabled ? "ENABLE" : "DISABLE"
                selected: page.selectedMonitor ? !page.selectedMonitor.disabled : false
                onClicked: if (page.selectedMonitor) {
                    pageService.setEnabled(
                        page.selectedMonitor,
                        page.selectedMonitor.disabled
                    )
                }
            }
        }

        SettingsRow {
            label: "SCALE"
            description: page.selectedMonitor
                ? "Compositor scaling · " + page.selectedMonitor.scale.toFixed(2) + "×"
                : "Compositor scaling"
            value: page.selectedMonitor ? page.selectedMonitor.scale.toFixed(2) + "×" : "—"

            Slider {
                width: 240
                value: page.selectedMonitor
                    ? Math.max(0, Math.min(1, (page.selectedMonitor.scale - 0.7) / 0.6))
                    : 0
                onCommitted: value => {
                    if (page.selectedMonitor) pageService.setScale(
                        page.selectedMonitor,
                        0.7 + value * 0.6
                    )
                }
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "AVAILABLE MODES"
        description: "Resolution and refresh combinations reported by this monitor"
        visible: page.selectedMonitor !== null

        Flow {
            id: modeFlow
            width: parent.width
            spacing: 8

            Repeater {
                id: modeRepeater
                model: page.selectedMonitor?.availableModes || []

                delegate: HubButton {
                    required property var modelData
                    width: Math.max(
                        150,
                        (modeFlow.width - (modeRepeater.count - 1) * modeFlow.spacing)
                            / Math.max(1, modeRepeater.count)
                    )
                    label: modelData
                    selected: page.isCurrentMode(modelData)
                    onClicked: pageService.setMode(page.selectedMonitor, modelData)
                }
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "LAYOUT"
        description: "Position and mirror this monitor in the desktop layout"
        visible: page.selectedMonitor !== null

        SettingsRow {
            label: "POSITION X"
            value: page.selectedMonitor ? page.selectedMonitor.x + " px" : "—"
            enabled: page.selectedMonitor?.mirrorOf === "none"

            HubButton {
                label: "LEFT"
                onClicked: if (page.selectedMonitor) {
                    pageService.move(page.selectedMonitor, -50, 0)
                }
            }

            HubButton {
                label: "RIGHT"
                onClicked: if (page.selectedMonitor) {
                    pageService.move(page.selectedMonitor, 50, 0)
                }
            }
        }

        SettingsRow {
            label: "POSITION Y"
            value: page.selectedMonitor ? page.selectedMonitor.y + " px" : "—"
            enabled: page.selectedMonitor?.mirrorOf === "none"

            HubButton {
                label: "UP"
                onClicked: if (page.selectedMonitor) {
                    pageService.move(page.selectedMonitor, 0, -50)
                }
            }

            HubButton {
                label: "DOWN"
                onClicked: if (page.selectedMonitor) {
                    pageService.move(page.selectedMonitor, 0, 50)
                }
            }
        }

        SettingsRow {
            label: "MIRROR"
            description: page.selectedMonitor ? page.selectedMonitor.mirrorOf === "none" ? "Independent display" : "Mirrors " + page.selectedMonitor.mirrorOf : "No monitor selected"
            value: page.selectedMonitor?.mirrorOf || "none"
        }
    }

    SettingsSection {
        width: parent.width
        title: "COMFORT"
        description: "Brightness and gammastep night-light temperature"

        SettingsRow {
            label: "BRIGHTNESS"
            description: "Backlight output"
            value: Math.round(pageService.brightness * 100) + "%"

            Slider {
                width: 240
                value: pageService.brightness
                onCommitted: value => pageService.commitBrightness(value)
            }
        }

        SettingsRow {
            label: "NIGHT LIGHT"
            description: pageService.nightlightEnabled
                ? "Active at " + pageService.nightlightTemperature() + "K"
                : "Disabled"
            danger: pageService.nightlightEnabled

            HubButton {
                label: pageService.nightlightEnabled ? "DISABLE" : "ENABLE"
                selected: pageService.nightlightEnabled
                onClicked: pageService.setNightlight(!pageService.nightlightEnabled)
            }

            Slider {
                width: 190
                value: pageService.nightlight
                onCommitted: value => pageService.commitNightlight(value)
            }
        }
    }

    Component.onCompleted: ensureSelection()
}

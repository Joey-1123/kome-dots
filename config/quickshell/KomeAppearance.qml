import QtQuick

Rectangle {
    id: appearance

    required property string themePreset
    required property string themeMode
    required property string currentWallpaper
    property bool busy: false

    signal presetRequested(string preset)
    signal modeRequested(string mode)
    signal wallpaperRequested(string action)

    height: 366
    radius: Theme.radius
    color: Theme.bgCard
    border.width: 1
    border.color: Theme.border

    function wallpaperName(path) {
        if (!path) return "No wallpaper selected"
        return path.split("/").pop()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Text {
            text: "APPEARANCE"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 2
        }

        Row {
            width: parent.width
            spacing: 18

            Column {
                width: 290
                spacing: 12

                Text {
                    text: "COLOR PRESET"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "gruvbox" },
                            { name: "catppuccin-mocha" },
                            { name: "tokyo-night" }
                        ]

                        delegate: HubButton {
                            required property var modelData
                            width: (parent.width - 16) / 3
                            enabled: !appearance.busy
                            selected: appearance.themePreset === modelData.name
                            label: modelData.name === "catppuccin-mocha"
                                ? "Catppuccin"
                                : modelData.name === "tokyo-night"
                                    ? "Tokyo Night"
                                    : "Gruvbox"
                            onClicked: appearance.presetRequested(modelData.name)
                        }
                    }
                }

                Text {
                    text: "MODE"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { mode: "dark", label: "Dark" },
                            { mode: "light", label: "Light" }
                        ]

                        delegate: HubButton {
                            required property var modelData
                            width: (parent.width - 8) / 2
                            enabled: !appearance.busy
                            selected: appearance.themeMode === modelData.mode
                            label: modelData.label
                            onClicked: appearance.modeRequested(modelData.mode)
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 290 - 18
                height: 244
                radius: Theme.radius
                color: Theme.bgPanel
                border.width: 1
                border.color: Theme.border
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: appearance.currentWallpaper
                        ? "file://" + appearance.currentWallpaper
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    visible: status !== Image.Error && source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: appearance.currentWallpaper.length === 0
                    text: "No wallpaper preview"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 48
                    color: Theme.alpha(Theme.bg, 0.86)

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        text: appearance.wallpaperName(appearance.currentWallpaper)
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 8

            HubButton {
                width: (parent.width - 16) / 3
                enabled: !appearance.busy
                icon: ""
                label: "Choose"
                onClicked: appearance.wallpaperRequested("picker")
            }

            HubButton {
                width: (parent.width - 16) / 3
                enabled: !appearance.busy
                icon: ""
                label: "Next"
                onClicked: appearance.wallpaperRequested("next")
            }

            HubButton {
                width: (parent.width - 16) / 3
                enabled: !appearance.busy
                icon: ""
                label: "Random"
                onClicked: appearance.wallpaperRequested("random")
            }
        }
    }
}

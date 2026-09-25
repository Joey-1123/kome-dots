import QtQuick

Rectangle {
    id: quickActions

    property bool busy: false
    signal actionRequested(string action)

    height: 206
    radius: Theme.radius
    color: Theme.bgCard
    border.width: 1
    border.color: Theme.border

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: "QUICK ACTIONS"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 2
        }

        Grid {
            width: parent.width
            columns: 4
            spacing: 10

            Repeater {
                model: [
                    { id: "launcher", icon: "", label: "Launcher", description: "Open applications" },
                    { id: "files", icon: "", label: "Files", description: "Browse workspace" },
                    { id: "browser", icon: "", label: "Browser", description: "Open the web" },
                    { id: "clipboard", icon: "", label: "Clipboard", description: "Paste history" },
                    { id: "notifications", icon: "", label: "Notices", description: "Review alerts" },
                    { id: "screenshot", icon: "", label: "Capture", description: "Select an area" },
                    { id: "record", icon: "", label: "Record", description: "Toggle video" }
                ]

                delegate: HubActionTile {
                    required property var modelData
                    width: (quickActions.width - 54 - 30) / 4
                    height: 70
                    enabled: !quickActions.busy
                    icon: modelData.icon
                    label: modelData.label
                    description: modelData.description
                    onClicked: quickActions.actionRequested(modelData.id)
                }
            }
        }
    }
}

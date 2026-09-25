import QtQuick

Item {
    id: dialog

    property bool open: false
    property string title: ""
    property string message: ""
    property string confirmText: "CONFIRM"
    property string cancelText: "CANCEL"
    property bool destructive: false

    signal confirmed
    signal cancelled

    visible: open
    enabled: open
    z: 1000
    anchors.fill: parent

    onOpenChanged: if (open) cancelButton.forceActiveFocus()

    Behavior on opacity {
        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
    }

    opacity: open ? 1 : 0

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.cancelled()
    }

    Rectangle {
        width: Math.min(440, parent.width - 40)
        height: 190
        anchors.centerIn: parent
        radius: Theme.radius
        color: Theme.bgCard
        border.width: 1
        border.color: dialog.destructive ? Theme.danger : Theme.accent

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                width: parent.width
                text: dialog.title
                color: dialog.destructive ? Theme.danger : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: dialog.message
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Item {
                width: parent.width
                height: 38

                HubButton {
                    id: cancelButton
                    anchors.left: parent.left
                    width: (parent.width - 10) / 2
                    label: dialog.cancelText
                    onClicked: dialog.cancelled()
                }

                HubButton {
                    anchors.right: parent.right
                    width: (parent.width - 10) / 2
                    label: dialog.confirmText
                    destructive: dialog.destructive
                    onClicked: dialog.confirmed()
                }
            }
        }
    }

    Keys.onEscapePressed: dialog.cancelled()
}

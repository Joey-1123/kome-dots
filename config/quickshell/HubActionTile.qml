import QtQuick

Rectangle {
    id: tile

    required property string icon
    required property string label
    required property string description
    property bool hovered: false
    signal clicked

    activeFocusOnTab: enabled
    radius: Theme.radius
    color: tile.hovered || tile.activeFocus
        ? Theme.alpha(Theme.accent, 0.10)
        : Theme.alpha(Theme.bgPanel, 0.72)
    border.width: 1
    border.color: tile.activeFocus ? Theme.accent2 : Theme.border
    opacity: enabled ? 1 : 0.45

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 5

        Text {
            width: parent.width
            text: tile.icon
            color: Theme.accent2
            font.family: Theme.iconFont
            font.pixelSize: 19
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: tile.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: tile.description
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: tile.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.hovered = true
        onExited: tile.hovered = false
        onClicked: tile.clicked()
    }

    Keys.onReturnPressed: tile.clicked()
    Keys.onEnterPressed: tile.clicked()
}

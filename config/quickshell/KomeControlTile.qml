import QtQuick

Rectangle {
    id: tile

    required property string label
    required property string value
    required property string icon
    property bool active: false
    property bool busy: false

    signal clicked

    activeFocusOnTab: !busy
    height: 68
    radius: Theme.radius
    color: active
        ? Theme.alpha(Theme.accent, 0.12)
        : tile.activeFocus || hovered
            ? Theme.alpha(Theme.accent, 0.07)
            : Theme.bgPanel
    border.width: 1
    border.color: active || tile.activeFocus ? Theme.accent : Theme.border
    property bool hovered: false

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 3

        Text {
            text: tile.icon
            color: tile.active ? Theme.accent2 : Theme.textDim
            font.family: Theme.iconFont
            font.pixelSize: 15
        }

        Text {
            width: parent.width
            text: tile.label
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: tile.value
            color: tile.active ? Theme.accent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !tile.busy
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.hovered = true
        onExited: tile.hovered = false
        onClicked: tile.clicked()
    }

    Keys.onReturnPressed: if (!tile.busy) tile.clicked()
    Keys.onEnterPressed: if (!tile.busy) tile.clicked()
}

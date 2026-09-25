import QtQuick

Rectangle {
    id: button

    required property string label
    property string icon: ""
    property bool selected: false
    property bool destructive: false
    property bool hovered: false
    signal clicked

    activeFocusOnTab: enabled
    implicitHeight: 38
    implicitWidth: buttonContent.implicitWidth + 28
    radius: Theme.radius
    color: !enabled
        ? Theme.alpha(Theme.textFaint, 0.08)
        : selected
            ? Theme.alpha(Theme.accent, 0.18)
            : hovered || activeFocus
                ? Theme.alpha(Theme.accent, 0.09)
                : Theme.alpha(Theme.bgPanel, 0.72)
    border.width: 1
    border.color: button.activeFocus
        ? Theme.accent2
        : button.selected
            ? Theme.accent
            : Theme.border
    opacity: enabled ? 1 : 0.45

    Row {
        id: buttonContent
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: button.icon.length > 0
            text: button.icon
            color: button.destructive ? Theme.danger : Theme.accent2
            font.family: Theme.iconFont
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: button.label
            color: button.destructive ? Theme.danger : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: button.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: button.hovered = true
        onExited: button.hovered = false
        onClicked: button.clicked()
    }

    Keys.onReturnPressed: button.clicked()
    Keys.onEnterPressed: button.clicked()
}

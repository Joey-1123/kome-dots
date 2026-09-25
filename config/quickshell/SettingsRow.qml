import QtQuick

Rectangle {
    id: row

    required property string label
    property string description: ""
    property string value: ""
    property string icon: ""
    property bool clickable: false
    property bool selected: false
    property bool danger: false
    property bool hovered: false

    default property alias content: trailing.data
    signal clicked

    activeFocusOnTab: clickable
    implicitHeight: 58
    height: implicitHeight
    radius: Theme.radius
    color: danger
        ? Theme.alpha(Theme.danger, row.hovered || row.activeFocus ? 0.10 : 0.05)
        : selected
            ? Theme.alpha(Theme.accent, 0.12)
            : row.hovered || row.activeFocus
                ? Theme.alpha(Theme.accent, 0.07)
                : Theme.alpha(Theme.bgPanel, 0.62)
    border.width: 1
    border.color: row.activeFocus
        ? Theme.accent2
        : row.selected
            ? Theme.accent
            : Theme.border

    Row {
        id: leading
        anchors.left: parent.left
        anchors.right: trailing.left
        anchors.rightMargin: trailing.width > 0 ? 14 : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        spacing: 12

        Rectangle {
            width: 36
            height: 36
            radius: Theme.radius
            visible: row.icon.length > 0
            color: Theme.alpha(row.danger ? Theme.danger : Theme.accent, 0.12)
            border.width: 1
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: row.icon
                color: row.danger ? Theme.danger : Theme.accent2
                font.family: Theme.iconFont
                font.pixelSize: 14
            }
        }

        Column {
            width: parent.width - (row.icon.length > 0 ? 48 : 0)
            spacing: 3

            Text {
                width: parent.width
                text: row.label
                color: row.danger ? Theme.danger : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: row.description
                visible: text.length > 0
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: row.value.length > 0 && trailing.width === 0
        text: row.value
        color: row.danger ? Theme.danger : Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
    }

    Row {
        id: trailing
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }

    MouseArea {
        anchors.fill: parent
        enabled: row.clickable
        hoverEnabled: true
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: row.hovered = true
        onExited: row.hovered = false
        onClicked: row.clicked()
    }

    Keys.onReturnPressed: if (row.clickable) row.clicked()
    Keys.onEnterPressed: if (row.clickable) row.clicked()
}

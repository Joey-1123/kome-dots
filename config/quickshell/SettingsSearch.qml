import QtQuick

Rectangle {
    id: search

    property alias text: input.text
    property string placeholder: "Search"
    property bool focused: input.activeFocus

    signal accepted
    signal cleared

    activeFocusOnTab: true
    height: 42
    radius: Theme.radius
    color: Theme.bgPanel
    border.width: 1
    border.color: activeFocus ? Theme.accent2 : Theme.border

    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

    Text {
        id: searchIcon
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        color: Theme.accent2
        font.family: Theme.iconFont
        font.pixelSize: 13
    }

    TextInput {
        id: input
        anchors.left: searchIcon.right
        anchors.leftMargin: 10
        anchors.right: clearArea.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        selectByMouse: true
        clip: true

        Text {
            anchors.fill: parent
            text: search.placeholder
            visible: input.text.length === 0
            color: Theme.textDim
            font: input.font
        }

        Keys.onReturnPressed: search.accepted()
        Keys.onEnterPressed: search.accepted()
        Keys.onEscapePressed: {
            if (input.text.length > 0) input.text = ""
            else search.cleared()
        }
    }

    Item {
        id: clearArea
        width: 32
        height: parent.height
        anchors.right: parent.right

        Text {
            anchors.centerIn: parent
            text: ""
            visible: input.text.length > 0
            color: clearMouse.containsMouse ? Theme.text : Theme.textDim
            font.family: Theme.iconFont
            font.pixelSize: 11
        }

        MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (input.text.length > 0) input.text = ""
                input.forceActiveFocus()
            }
        }
    }
}

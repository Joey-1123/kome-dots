import QtQuick

Rectangle {
    id: section

    required property string title
    property string description: ""

    default property alias content: body.data

    height: body.implicitHeight + 36
    radius: Theme.radius
    color: Theme.bgCard
    border.width: 1
    border.color: Theme.border

    Column {
        id: body
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: section.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 2
        }

        Text {
            width: parent.width
            text: section.description
            visible: text.length > 0
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }
    }
}

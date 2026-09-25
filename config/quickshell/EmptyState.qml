import QtQuick

Rectangle {
    id: empty

    required property string title
    property string message: ""
    property string icon: "\uf05e"
    property bool loading: false
    property bool error: false

    default property alias content: actions.data

    height: 120
    radius: Theme.radius
    color: Theme.alpha(empty.error ? Theme.danger : Theme.accent, 0.05)
    border.width: 1
    border.color: Theme.alpha(empty.error ? Theme.danger : Theme.border, 0.8)

    Column {
        anchors.centerIn: parent
        width: parent.width - 36
        spacing: 7

        Text {
            width: parent.width
            text: empty.loading ? "..." : empty.icon
            color: empty.error ? Theme.danger : Theme.accent2
            font.family: Theme.iconFont
            font.pixelSize: empty.loading ? 18 : 20
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: empty.title
            color: empty.error ? Theme.danger : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: empty.message
            visible: text.length > 0
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Row {
        id: actions
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        spacing: 8
    }
}

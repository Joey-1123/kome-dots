import QtQuick

Rectangle {
    id: card

    required property string deviceName
    required property real volume
    required property bool muted
    property string icon: ""

    signal volumeCommitted(real value)
    signal muteClicked()

    height: 104
    radius: Theme.radius
    color: Theme.bgPanel
    border.width: 1
    border.color: muted ? Theme.danger : Theme.border

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Row {
            width: parent.width
            height: 38

            Text {
                width: parent.width - muteButton.width - 12
                text: card.deviceName
                color: card.muted ? Theme.danger : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }

            HubButton {
                id: muteButton
                anchors.verticalCenter: parent.verticalCenter
                icon: card.muted ? "" : card.icon
                label: card.muted ? "UNMUTE" : "MUTE"
                destructive: card.muted
                onClicked: card.muteClicked()
            }
        }

        Row {
            width: parent.width
            height: 34

            Text {
                width: 52
                text: Math.round(card.volume * 100) + "%"
                color: card.muted ? Theme.danger : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                width: parent.width - 52
                height: 34
                value: card.muted ? 0 : card.volume
                accentColor: card.muted ? Theme.danger : Theme.accent
                onCommitted: value => card.volumeCommitted(value)
            }
        }
    }
}

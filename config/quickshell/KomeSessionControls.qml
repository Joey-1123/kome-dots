import QtQuick

Rectangle {
    id: session

    property bool busy: false
    property string statusText: "Ready"
    property bool actionFailed: false

    signal lockRequested
    signal disruptiveRequested(string action)

    height: 222
    radius: Theme.radius
    color: Theme.bgCard
    border.width: 1
    border.color: Theme.border

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: "SESSION"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 2
        }

        HubButton {
            width: parent.width
            label: "LOCK SCREEN"
            enabled: !session.busy
            onClicked: session.lockRequested()
        }

        Grid {
            width: parent.width
            columns: 2
            spacing: 10

            HubButton {
                width: (session.width - 36 - 10) / 2
                label: "LOGOUT"
                destructive: true
                enabled: !session.busy
                onClicked: session.disruptiveRequested("logout")
            }

            HubButton {
                width: (session.width - 36 - 10) / 2
                label: "SUSPEND"
                destructive: true
                enabled: !session.busy
                onClicked: session.disruptiveRequested("suspend")
            }

            HubButton {
                width: (session.width - 36 - 10) / 2
                label: "REBOOT"
                destructive: true
                enabled: !session.busy
                onClicked: session.disruptiveRequested("reboot")
            }

            HubButton {
                width: (session.width - 36 - 10) / 2
                label: "SHUTDOWN"
                destructive: true
                enabled: !session.busy
                onClicked: session.disruptiveRequested("shutdown")
            }
        }

        Text {
            width: parent.width
            text: session.statusText
            color: session.actionFailed ? Theme.danger : Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }
}

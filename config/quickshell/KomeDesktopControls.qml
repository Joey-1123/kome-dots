import QtQuick

Rectangle {
    id: controls

    property bool busy: false
    property bool barRunning: false
    property bool gameMode: false
    property bool nightLight: false
    property real windowOpacity: 1
    property int updateCount: -1
    property string statusText: "Loading"
    property string actionOutput: ""
    property string doctorOutput: ""
    property bool actionFailed: false

    signal barRequested
    signal gameModeRequested
    signal nightLightRequested
    signal opacityRequested
    signal updatesRequested
    signal doctorRequested

    height: doctorOutput.length > 0 ? 370 : 324
    radius: Theme.radius
    color: Theme.bgCard
    border.width: 1
    border.color: Theme.border

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Row {
            width: parent.width
            height: 24

            Text {
                width: parent.width - 100
                text: "DESKTOP CONTROLS"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: 100
                text: controls.updateCount < 0
                    ? "Updates —"
                    : controls.updateCount + " updates"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Grid {
            width: parent.width
            columns: 2
            spacing: 10

            KomeControlTile {
                width: (controls.width - 36 - 10) / 2
                label: "STATUS BAR"
                value: controls.barRunning ? "Running" : "Hidden"
                icon: ""
                active: controls.barRunning
                busy: controls.busy
                onClicked: controls.barRequested()
            }

            KomeControlTile {
                width: (controls.width - 36 - 10) / 2
                label: "GAME MODE"
                value: controls.gameMode ? "On" : "Off"
                icon: ""
                active: controls.gameMode
                busy: controls.busy
                onClicked: controls.gameModeRequested()
            }

            KomeControlTile {
                width: (controls.width - 36 - 10) / 2
                label: "NIGHT LIGHT"
                value: controls.nightLight ? "On" : "Off"
                icon: ""
                active: controls.nightLight
                busy: controls.busy
                onClicked: controls.nightLightRequested()
            }

            KomeControlTile {
                width: (controls.width - 36 - 10) / 2
                label: "WINDOW OPACITY"
                value: Math.round(controls.windowOpacity * 100) + "%"
                icon: "◐"
                active: controls.windowOpacity < 1
                busy: controls.busy
                onClicked: controls.opacityRequested()
            }
        }

        Row {
            width: parent.width
            height: 38
            spacing: 10

            HubButton {
                width: (parent.width - 10) / 2
                label: "CHECK UPDATES"
                enabled: !controls.busy
                onClicked: controls.updatesRequested()
            }

            HubButton {
                width: (parent.width - 10) / 2
                label: "RUN DOCTOR"
                enabled: !controls.busy
                onClicked: controls.doctorRequested()
            }
        }

        Text {
            width: parent.width
            height: 18
            text: controls.actionOutput.length > 0
                ? controls.statusText + " · " + controls.actionOutput
                : controls.statusText
            color: controls.actionFailed ? Theme.danger : Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            height: visible ? 42 : 0
            visible: controls.doctorOutput.length > 0
            text: controls.doctorOutput
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: 9
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
        }
    }
}

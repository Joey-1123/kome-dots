import QtQuick

Rectangle {
    id: hero

    required property string connectionName
    required property string detail
    required property string ipAddress
    required property real downloadSpeed
    required property real uploadSpeed
    property bool wifi: true
    property string status: "OFFLINE"

    height: 120
    radius: Theme.radius
    color: Theme.bgPanel
    border.width: 1
    border.color: Theme.border

    function formatSpeed(bytes) {
        if (bytes < 1024) return Math.round(bytes) + " B/s"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB/s"
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(2) + " MB/s"
        return (bytes / 1024 / 1024 / 1024).toFixed(2) + " GB/s"
    }

    Row {
        id: heading
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        Rectangle {
            width: 44
            height: 44
            radius: Theme.radius
            color: Theme.alpha(Theme.accent, 0.12)
            border.width: 1
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: hero.wifi ? "" : "󰈅"
                color: Theme.accent2
                font.family: Theme.iconFont
                font.pixelSize: 17
            }
        }

        Column {
            width: parent.width - 56 - statusPill.width
            spacing: 4

            Text {
                width: parent.width
                text: hero.connectionName
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: hero.detail
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: hero.ipAddress || "No IPv4 address"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        StatePill {
            id: statusPill
            anchors.verticalCenter: parent.verticalCenter
            text: hero.status
            tone: hero.status === "CONNECTED" ? "ok" : "neutral"
        }
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 14
        spacing: 18

        Text {
            width: parent.width / 2
            text: " " + hero.formatSpeed(hero.downloadSpeed)
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            width: parent.width / 2
            text: " " + hero.formatSpeed(hero.uploadSpeed)
            color: Theme.accent2
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
            horizontalAlignment: Text.AlignRight
        }
    }
}

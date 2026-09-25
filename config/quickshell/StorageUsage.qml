import QtQuick

Rectangle {
    id: usage

    required property string label
    required property string detail
    required property real used
    required property real available
    required property real total
    required property real percent

    readonly property real ratio: Math.max(0, Math.min(1, percent / 100))
    readonly property color barColor: percent >= 90
        ? Theme.danger
        : percent >= 75 ? Theme.accent2 : Theme.accent

    height: 88
    radius: Theme.radius
    color: Theme.bgPanel
    border.width: 1
    border.color: Theme.border

    function formatBytes(bytes) {
        if (!isFinite(bytes) || bytes < 0) return "0 B"
        const units = ["B", "KB", "MB", "GB", "TB"]
        let value = bytes
        let index = 0
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024
            index++
        }
        return (index ? value.toFixed(1) : Math.round(value)) + " " + units[index]
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Row {
            width: parent.width
            height: 20

            Text {
                width: parent.width - 62
                text: usage.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: 54
                text: Math.round(usage.percent) + "%"
                color: usage.barColor
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: Theme.alpha(Theme.text, 0.10)

            Rectangle {
                width: parent.width * usage.ratio
                height: parent.height
                radius: 3
                color: usage.barColor
                Behavior on width {
                    NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            width: parent.width
            text: usage.detail
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            height: 14
            spacing: 12

            Text {
                text: usage.formatBytes(usage.used) + " USED"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            Text {
                text: usage.formatBytes(usage.available) + " FREE"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            Text {
                width: parent.width - 180
                text: usage.formatBytes(usage.total) + " TOTAL"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

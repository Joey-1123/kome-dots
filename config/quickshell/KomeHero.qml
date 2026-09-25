import QtQuick

Rectangle {
    id: hero

    required property string dateText
    required property string clockText
    required property string themeLabel
    required property string updateText

    height: 142
    radius: Theme.radius
    color: Theme.alpha(Theme.bgCard, 0.94)
    border.width: 1
    border.color: Theme.border

    Row {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 28

        Column {
            width: 270
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: hero.dateText.toUpperCase()
                color: Theme.accent2
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                text: hero.clockText
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 42
                font.bold: true
                font.letterSpacing: 1
            }

            Text {
                text: "Your desktop, one control surface."
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 12
                width: parent.width
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: Theme.border
        }

        Column {
            width: parent.width - 270 - 28
            height: parent.height
            spacing: 14
            anchors.verticalCenter: parent.verticalCenter

            Row {
                width: parent.width
                height: 42

                Rectangle {
                    width: 42
                    height: 42
                    radius: Theme.radius
                    color: Theme.alpha(Theme.accent, 0.14)
                    border.width: 1
                    border.color: Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.accent2
                        font.family: Theme.iconFont
                        font.pixelSize: 17
                    }
                }

                Column {
                    width: parent.width - 58
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "ACTIVE THEME"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 2
                    }

                    Text {
                        width: parent.width
                        text: hero.themeLabel
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Text {
                width: parent.width
                text: hero.updateText
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}

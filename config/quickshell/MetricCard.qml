import QtQuick

Rectangle {
    id: card

    required property string label
    required property string valueText
    property string detail: ""
    property string icon: ""
    property var history: []
    property bool loading: false

    height: 134
    radius: Theme.radius
    color: Theme.bgCard
    border.width: 1
    border.color: Theme.border

    function normalized(value) {
        const number = Number(value)
        if (isNaN(number)) return 0
        return Math.max(0, Math.min(1, number / 100))
    }

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 9

        Text {
            visible: card.icon.length > 0
            text: card.icon
            color: Theme.accent2
            font.family: Theme.iconFont
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            width: parent.width - statusPill.width - (card.icon.length > 0 ? 23 : 0)
            text: card.label
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 2
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        StatePill {
            id: statusPill
            anchors.verticalCenter: parent.verticalCenter
            visible: card.loading || card.detail.length > 0
            text: card.loading ? "LOADING" : card.detail
            tone: card.loading ? "accent" : "neutral"
        }
    }

    Text {
        id: value
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 6
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        text: card.valueText
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 25
        font.bold: true
        elide: Text.ElideRight
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 12
        height: 34

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.alpha(Theme.border, 0.65)
        }

        Repeater {
            model: card.loading ? [] : card.history

            delegate: Rectangle {
                required property int index
                required property var modelData

                width: 2
                height: Math.max(2, parent.height * card.normalized(modelData))
                x: card.history.length > 1
                    ? index / (card.history.length - 1) * (parent.width - width)
                    : 0
                y: parent.height - height
                radius: 1
                color: Theme.accent2
            }
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: card.history.length > 0 ? "NOW" : "NO HISTORY"
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: 8
            font.letterSpacing: 1
        }
    }
}

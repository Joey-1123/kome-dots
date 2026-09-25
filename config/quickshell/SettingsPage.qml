import QtQuick

Item {
    id: page

    required property string title
    property string subtitle: ""
    property string statusText: ""
    property bool busy: false

    default property alias content: body.data

    Component.onCompleted: body.forceLayout()

    Flickable {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: body.childrenRect.height + 18
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: scroll.width
            spacing: 16
            bottomPadding: 18
            onChildrenChanged: forceLayout()

            Item {
                width: parent.width
                height: 52

                Column {
                    anchors.left: parent.left
                    anchors.right: statusPill.left
                    anchors.rightMargin: statusPill.visible ? 12 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: page.title
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.bold: true
                        font.letterSpacing: 3
                    }

                    Text {
                        width: parent.width
                        text: page.subtitle
                        visible: text.length > 0
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                StatePill {
                    id: statusPill
                    visible: page.statusText.length > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.busy ? "WORKING" : page.statusText
                    tone: page.busy ? "accent" : "neutral"
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }
        }
    }
}

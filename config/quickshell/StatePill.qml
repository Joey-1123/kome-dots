import QtQuick

Rectangle {
    id: pill

    required property string text
    property string tone: "neutral"

    readonly property color toneColor: tone === "danger"
        ? Theme.danger
        : tone === "ok"
            ? Theme.ok
            : tone === "warning"
                ? Theme.accent2
                : tone === "accent"
                    ? Theme.accent
                    : Theme.textDim

    height: 24
    implicitWidth: label.implicitWidth + 20
    radius: height / 2
    color: Theme.alpha(toneColor, 0.12)
    border.width: 1
    border.color: Theme.alpha(toneColor, 0.55)

    Text {
        id: label
        anchors.centerIn: parent
        text: pill.text
        color: pill.toneColor
        font.family: Theme.fontFamily
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 1
    }
}

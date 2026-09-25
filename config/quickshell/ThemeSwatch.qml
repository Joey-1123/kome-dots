import QtQuick

// A miniature terminal painted with a theme's own background, text, and accent
// colours (the kitty cursor, the bar highlight). Colours arrive as "#rrggbb"
// strings from kome-kitty-theme and kome-bar-theme; an empty value falls back to
// a shared token so a theme without colours stays readable.
Rectangle {
    id: swatch

    property string background: ""
    property string foreground: ""
    property string accent: ""

    readonly property color backgroundColor: paint(background, Theme.alpha(Theme.textDim, 0.18))
    readonly property color foregroundColor: paint(foreground, Theme.textDim)
    readonly property color accentColor: paint(accent, Theme.accent)

    function paint(value, fallback) {
        return value && value.length > 0 ? value : fallback
    }

    width: 46
    height: 28
    radius: Theme.radius
    color: backgroundColor
    border.width: 1
    border.color: Theme.border

    Rectangle {
        x: 6
        y: 8
        width: 22
        height: 3
        radius: 1.5
        color: Theme.alpha(foregroundColor, 0.85)
    }

    Rectangle {
        x: 6
        y: 15
        width: 14
        height: 3
        radius: 1.5
        color: Theme.alpha(foregroundColor, 0.55)
    }

    Rectangle {
        x: 23
        y: 14
        width: 3
        height: 5
        radius: 1
        color: accentColor
    }
}

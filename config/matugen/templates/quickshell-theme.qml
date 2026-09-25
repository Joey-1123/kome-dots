// kome — generated from the active palette. Do not edit; run `kome-theme apply`.
pragma Singleton
import QtQuick

QtObject {
    readonly property color bg: "{{colors.surface.default.hex}}"
    readonly property color text: "{{colors.on_surface.default.hex}}"
    readonly property color textDim: "{{colors.on_surface_variant.default.hex}}"
    readonly property int radius: 6

    readonly property color danger: "{{colors.error.default.hex}}"
    readonly property color accent: "{{colors.primary.default.hex}}"
    readonly property color accent2: "{{colors.tertiary.default.hex}}"
    readonly property color border: "{{colors.outline_variant.default.hex}}"

    readonly property color bgPanel: "{{colors.surface_container.default.hex}}"
    readonly property color bgCard: "{{colors.surface_container_low.default.hex}}"
    readonly property color borderAccent: "{{colors.outline.default.hex}}"
    readonly property color textFaint: "{{colors.outline.default.hex}}"
    readonly property color ok: "{{colors.tertiary.default.hex}}"
    readonly property color trackBg: "{{colors.surface_container_high.default.hex}}"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    property string iconFont: "JetBrainsMono Nerd Font"

    readonly property int animFast: 120
    readonly property int animMed: 220
    readonly property int animSlow: 380

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}

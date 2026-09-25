import Quickshell
import QtQuick

// Panel chrome for the kome hub.
//
// Motion budget: this opens tens of times a day, usually from a keybind, so
// the entrance is near-instant and only the transform/opacity pair animates.
// No bounce, no 20-degree tilt — those read as "showcase" on something you
// open constantly. The hover parallax stays because it is the one cue that
// sells the panel as a physical surface, and it settles fast.
//
// Set KOME_REDUCED_MOTION=1 to drop all movement and keep opacity only.
Item {
    id: root

    default property alias content: contentContainer.data

    property bool open: false
    // Degrees of hover parallax. Small on purpose: frequent interaction.
    property real tiltStrength: 2.5
    property real parallaxX: 0
    property real parallaxY: 0

    readonly property bool reducedMotion:
        Quickshell.env("KOME_REDUCED_MOTION") === "1"

    readonly property real enterMs: reducedMotion ? 0 : 180

    opacity: open ? 1 : 0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: root.reducedMotion ? 120 : 180
            easing.type: Easing.OutCubic
        }
    }

    // Entrance is a small lift toward the viewer, not a warp. scale(0.96)
    // is the floor — scale(0) reads as a rendering glitch.
    readonly property real restScale: 1
    readonly property real closedScale: reducedMotion ? 1 : 0.96
    readonly property real restLift: 0
    readonly property real closedLift: reducedMotion ? 0 : 10

    transform: [
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root.open ? root.restScale : root.closedScale
            yScale: root.open ? root.restScale : root.closedScale

            Behavior on xScale {
                NumberAnimation {
                    duration: root.enterMs
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    duration: root.enterMs
                    easing.type: Easing.OutCubic
                }
            }
        },
        Translate {
            y: root.open ? root.restLift : root.closedLift

            Behavior on y {
                NumberAnimation {
                    duration: root.enterMs
                    easing.type: Easing.OutCubic
                }
            }
        },
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: root.parallaxX

            Behavior on angle {
                NumberAnimation {
                    duration: root.reducedMotion ? 0 : 160
                    easing.type: Easing.OutCubic
                }
            }
        },
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: root.parallaxY

            Behavior on angle {
                NumberAnimation {
                    duration: root.reducedMotion ? 0 : 160
                    easing.type: Easing.OutCubic
                }
            }
        }
    ]

    HoverHandler {
        id: hover
        onPointChanged: {
            if (root.reducedMotion) return
            var nx = (point.position.x / root.width) - 0.5
            var ny = (point.position.y / root.height) - 0.5
            root.parallaxX = -ny * root.tiltStrength
            root.parallaxY = nx * root.tiltStrength
        }
        onHoveredChanged: {
            if (!hovered) {
                root.parallaxX = 0
                root.parallaxY = 0
            }
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}

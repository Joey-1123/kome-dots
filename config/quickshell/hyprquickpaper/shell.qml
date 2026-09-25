import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Wayland

PanelWindow {
    id: main

    // ---- Settings ----
    // Wallpaper to preselect when the rail opens.
    property int startPosition: 0

    // Resolved once, used to expand relative paths from config.json
    readonly property string homeDir: Quickshell.env("HOME")

    // Full-screen overlay: dimmed backdrop, vertical rail on the left,
    // large hover preview filling the rest.
    implicitHeight: Screen.height
    implicitWidth: Screen.width
    color: "#C4000000"
    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted:
        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("cache.sh"),
            Quickshell.shellDir
        ])

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures
            property string border_color
        }
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + main.homeDir + "/" + configs.wallpaper_path
        showDirs: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
    }

    // Hover preview — the full-resolution wallpaper, so the user sees the
    // real thing before applying it.
    Image {
        id: preview
        anchors.left: rail.right
        anchors.leftMargin: 48
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: source != ""
        source: rail.hoverIndex >= 0 && rail.hoverIndex < folderModel.count
                ? folderModel.get(rail.hoverIndex, "filePath")
                : ""
    }

    Text {
        anchors.centerIn: preview
        visible: preview.source === ""
        text: folderModel.count === 0 ? "No wallpapers found" : "Hover a wallpaper to preview"
        color: "#88ffffff"
        font.pixelSize: 22
    }

    // Vertical thumbnail rail on the left edge.
    ListView {
        id: rail
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        width: 190
        height: Math.min(parent.height - 80,
                         Math.max(count, 1) * (tileHeight + spacing))
        focus: true
        model: folderModel
        orientation: ListView.Vertical
        spacing: 10
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        readonly property real tileHeight: 108
        property int selectedIndex: 0
        // Index the pointer is over; -1 until the model loads.
        property int hoverIndex: -1

        onCountChanged: {
            if (count > 0) {
                selectedIndex = Math.max(0, Math.min(main.startPosition, count - 1))
                hoverIndex = selectedIndex
                positionViewAtIndex(selectedIndex, ListView.Contain)
            }
        }

        function activateCurrent() {
            if (selectedIndex < 0 || selectedIndex >= count)
                return
            Quickshell.execDetached([
                "bash",
                Quickshell.shellPath("commands.sh"),
                folderModel.get(selectedIndex, "filePath")
            ])
            Qt.quit()
        }

        delegate: Item {
            id: tile
            width: rail.width
            height: rail.tileHeight

            readonly property bool active: index === rail.selectedIndex

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#33000000"
                border.width: tile.active ? 3 : 1
                border.color: tile.active ? configs.border_color : "#33ffffff"
            }

            Image {
                id: thumb
                anchors.fill: parent
                anchors.margins: 4
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                // Join explicitly: config paths carry no trailing slash, and
                // concatenating without one yields ".../thumbs01.png".
                source: "file://" +
                        main.homeDir + "/" +
                        configs.cache_path.replace(/\/+$/, "") + "/" +
                        fileName
            }

            Text {
                anchors.centerIn: parent
                visible: thumb.status === Image.Error || thumb.status === Image.Loading
                text: "…"
                color: "#88ffffff"
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    rail.hoverIndex = index
                    rail.selectedIndex = index
                }

                onClicked: rail.activateCurrent()

                onWheel: function(wheel) {
                    rail.flick(0, -wheel.angleDelta.y * 8)
                    wheel.accepted = true
                }
            }
        }

        Keys.onPressed: function(event) {
            switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                activateCurrent()
                break
            case Qt.Key_W:
            case Qt.Key_Escape:
                Qt.quit()
                break
            case Qt.Key_Down:
                rail.selectedIndex = Math.min(rail.selectedIndex + 1, count - 1)
                rail.hoverIndex = rail.selectedIndex
                rail.positionViewAtIndex(rail.selectedIndex, ListView.Contain)
                break
            case Qt.Key_Up:
                rail.selectedIndex = Math.max(rail.selectedIndex - 1, 0)
                rail.hoverIndex = rail.selectedIndex
                rail.positionViewAtIndex(rail.selectedIndex, ListView.Contain)
                break
            default:
                return
            }
            event.accepted = true
        }
    }
}

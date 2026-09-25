import QtQuick
import "../"

SettingsPage {
    id: page

    title: "SHORTCUTS"
    subtitle: "Search the canonical Kome keybind reference"
    statusText: service.loading
        ? "LOADING"
        : service.errorText ? "ERROR" : service.filtered(page.searchText).length + " BINDS"
    busy: service.loading

    property string searchText: ""
    onSearchTextChanged: resetScroll()

    ShortcutService {
        id: service
    }

    Connections {
        target: service
        function onBindsChanged() {
            Qt.callLater(page.resetScroll)
        }
    }

    SettingsSearch {
        width: parent.width
        placeholder: "Search keys or descriptions"
        text: page.searchText
        onTextChanged: page.searchText = text
    }

    SettingsSection {
        width: parent.width
        title: "KEYBINDS"
        description: "Installed actions from kome-keybinds --list"

        Repeater {
            id: shortcutList
            model: service.filtered(page.searchText)

            delegate: SettingsRow {
                required property var modelData
                width: parent.width
                label: modelData.key
                description: modelData.description

                StatePill {
                    text: "BIND"
                    tone: "accent"
                }
            }
        }

        EmptyState {
            width: parent.width
            title: service.loading
                ? "LOADING KEYBINDS"
                : service.errorText ? "KEYBINDS UNAVAILABLE" : "NO MATCHES"
            message: service.loading
                ? "Reading the installed keybind reference"
                : service.errorText || "Try a different key or description"
            error: service.errorText.length > 0
            visible: service.loading || service.errorText.length > 0
                || service.filtered(page.searchText).length === 0
        }
    }
}

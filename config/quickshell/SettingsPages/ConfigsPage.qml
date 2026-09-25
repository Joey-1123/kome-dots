import QtQuick
import "../"

SettingsPage {
    id: page

    title: "CONFIGS"
    subtitle: "Open the files that shape your desktop, pick the terminal theme"
    statusText: service.statusText.toUpperCase()
    busy: service.busy

    property string searchText: ""
    onSearchTextChanged: resetScroll()

    ConfigService {
        id: service
    }

    SettingsSearch {
        width: parent.width
        placeholder: "Search config names or paths"
        text: page.searchText
        onTextChanged: page.searchText = text
    }

    Repeater {
        id: sectionList
        model: service.filteredSections(page.searchText)

        delegate: SettingsSection {
            required property var modelData
            width: parent.width
            title: modelData.title
            description: modelData.description

            Repeater {
                model: modelData.items

                delegate: SettingsRow {
                    required property var modelData
                    width: parent.width
                    label: modelData.label
                    description: modelData.action === "kitty-theme"
                        ? modelData.description
                        : service.pathExists(modelData.path)
                            ? modelData.path
                            : modelData.path + " · not installed"
                    selected: modelData.action === "kitty-theme"
                        && service.kittyTheme === modelData.value
                    clickable: modelData.action === "kitty-theme"
                        ? !service.busy
                        : service.pathExists(modelData.path)
                    onClicked: modelData.action === "kitty-theme"
                        ? service.applyKittyTheme(modelData.value)
                        : service.open(modelData.path)

                    ThemeSwatch {
                        visible: modelData.action === "kitty-theme"
                        background: modelData.background || ""
                        foreground: modelData.foreground || ""
                        cursor: modelData.cursor || ""
                    }

                    StatePill {
                        visible: modelData.action === "kitty-theme"
                        text: service.pendingTheme === modelData.value && service.busy
                            ? "APPLYING"
                            : service.kittyTheme === modelData.value
                                ? "ACTIVE"
                                : "APPLY"
                        tone: service.kittyTheme === modelData.value ? "accent" : "neutral"
                    }

                    StatePill {
                        visible: modelData.action !== "kitty-theme"
                        text: service.pathExists(modelData.path) ? "OPEN" : "MISSING"
                        tone: service.pathExists(modelData.path) ? "accent" : "warning"
                    }
                }
            }
        }
    }

    EmptyState {
        width: parent.width
        title: "NO CONFIGS FOUND"
        message: page.searchText
            ? "No config matches your search"
            : "No config launchers are available"
        visible: service.filteredSections(page.searchText).length === 0
    }
}

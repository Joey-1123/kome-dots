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
                    description: modelData.action
                        ? modelData.description
                        : service.pathExists(modelData.path)
                            ? modelData.path
                            : modelData.path + " · not installed"
                    selected: modelData.action
                        && service.activeTheme(modelData.action) === modelData.value
                    clickable: modelData.action
                        ? !service.busy
                        : service.pathExists(modelData.path)
                    onClicked: {
                        if (modelData.action === "kitty-theme") {
                            service.applyKittyTheme(modelData.value)
                        } else if (modelData.action === "bar-theme") {
                            service.applyBarTheme(modelData.value)
                        } else {
                            service.open(modelData.path)
                        }
                    }

                    ThemeSwatch {
                        visible: modelData.action !== undefined
                        background: modelData.background || ""
                        foreground: modelData.foreground || ""
                        accent: modelData.accent || ""
                    }

                    StatePill {
                        visible: modelData.action !== undefined
                        text: service.pendingThemeFor(modelData.action) === modelData.value
                            && service.busy
                            ? "APPLYING"
                            : service.activeTheme(modelData.action) === modelData.value
                                ? "ACTIVE"
                                : "APPLY"
                        tone: service.activeTheme(modelData.action) === modelData.value
                            ? "accent"
                            : "neutral"
                    }

                    StatePill {
                        visible: modelData.action === undefined
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

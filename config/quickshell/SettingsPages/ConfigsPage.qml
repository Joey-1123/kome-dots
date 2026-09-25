import QtQuick
import "../"

SettingsPage {
    id: page

    title: "CONFIGS"
    subtitle: "Open the files that shape your desktop"
    statusText: service.statusText.toUpperCase()
    busy: false

    property string searchText: ""

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
                    description: service.pathExists(modelData.path)
                        ? modelData.path
                        : modelData.path + " · not installed"
                    clickable: service.pathExists(modelData.path)
                    onClicked: service.open(modelData.path)

                    StatePill {
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

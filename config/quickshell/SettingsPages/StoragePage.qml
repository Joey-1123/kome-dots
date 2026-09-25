import QtQuick
import "../"

SettingsPage {
    id: page

    title: "STORAGE"
    subtitle: "Capacity, drives, and confirmed cleanup actions"
    statusText: service.errorText ? "ERROR" : service.busy ? "UPDATING" : service.statusText.toUpperCase()
    busy: service.busy

    property var pendingCleanup: null

    StorageService {
        id: service
    }

    SettingsSection {
        width: parent.width
        title: "FILESYSTEMS"
        description: "Mounted capacity reported by the kernel"

        Repeater {
            id: filesystemList
            model: service.filesystems

            delegate: StorageUsage {
                required property var modelData
                width: parent.width
                label: modelData.mount
                detail: modelData.filesystem
                used: modelData.used
                available: modelData.available
                total: modelData.total
                percent: modelData.percent
            }
        }

        EmptyState {
            width: parent.width
            title: service.errorText ? "FILESYSTEMS UNAVAILABLE" : "NO FILESYSTEMS"
            message: service.errorText || "Mounted filesystems will appear here"
            error: service.errorText.length > 0
            visible: service.filesystems.length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "DRIVES"
        description: "Physical devices and their mounted capacity"

        Repeater {
            id: driveList
            model: service.drives

            delegate: StorageUsage {
                id: driveUsage
                required property var modelData
                property var usage: service.usageForDisk(modelData)

                width: parent.width
                label: modelData.model || modelData.name || "Drive"
                detail: "/dev/" + modelData.name + (modelData.tran ? "  ·  " + modelData.tran : "")
                used: usage.used
                available: usage.available
                total: usage.total
                percent: usage.percent
            }
        }

        EmptyState {
            width: parent.width
            title: "NO DRIVES REPORTED"
            message: "Drive inventory will appear when lsblk responds"
            visible: service.drives.length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "CLEANUP"
        description: "Every destructive action asks for confirmation first"

        Repeater {
            id: cleanupList
            model: service.cleanupActions

            delegate: SettingsRow {
                required property var modelData
                width: parent.width
                label: modelData.label
                description: modelData.key === "yay"
                    ? service.formatBytes(service.cleanupInfo.yay) + " cached"
                    : service.cleanupMessage(modelData)
                value: service.formatBytes(service.cleanupInfo[modelData.key])
                danger: true
                clickable: true
                onClicked: page.pendingCleanup = modelData

                HubButton {
                    label: modelData.action
                    destructive: true
                    onClicked: page.pendingCleanup = modelData
                }
            }
        }

        EmptyState {
            width: parent.width
            title: "NO CLEANUP ACTIONS"
            message: "Cleanup tools will appear when storage data is available"
            visible: service.cleanupActions.length === 0
        }
    }

    ConfirmDialog {
        parent: page
        open: page.pendingCleanup !== null
        title: page.pendingCleanup ? page.pendingCleanup.title : "Confirm cleanup"
        message: page.pendingCleanup
            ? service.cleanupMessage(page.pendingCleanup)
            : ""
        confirmText: page.pendingCleanup ? page.pendingCleanup.action : "CONFIRM"
        destructive: true
        onCancelled: page.pendingCleanup = null
        onConfirmed: {
            if (page.pendingCleanup) service.runCleanup(page.pendingCleanup.key)
            page.pendingCleanup = null
        }
    }
}

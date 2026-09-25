import QtQuick
import Quickshell.Services.Pipewire
import "../"

SettingsPage {
    id: page

    title: "AUDIO"
    subtitle: "PipeWire output, input, routing, and application streams"
    statusText: page.outputSinks.length === 0
        ? "NO OUTPUT"
        : page.appStreams.length + " ACTIVE STREAMS"

    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var outputSinks: Pipewire.nodes.values.filter(
        node => node.isSink && !node.isStream && node.audio
    )
    readonly property var inputSources: Pipewire.nodes.values.filter(
        node => !node.isSink && !node.isStream && node.audio
    )
    readonly property var appStreams: Pipewire.nodes.values.filter(
        node => node.isStream && node.isSink
    )

    function displayName(node) {
        if (!node) return "Unknown device"
        return node.description || node.nickname || node.name || "Unknown device"
    }

    function setOutputVolume(value) {
        if (!sink || !sink.audio) return
        sink.audio.muted = false
        sink.audio.volume = value
    }

    function setInputVolume(value) {
        if (!source || !source.audio) return
        source.audio.muted = false
        source.audio.volume = value
    }

    SettingsSection {
        width: parent.width
        title: "DEFAULT OUTPUT"
        description: "Primary speakers or headphones"

        DefaultAudioCard {
            width: parent.width
            icon: ""
            deviceName: page.displayName(page.sink)
            volume: page.sink?.audio?.volume || 0
            muted: page.sink?.audio?.muted || false
            onVolumeCommitted: value => page.setOutputVolume(value)
            onMuteClicked: if (page.sink?.audio) {
                page.sink.audio.muted = !page.sink.audio.muted
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "OUTPUT DEVICES"
        description: "Click a device to make it the default output"

        Repeater {
            model: page.outputSinks

            delegate: SettingsRow {
                required property var modelData
                label: page.displayName(modelData)
                description: modelData === page.sink ? "Current default output" : "Available output"
                selected: modelData === page.sink
                clickable: true
                onClicked: Pipewire.preferredDefaultAudioSink = modelData

                StatePill {
                    text: modelData === page.sink ? "ACTIVE" : "AVAILABLE"
                    tone: modelData === page.sink ? "ok" : "neutral"
                }
            }
        }

        EmptyState {
            width: parent.width
            title: "NO AUDIO OUTPUTS"
            message: "Connect a speaker, headphones, or audio device"
            visible: page.outputSinks.length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "DEFAULT INPUT"
        description: "Microphone or line-in used by applications"

        DefaultAudioCard {
            width: parent.width
            icon: ""
            deviceName: page.displayName(page.source)
            volume: page.source?.audio?.volume || 0
            muted: page.source?.audio?.muted || false
            onVolumeCommitted: value => page.setInputVolume(value)
            onMuteClicked: if (page.source?.audio) {
                page.source.audio.muted = !page.source.audio.muted
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "INPUT DEVICES"
        description: "Click a device to make it the default input"

        Repeater {
            model: page.inputSources

            delegate: SettingsRow {
                required property var modelData
                label: page.displayName(modelData)
                selected: modelData === page.source
                clickable: true
                onClicked: Pipewire.preferredDefaultAudioSource = modelData

                StatePill {
                    text: modelData === page.source ? "ACTIVE" : "AVAILABLE"
                    tone: modelData === page.source ? "ok" : "neutral"
                }
            }
        }

        EmptyState {
            width: parent.width
            title: "NO AUDIO INPUTS"
            message: "Connect a microphone or line-in device"
            visible: page.inputSources.length === 0
        }
    }

    SettingsSection {
        width: parent.width
        title: "APPLICATION STREAMS"
        description: "Volume and mute controls for active PipeWire streams"

        Repeater {
            model: page.appStreams

            delegate: SettingsRow {
                required property var modelData
                label: page.displayName(modelData)
                description: modelData?.target?.mediaClass || "Audio stream"
                danger: modelData?.audio?.muted || false

                Slider {
                    width: 230
                    value: modelData?.audio?.muted ? 0 : modelData?.audio?.volume || 0
                    onCommitted: value => {
                        if (!modelData?.audio) return
                        modelData.audio.muted = false
                        modelData.audio.volume = value
                    }
                }
            }
        }

        EmptyState {
            width: parent.width
            title: "NO ACTIVE STREAMS"
            message: "Playing audio will appear here automatically"
            visible: page.appStreams.length === 0
        }
    }
}

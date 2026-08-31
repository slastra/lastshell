import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Default-sink volume chip (waybar wireplumber): click toggles mute,
// wheel steps 1%, glyph tracks level / mute / bluetooth.
Chip {
    id: root
    edge: "top"

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool bluetooth: (sink?.name ?? "").startsWith("bluez")

    onClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
    onWheelUp: if (sink?.audio) sink.audio.volume = Math.min(1.5, vol + 0.01)
    onWheelDown: if (sink?.audio) sink.audio.volume = Math.max(0, vol - 0.01)

    Popout {
        owner: root
        edge: "top"
        ownerHovered: root.hovered

        Column {
            spacing: 8
            Text {
                text: root.sink?.description ?? "no sink"
                color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14
                width: 220; elide: Text.ElideRight
            }
            Rectangle { // slider track
                width: 220; height: 8; radius: 4
                color: Theme.overlay
                Rectangle {
                    width: parent.width * Math.min(1, root.vol)
                    height: parent.height; radius: 4
                    color: root.muted ? Theme.love : Theme.pine
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => { if (root.sink?.audio) root.sink.audio.volume = mouse.x / width }
                    onPositionChanged: mouse => { if (pressed && root.sink?.audio) root.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                }
            }
        }
    }

    ChipText {
        height: root.height
        padRight: 17
        text: {
            const pct = Math.round(root.vol * 100)
            const icon = root.muted ? "󱭟"
                       : root.bluetooth ? "󰂰"
                       : pct < 34 ? "󱕿" : pct < 67 ? "󱖀" : "󱕾"
            return `${pct}% ${icon}`
        }
    }
}

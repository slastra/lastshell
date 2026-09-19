import QtQuick

// deskpresence chip: is anyone at the desk, as the radar sees it. Foam
// while you are here, muted while away, love when the sensor has gone
// quiet (the OLED is unguarded), gold while paused. Hover for the verdict,
// how long it has held, the TV state and the closest target. Click opens
// the live gate view; right-click toggles the daemon's pause file.
Chip {
    id: root
    edge: "top"
    present: Presence.loaded

    readonly property bool stale: !Presence.sensorOk || !Presence.known
    readonly property color tone:
        root.stale ? Theme.love
        : Presence.paused ? Theme.gold
        : Presence.present ? Theme.foam
        : Qt.alpha(Theme.text, 0.45)

    // ticks once a second so "for 4m 12s" in the popout stays honest
    property double now: Date.now()
    Timer { interval: 1000; running: root.hovered; repeat: true; onTriggered: root.now = Date.now() }
    onHoveredChanged: if (hovered) now = Date.now()

    function held() {
        if (!Presence.since) return ""
        const s = Math.max(0, Math.floor((now - Presence.since) / 1000))
        if (s < 60) return `${s}s`
        if (s < 3600) return `${Math.floor(s / 60)}m ${s % 60}s`
        return `${Math.floor(s / 3600)}h ${Math.floor(s % 3600 / 60)}m`
    }

    onClicked: Presence.openView()
    onRightClicked: Presence.togglePause()

    Row {
        height: root.height - 2
        spacing: 8
        leftPadding: 12
        rightPadding: 12

        LucideIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.stale ? "radar" : Presence.paused ? "eye" : Presence.present ? "user" : "radar"
            color: root.tone
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
    }

    Popout {
        owner: root
        edge: "top"
        ownerHovered: root.hovered

        Column {
            spacing: 6
            width: 280

            Row {
                spacing: 8
                Text {
                    text: "deskpresence"
                    color: Theme.text; font.family: Theme.fontFamily
                    font.pixelSize: 14; font.bold: true
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: root.stale ? "sensor silent"
                        : Presence.paused ? "paused"
                        : Presence.present ? "present" : "away"
                    color: root.tone
                    font.family: Theme.fontFamily; font.pixelSize: 13
                }
            }

            Text {
                visible: root.stale
                width: parent.width
                wrapMode: Text.WordWrap
                text: "No frames from the LD2410C. Nothing is blanking the OLED."
                color: Qt.alpha(Theme.love, 0.9)
                font.family: Theme.fontFamily; font.pixelSize: 12
            }

            PresenceGraph { width: parent.width; height: 64 }
            Text {
                text: `near-gate moving energy, 60 s  ·  present ≥ ${Presence.threshold}`
                color: Qt.alpha(Theme.text, 0.45)
                font.family: Theme.fontFamily; font.pixelSize: 11
            }

            Repeater {
                model: [
                    ["for", root.held()],
                    ["tv", Presence.busy ? `${Presence.tv || "?"} (switching)` : (Presence.tv || "unknown")],
                    ["target", Presence.state === 0 ? "none" : `${Presence.stateWord} at ${Presence.distance} cm`],
                ]
                Row {
                    required property var modelData
                    spacing: 8
                    Text {
                        width: 60
                        text: modelData[0]
                        color: Qt.alpha(Theme.text, 0.5)
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        text: modelData[1]
                        color: Theme.text
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                }
            }

            Text {
                text: "click: live view  ·  right-click: " + (Presence.paused ? "resume" : "pause")
                color: Qt.alpha(Theme.text, 0.45)
                font.family: Theme.fontFamily; font.pixelSize: 12
            }
        }
    }
}

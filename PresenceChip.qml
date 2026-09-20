import QtQuick

// deskpresence chip: is anyone at the desk, as the radar sees it. Foam
// while you are here, muted while away, love when the sensor has gone
// quiet (the OLED is unguarded), gold while paused. Hover for the verdict,
// how long it has held, the TV state and the closest target. Click opens
// the live gate view; right-click toggles the daemon's pause file. The
// popout has rows to stop the Office Light or audio following presence
// and to hold the daemon off (keep awake) for 30 minutes.
Chip {
    id: root
    edge: "top"
    present: Presence.loaded

    // A control row in the popout: icon + name on the left, a muted state
    // word and a drawn switch on the right. The whole row is the hit target.
    component ActionRow: Rectangle {
        id: row
        property string icon
        property bool on
        property string label
        property string word        // muted word beside the switch
        signal clicked()
        width: parent.width
        height: 30
        radius: 6
        color: area.containsMouse ? Qt.alpha(Theme.text, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            spacing: 8
            LucideIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: row.icon
                color: row.on ? Theme.gold : Qt.alpha(Theme.text, 0.45)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: row.label
                color: Theme.text
                font.family: Theme.fontFamily; font.pixelSize: 13
            }
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: row.word
                color: row.on ? Qt.alpha(Theme.gold, 0.9) : Qt.alpha(Theme.text, 0.45)
                font.family: Theme.fontFamily; font.pixelSize: 12
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
            // switch: track + knob, gold when on
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 16; radius: 8
                color: row.on ? Qt.alpha(Theme.gold, 0.35) : Qt.alpha(Theme.text, 0.12)
                border.width: 1
                border.color: row.on ? Theme.gold : Qt.alpha(Theme.text, 0.25)
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Theme.animDuration } }
                Rectangle {
                    width: 10; height: 10; radius: 5
                    y: 3
                    x: row.on ? parent.width - width - 3 : 3
                    color: row.on ? Theme.gold : Qt.alpha(Theme.text, 0.5)
                    Behavior on x { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animDuration } }
                }
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    readonly property bool stale: !Presence.sensorOk || !Presence.known
    readonly property color tone:
        root.stale ? Theme.love
        : Presence.paused ? Theme.gold
        : Presence.present ? Theme.foam
        : Qt.alpha(Theme.text, 0.45)

    // ticks once a second while the popout is up so "for 4m 12s" stays honest
    // (the card outlives the chip hover: the pointer can sit on it)
    property double now: Date.now()
    Timer { interval: 1000; running: pop.visible; repeat: true; onTriggered: root.now = Date.now() }

    function holdLeft() {
        const s = Math.max(0, Math.round((Presence.holdUntil - now) / 1000))
        return s >= 60 ? `${Math.ceil(s / 60)}m` : `${s}s`
    }

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
        }
    }

    Popout {
        id: pop
        owner: root
        edge: "top"
        ownerHovered: root.hovered
        onVisibleChanged: {
            Presence.historyWatchers += visible ? 1 : -1
            if (visible) root.now = Date.now()
        }

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
                        : Presence.holdUntil > 0 ? "held awake"
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

            // divider, then the controls
            Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.text, 0.1) }

            ActionRow {
                icon: Presence.lightFollow ? "lightbulb" : "lightbulb-off"
                on: Presence.lightFollow
                label: "office light"
                word: on ? "follows" : "manual"
                onClicked: Presence.toggleLight()
            }
            ActionRow {
                icon: Presence.audioFollow ? "volume-2" : "volume-x"
                on: Presence.audioFollow
                label: "audio"
                word: on ? "fades" : "manual"
                onClicked: Presence.toggleAudio()
            }
            ActionRow {
                icon: "coffee"
                on: Presence.holdUntil > 0
                label: "keep awake"
                word: on ? `${root.holdLeft()} left` : "30 min"
                onClicked: Presence.hold(on ? 0 : 30)
            }

            Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.text, 0.1) }

            Text {
                text: "click: live view  ·  right-click: " + (Presence.paused ? "resume" : "pause")
                color: Qt.alpha(Theme.text, 0.45)
                font.family: Theme.fontFamily; font.pixelSize: 12
            }
        }
    }
}

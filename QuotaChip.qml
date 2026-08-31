import QtQuick

// Usage as a drawn ring gauge — the arc sweeps between values, the color
// carries the worst limit, and the frame label sits beside it. Click
// cycles frames; the hover card shows every window with its reset time.
Chip {
    id: root
    edge: "bottom"
    visible: Claude.quota.frames.length > 0

    property int frame: 0
    onClicked: frame = (frame + 1) % Math.max(1, Claude.quota.frames.length)

    readonly property var shown: Claude.quota.frames[frame % Math.max(1, Claude.quota.frames.length)] ?? { id: "", pct: 0 }
    readonly property color accent: Theme.level(Claude.quota.worstPct, 70, 90, Theme.foam)

    // The animated value the arc actually draws — sweeps on frame change
    // and on live quota movement alike.
    property real drawnPct: 0
    Behavior on drawnPct { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    onShownChanged: drawnPct = shown.pct ?? 0
    Component.onCompleted: drawnPct = shown.pct ?? 0

    Row {
        height: root.height - 2
        spacing: 8
        leftPadding: 12
        rightPadding: 12

        Canvas { // the ring
            id: ring
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const c = width / 2, r = c - 2
                ctx.lineWidth = 3
                ctx.lineCap = "round"
                // track: legible against surface, quiet under the arc
                ctx.strokeStyle = Qt.alpha(Theme.text, 0.22)
                ctx.beginPath(); ctx.arc(c, c, r, 0, 2 * Math.PI); ctx.stroke()
                if (root.drawnPct > 0) {
                    ctx.strokeStyle = Qt.alpha(root.accent, Claude.quota.stale ? 0.5 : 1)
                    ctx.beginPath()
                    ctx.arc(c, c, r, -Math.PI / 2,
                            -Math.PI / 2 + 2 * Math.PI * Math.min(1, root.drawnPct / 100))
                    ctx.stroke()
                }
            }
            Connections {
                target: root
                function onDrawnPctChanged() { ring.requestPaint() }
                function onAccentChanged() { ring.requestPaint() }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: 16
            color: root.accent
            text: `${Math.round(root.shown.pct ?? 0)}%`
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        Text { // frame marker: hourglass for the 5h window, calendar for weeklies
            anchors.verticalCenter: parent.verticalCenter
            // nf-md glyphs sit low on their line; nudge up to optically center
            anchors.verticalCenterOffset: -1
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: root.accent
            text: root.shown.id === "5h" ? "󰔟" : "󰨴"
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        Text { // model name, only where the calendar alone is ambiguous
            visible: root.shown.id !== "5h" && root.shown.id !== "wk"
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Qt.alpha(Theme.text, 0.5)
            text: root.shown.id
        }
    }

    Popout {
        owner: root
        edge: "bottom"
        ownerHovered: root.hovered

        Column {
            spacing: 8

            Text {
                text: "Usage"
                color: Theme.text; font.family: Theme.fontFamily
                font.pixelSize: 14; font.bold: true
            }

            Repeater {
                model: Claude.quota.frames
                Item {
                    required property var modelData
                    width: 240
                    height: 26
                    readonly property color tone: Theme.level(modelData.pct, 70, 90, Theme.foam)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 58
                        text: modelData.id
                        color: Qt.alpha(Theme.text, 0.7)
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Rectangle {
                        x: 62
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120; height: 6; radius: 3
                        // empty space in a faint wash of the frame's own color,
                        // matching the ring-track treatment
                        color: Qt.alpha(parent.tone, 0.22)
                        Rectangle {
                            width: parent.width * Math.min(1, parent.parent.modelData.pct / 100)
                            height: parent.height; radius: 3
                            color: parent.parent.tone
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${modelData.pct.toFixed(0)}%`
                        color: parent.tone
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                }
            }

            Text {
                visible: Claude.quota.stale
                text: "data is stale"
                color: Qt.alpha(Theme.gold, 0.8)
                font.family: Theme.fontFamily; font.pixelSize: 12; font.italic: true
            }
        }
    }
}

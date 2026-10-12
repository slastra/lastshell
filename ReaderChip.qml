import QtQuick

// The narrator's chip (Super+T reads; services/Reader.qml): here only while
// a document is loaded. Click play-pauses, the wheel skips passages, and the
// popout is the whole player. The chip itself changes once per passage; the
// per-second clock and progress live in the popout, so a long read doesn't
// repaint the bar every second.
Chip {
    id: root
    edge: "bottom"
    present: Reader.active
    active: Reader.playing

    onClicked: Reader.toggle()
    onWheelUp: Reader.prev()
    onWheelDown: Reader.next()

    readonly property var s: Reader.state

    ChipBody {
        LucideIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: Reader.playing ? "audio-lines" : root.s.finished ? "square" : "pause"
            font.pixelSize: 13
            color: Qt.alpha(Reader.playing ? Theme.foam : Theme.text, 0.8)
        }
        ValueText {
            font.italic: !Reader.playing
            color: Reader.playing ? Theme.foam : Theme.text
            text: root.s.passages ? `${root.s.position}/${root.s.passages}${root.s.complete ? "" : "+"}` : "…"
        }
    }

    Popout {
        id: pop
        owner: root

        Column {
            spacing: 10
            width: 380

            PopoutHeader {
                title: "reader"
                status: {
                    const s = root.s
                    if (s.finished) return "finished"
                    const parts = [s.passages ? `passage ${s.position} of ${s.passages}${s.complete ? "" : "+"}` : "starting"]
                    if (s.note) parts.push(s.note)
                    else if (!s.settled && s.passages) parts.push(`rendering ${s.rendered}`)
                    return parts.join("  ·  ")
                }
                tone: Reader.playing ? Theme.foam : Theme.textMuted
            }

            Divider { width: parent.width }

            PopText { // the passage being read
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 8
                elide: Text.ElideRight
                size: 14
                text: root.s.passage || ""
            }

            Column {
                width: parent.width
                spacing: 4
                SliderTrack {
                    width: parent.width
                    height: 6
                    frac: pop.visible ? Reader.progress : 0
                    fill: Theme.foam
                }
                Item {
                    width: parent.width
                    height: elapsed.implicitHeight
                    PopText { id: elapsed; size: 12; dim: 0.7; text: Reader.clock(root.s.elapsed) }
                    PopText {
                        anchors.right: parent.right
                        size: 12; dim: 0.45
                        text: (root.s.settled ? "of " : "of ~") + Reader.clock(root.s.total)
                    }
                }
            }

            Row { // transport
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22
                Repeater {
                    model: [
                        { icon: "skip-back", act: () => Reader.prev() },
                        { icon: Reader.playing ? "pause" : "play", act: () => Reader.toggle(), big: true },
                        { icon: "skip-forward", act: () => Reader.next() },
                        { icon: "square", act: () => Reader.stop() },
                    ]
                    LucideIcon {
                        required property var modelData
                        name: modelData.icon
                        font.pixelSize: modelData.big ? 22 : 16
                        color: tap.containsMouse ? Theme.rose : modelData.big ? Theme.text : Theme.textMuted
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            id: tap
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.act()
                        }
                    }
                }
            }

            Row { // speed: 0.5x .. 3x, dragging sends steps of 0.05
                spacing: 10
                PopText { width: 44; size: 12; dim: 0.5; text: "speed"; anchors.verticalCenter: parent.verticalCenter }
                SliderTrack {
                    width: 380 - 44 - 50 - 20
                    anchors.verticalCenter: parent.verticalCenter
                    interactive: true
                    fill: Theme.iris
                    frac: ((Reader.config.speed ?? 1) - 0.5) / 2.5
                    onSeek: f => Reader.setSpeed(0.5 + f * 2.5)
                }
                PopText {
                    width: 50; size: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${(Reader.config.speed ?? 1).toFixed(2)}×`
                }
            }

            component Cycler: Row {
                id: cy
                property string label
                property string value
                property bool enabled: true
                signal step(int d)
                spacing: 10
                PopText { width: 44; size: 12; dim: 0.5; text: cy.label; anchors.verticalCenter: parent.verticalCenter }
                LucideIcon {
                    name: "chevron-left"; font.pixelSize: 13
                    color: cl.containsMouse ? Theme.rose : Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { id: cl; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; enabled: cy.enabled; onClicked: cy.step(-1) }
                }
                PopText {
                    width: 380 - 44 - 13 * 2 - 30
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    size: 13
                    dim: cy.enabled ? 1 : 0.4
                    text: cy.value
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { // the wheel cycles too
                        anchors.fill: parent
                        enabled: cy.enabled
                        onWheel: w => cy.step(w.angleDelta.y > 0 ? -1 : 1)
                    }
                }
                LucideIcon {
                    name: "chevron-right"; font.pixelSize: 13
                    color: cr.containsMouse ? Theme.rose : Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { id: cr; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; enabled: cy.enabled; onClicked: cy.step(1) }
                }
            }

            Cycler {
                label: "voice"
                value: Reader.voiceLabel()
                onStep: d => Reader.cycleVoice(d)
            }
            Cycler {
                label: "tidy"
                value: Reader.config.tidy_available ? (Reader.config.tidy ?? "Auto") : "unavailable (no key)"
                enabled: Reader.config.tidy_available === true
                onStep: d => Reader.cycleTidy(d)
            }
        }
    }
}

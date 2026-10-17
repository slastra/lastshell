import QtQuick

// The desk's voice, in one chip (services/Voice.qml for deskvoice,
// services/Reader.qml for the narrator). It replaces the reader chip.
//
// One mouth, many voices: the chip's border lights in the colour of whoever
// has the floor, and the mark beside it steps while they talk. deskdoc is
// rose, Claude iris, the reader foam, the open mic gold, dictation love.
// Idle it is just the mark, muted; with the wake word off, a struck mic.
//
// Click: stop deskdoc or Claude mid-sentence, else play-pause the reader.
// Right-click: the wake word on or off. Wheel: skip passages while reading.
// The popout holds the rest: what's being said or heard right now, the three
// voices, the reader's player, dictation, recent exchanges, the switches.
Chip {
    id: root
    edge: "bottom"
    present: Voice.up || Reader.active

    readonly property string who: Voice.who
    readonly property color tone: Voice.tone(who)
    readonly property bool talking: who === "deskdoc" || who === "claude"
    active: who !== "idle" && who !== "down"
    accent: tone

    onClicked: {
        if (talking) Voice.stopSpeaking()
        else if (Reader.active) Reader.toggle()
    }
    onRightClicked: if (Voice.up) Voice.setMic(!Voice.micOn)
    onWheelUp: if (Reader.active) Reader.prev()
    onWheelDown: if (Reader.active) Reader.next()

    readonly property string markMode: who === "dictating" ? "dictating"
        : who === "listening" ? "listening"
        : talking || Reader.playing ? "speaking" : "idle"

    readonly property string label: {
        const d = Voice.dictation
        if (who === "dictating") return `${Math.floor((d?.secs ?? 0) / 60)}:${String((d?.secs ?? 0) % 60).padStart(2, "0")}`
        if (who === "listening") return "listening"
        if (who === "deskdoc") return "doc"
        if (who === "claude") return "claude"
        if (who === "reader") {
            const s = Reader.state
            if (Reader.starting) return "reading…"
            if (Reader.finished) return "done"
            return `${s.position}/${s.passages}${s.complete ? "" : "+"}`
        }
        return ""
    }

    ChipBody {
        VoiceMark {
            anchors.verticalCenter: parent.verticalCenter
            visible: !(root.who === "idle" && !Voice.micOn)
            mode: root.markMode
            tone: root.active ? root.tone : Theme.textMuted
        }
        LucideIcon { // the wake word is off: no capture
            anchors.verticalCenter: parent.verticalCenter
            visible: root.who === "idle" && !Voice.micOn
            name: "mic-off"
            font.pixelSize: 13
            color: Theme.textFaint
        }
        ValueText {
            visible: root.label !== ""
            text: root.label
            color: root.tone
            font.italic: root.who === "reader" && !Reader.playing
        }
    }

    // --- popout ----------------------------------------------------------------
    component Action: Rectangle {
        id: act
        property string icon
        property string text
        property string hint
        signal tapped()
        implicitWidth: actRow.implicitWidth + 24
        height: 30
        radius: Theme.innerRadius
        color: actHover.hovered ? Theme.border : Theme.overlay
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        Row {
            id: actRow
            anchors.centerIn: parent
            spacing: 8
            LucideIcon { anchors.verticalCenter: parent.verticalCenter; name: act.icon; font.pixelSize: 13; color: Theme.text }
            PopText { anchors.verticalCenter: parent.verticalCenter; size: 13; text: act.text }
            PopText { anchors.verticalCenter: parent.verticalCenter; size: 11; dim: 0.4; text: act.hint; visible: act.hint !== "" }
        }
        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: act.tapped() }
    }

    component Switch: Item {
        id: sw
        property string text
        property string note
        property bool on
        signal toggled(bool on)
        width: parent.width
        height: 28
        PopText { id: swText; anchors.verticalCenter: parent.verticalCenter; size: 13; text: sw.text }
        PopText {
            anchors.left: swText.right; anchors.leftMargin: 10
            anchors.right: seg.left; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            size: 11; dim: 0.4
            text: sw.note
        }
        Segmented {
            id: seg
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 112
            segmentHeight: 26
            options: [{ value: true, label: "on" }, { value: false, label: "off" }]
            current: sw.on
            onPicked: v => sw.toggled(v)
        }
    }

    Popout {
        id: pop
        owner: root

        Column {
            id: col
            spacing: 14
            width: 400

            PopoutHeader {
                title: "voice"
                status: {
                    if (!Voice.up) return "deskvoice isn't running"
                    const parts = [Voice.micOn ? "wake word on" : "wake word off"]
                    if (Voice.readerHeld) parts.push("reader held")
                    else if (Voice.ducking) parts.push("ducking")
                    return parts.join("  ·  ")
                }
                tone: !Voice.up ? Theme.love : root.active ? root.tone : Theme.textMuted
            }

            Divider { width: parent.width }

            // now: who has the floor, and what they're saying (or hearing)
            Row {
                width: parent.width
                spacing: 16
                Item {
                    width: 28; height: 28
                    VoiceMark {
                        anchors.centerIn: parent
                        unit: 2
                        visible: !(root.who === "idle" && !Voice.micOn)
                        mode: root.markMode
                        tone: root.active ? root.tone : Theme.textFaint
                    }
                    LucideIcon {
                        anchors.centerIn: parent
                        visible: root.who === "idle" && !Voice.micOn
                        name: "mic-off"; font.pixelSize: 20; color: Theme.textFaint
                    }
                }
                Column {
                    width: parent.width - 28 - parent.spacing
                    spacing: 4
                    PopText {
                        size: 12
                        color: root.active ? root.tone : Theme.textMuted
                        text: ({
                            deskdoc: `deskdoc  ·  ${Voice.voices.assistant ?? ""}`,
                            claude: `claude  ·  ${Voice.voices.cue ?? ""}`,
                            reader: Voice.readerHeld ? "reader  ·  held for the others" : "reader",
                            listening: Voice.listen?.state === "transcribing" ? "heard you" : "listening",
                            dictating: Voice.dictation?.voice ? "dictating  ·  by voice" : "dictating",
                            down: "deskvoice",
                        })[root.who] ?? "quiet"
                    }
                    PopText {
                        width: parent.width
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        size: 14
                        color: root.active ? Theme.text : Theme.textMuted
                        text: {
                            const w = root.who
                            if (w === "dictating") return Voice.dictation?.partial || "Go ahead…"
                            if (w === "listening") return Voice.listen?.state === "transcribing" ? "Working out what you said…" : "Speak now."
                            if (w === "deskdoc" || w === "claude") return Voice.speaking?.text ?? ""
                            if (w === "reader") return Reader.starting ? "Preparing…" : `passage ${Reader.state.position} of ${Reader.state.passages}`
                            if (w === "down") return "Not running. systemctl --user start deskvoice"
                            return Voice.micOn ? "Say “what's up doc”." : "The wake word is off; the mic is closed."
                        }
                    }
                }
            }

            // the three voices, each in its colour
            Column {
                width: parent.width
                spacing: 2
                SectionLabel { text: "voices"; bottomPadding: 4 }
                Repeater {
                    model: [
                        { id: "deskdoc", name: "deskdoc", voice: Voice.voices.assistant ?? "af_nicole" },
                        { id: "claude", name: "claude", voice: Voice.voices.cue ?? "ff_siwis" },
                        { id: "reader", name: "reader", voice: (Reader.config.voice || "kokoro-bm_george").replace(/^kokoro-/, "") },
                    ]
                    Item {
                        required property var modelData
                        readonly property bool on: root.who === modelData.id
                        readonly property color laneTone: Voice.tone(modelData.id)
                        width: col.width
                        height: 24
                        Rectangle {
                            id: dot
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; radius: 4
                            color: parent.on ? parent.laneTone : "transparent"
                            border.width: 1
                            border.color: Qt.alpha(parent.laneTone, parent.on ? 1 : 0.55)
                        }
                        PopText {
                            id: laneName
                            x: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 70
                            size: 13
                            color: parent.on ? parent.laneTone : Theme.text
                            text: parent.modelData.name
                        }
                        PopText {
                            anchors.left: laneName.right
                            anchors.verticalCenter: parent.verticalCenter
                            size: 12; dim: 0.45
                            text: parent.modelData.voice
                        }
                        PopText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            size: 12
                            color: parent.on ? parent.laneTone : Theme.textFaint
                            text: {
                                const id = parent.modelData.id
                                if (id === "reader") {
                                    if (!Reader.active) return "—"
                                    if (Voice.readerHeld) return "held"
                                    return Reader.playing ? "reading" : "paused"
                                }
                                const ch = id === "deskdoc" ? "assistant" : "cue"
                                if (parent.on) return "speaking"
                                const q = Voice.status.queued?.[ch] ?? 0
                                return q > 0 ? `${q} waiting` : "—"
                            }
                        }
                    }
                }
            }

            Divider { width: parent.width }

            // the reader's player while reading; a way to start one otherwise
            Loader {
                width: parent.width
                active: Reader.active
                visible: active
                sourceComponent: ReaderPanel { width: col.width; live: pop.visible }
            }
            Row {
                visible: !Reader.active
                spacing: 8
                Action { icon: "audio-lines"; text: "read selection"; hint: "super t"; onTapped: Reader.read() }
            }

            // dictation
            Column {
                width: parent.width
                spacing: 8
                SectionLabel { text: "dictation" }
                Row {
                    spacing: 8
                    Action { icon: "mic"; text: "dictate"; hint: "super x"; onTapped: Voice.dictate(false) }
                    Action { icon: "corner-down-left"; text: "dictate & send"; hint: "⇧ super x"; onTapped: Voice.dictate(true) }
                }
                PopText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    size: 11; dim: 0.35
                    text: "or say “what's up doc, dictate …”; end with “enter” to send"
                }
            }

            // recent: what you said, what was said back, what got typed
            Column {
                width: parent.width
                spacing: 6
                visible: Voice.recent.length > 0
                SectionLabel { text: "recent" }
                Repeater {
                    model: Voice.recent.slice(-5).reverse()
                    Item {
                        required property var modelData
                        width: col.width
                        height: Math.max(kind.implicitHeight, said.implicitHeight)
                        PopText {
                            id: kind
                            width: 48
                            size: 12
                            color: Voice.kindTone(parent.modelData)
                            text: Voice.kindLabel(parent.modelData)
                        }
                        PopText {
                            id: said
                            anchors.left: kind.right
                            anchors.right: when.left
                            anchors.rightMargin: 10
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            size: 12; dim: 0.8
                            text: parent.modelData.text
                        }
                        PopText {
                            id: when
                            anchors.right: parent.right
                            size: 11; dim: 0.35
                            text: Voice.clockOf(parent.modelData.ts)
                        }
                    }
                }
            }

            Divider { width: parent.width }

            Column {
                width: parent.width
                spacing: 6
                Switch {
                    text: "wake word"
                    note: Voice.micOn ? "listening for “what's up doc”" : "mic closed"
                    on: Voice.micOn
                    enabled: Voice.up
                    onToggled: v => Voice.setMic(v)
                }
                Switch {
                    text: "claude's voice"
                    note: Voice.claudeQuiet ? "cues muted" : "spoken cues"
                    on: !Voice.claudeQuiet
                    onToggled: v => Voice.setClaudeQuiet(!v)
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Now-playing chip (waybar mpris): one chip, one player at a time. Wheel
// cycles which player it shows when there are several (the text swaps
// with a slide from the bar edge, border and text in the accent for the
// beat) and skips tracks when there's one; click play-pauses. Left
// alone it follows the player that's actually playing.
Chip {
    id: root
    edge: "bottom"
    clip: true
    active: swap.running

    readonly property var players: Mpris.players.values
    present: players.length > 0

    property var player: null
    readonly property bool paused: player?.playbackState === MprisPlaybackState.Paused

    // Pick when the roster changes: keep the current one if it's still
    // here, else prefer playing > paused > first. Hand-picked via wheel
    // sticks until that player goes away.
    onPlayersChanged: {
        if (player && players.includes(player)) return
        player = players.find(p => p.playbackState === MprisPlaybackState.Playing)
            ?? players.find(p => p.playbackState === MprisPlaybackState.Paused)
            ?? players[0] ?? null
    }
    Component.onCompleted: playersChanged()

    // One player: wheel skips tracks. Several: wheel picks the player.
    function cycle(step) {
        if (players.length < 2) {
            if (step > 0 && player?.canGoNext) player.next()
            if (step < 0 && player?.canGoPrevious) player.previous()
            return
        }
        const i = Math.max(0, players.indexOf(player))
        player = players[(i + step + players.length) % players.length]
    }
    onWheelUp: cycle(1)
    onWheelDown: cycle(-1)
    onClicked: player?.togglePlaying()

    readonly property string liveText: {
        if (!player) return ""
        let dyn = [player.trackTitle, player.trackArtist].filter(x => x).join(" - ")
        if (dyn === "") dyn = player.identity ?? ""
        return dyn.length > 40 ? dyn.slice(0, 39) + "…" : dyn
    }
    property string text: ""
    onLiveTextChanged: if (!swap.running) text = liveText
    onPlayerChanged: if (text !== "") swap.restart(); else text = liveText

    SequentialAnimation {
        id: swap
        readonly property int half: Theme.slideDuration / 2
        ParallelAnimation {
            NumberAnimation { target: slide; property: "y"; to: -root.height; duration: swap.half; easing.type: Easing.InCubic }
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: swap.half; easing.type: Easing.InCubic }
        }
        ScriptAction { script: { root.text = root.liveText; slide.y = root.height } }
        ParallelAnimation {
            NumberAnimation { target: slide; property: "y"; to: 0; duration: swap.half; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: swap.half; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: Theme.slideDuration }
    }

    ChipBody {
        id: content
                transform: Translate { id: slide }

        LucideIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.paused ? "pause" : "play"
            font.pixelSize: 13
            color: Qt.alpha(root.active ? Theme.rose : Theme.text, 0.7)
        }
        ValueText {
            font.italic: root.paused
            color: root.active ? Theme.rose : Theme.text
            text: root.text
            Behavior on width { NumberAnimation { duration: Theme.slideDuration; easing.type: Easing.OutCubic } }
        }
    }
}

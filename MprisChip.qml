import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Now-playing chip for one player (waybar mpris): title/artist capped,
// italic when paused, click play-pause, wheel next/prev. Caches its text
// so it can slide out after the player object is gone.
Chip {
    id: root
    edge: "bottom"

    property var player: null   // MprisPlayer
    readonly property bool paused: player?.playbackState === MprisPlaybackState.Paused

    readonly property string liveText: {
        if (!player) return ""
        let dyn = [player.trackTitle, player.trackArtist].filter(x => x).join(" - ")
        if (dyn === "") dyn = player.identity ?? ""
        return dyn.length > 40 ? dyn.slice(0, 39) + "…" : dyn
    }
    property string text: ""
    onLiveTextChanged: if (player) text = liveText
    Component.onCompleted: text = liveText

    onClicked: player?.togglePlaying()
    onWheelUp: if (player?.canGoNext) player.next()
    onWheelDown: if (player?.canGoPrevious) player.previous()

    Row {
        height: root.height - 2
        spacing: 8
        leftPadding: 12
        rightPadding: 12

        LucideIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.paused ? "pause" : "play"
            font.pixelSize: 13
            color: Qt.alpha(Theme.text, 0.7)
        }
        ValueText {
            font.italic: root.paused
            color: Theme.text
            text: root.text
        }
    }
}

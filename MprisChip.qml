import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Now-playing chip (waybar mpris): title/artist capped, italic when paused,
// click play-pause, wheel next/prev.
Chip {
    id: root
    edge: "bottom"
    visible: player !== null

    readonly property MprisPlayer player: {
        const ps = Mpris.players.values
        return ps.find(p => p.playbackState === MprisPlaybackState.Playing)
            ?? ps.find(p => p.playbackState === MprisPlaybackState.Paused)
            ?? ps[0] ?? null
    }
    readonly property bool paused: player?.playbackState === MprisPlaybackState.Paused

    onClicked: player?.togglePlaying()
    onWheelUp: if (player?.canGoNext) player.next()
    onWheelDown: if (player?.canGoPrevious) player.previous()

    ChipText {
        height: root.height
        rightPadding: 12
        font.italic: root.paused
        text: {
            if (!root.player) return ""
            // nf-md plane; the classic PUA player glyphs render blank in Qt
            const icon = (root.player.identity ?? "").toLowerCase().includes("firefox") ? "󰈹" : "󰝚"
            const state = root.paused ? "󰏤" : "󰐊"
            let dyn = [root.player.trackTitle, root.player.trackArtist]
                .filter(x => x).join(" - ")
            if (dyn.length > 40) dyn = dyn.slice(0, 39) + "…"
            return `${state} ${icon} ${dyn}`
        }
    }
}

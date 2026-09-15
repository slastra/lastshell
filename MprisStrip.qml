import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// One chip per MPRIS player (bottom bar, right). Players go through a
// SyncedList keyed on their D-Bus name, so a player appearing or quitting
// slides its chip in or out; order is D-Bus order, kept stable so a
// play/pause toggle never shuffles the strip.
ChipRow {
    id: root
    spacing: 8

    SyncedList { id: players }
    function resync() { players.sync(Mpris.players.values, p => p.dbusName) }
    Connections {
        target: Mpris.players
        function onValuesChanged() { root.resync() }
    }
    Component.onCompleted: resync()

    Repeater {
        model: players.model
        MprisChip {
            required property var item     // MprisPlayer, null once freed
            required property bool gone
            player: item
            present: !gone
            anchors.bottom: parent.bottom
        }
    }
}

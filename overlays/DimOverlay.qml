import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."  // root module: Presence

// Absence warning: the screen fades to black over the last seconds before
// deskpresence declares the desk empty and powers the TV off. Follows the
// daemon's fade level (0.05 steps at 4 Hz), smoothed here so it reads as a
// dim rather than a stair. One breath resets it and the shade lifts.
// Never takes input: the mask is empty, so clicks land on what's beneath.
PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lastshell-dim"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}
    color: "transparent"
    // Only mapped while there is something to show: a resident fullscreen
    // layer is surface memory and a compositor pass for nothing.
    visible: shade.opacity > 0.001

    Rectangle {
        id: shade
        anchors.fill: parent
        color: "black"
        // only where deskpresence runs; the ternary keeps the singleton unbuilt elsewhere
        opacity: Host.presence ? Presence.fade : 0
        Behavior on opacity {
            // lifting is quick (you are back), dimming eases in
            NumberAnimation { duration: Presence.fade === 0 ? 220 : 320; easing.type: Easing.InOutQuad }
        }
    }
}

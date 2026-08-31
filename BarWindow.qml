import Quickshell
import QtQuick

// A bar shell: full-width transparent panel. During the parallel run with
// waybar it reserves NO exclusive zone (waybar keeps the layout); flip
// `reserve: true` at cutover.
PanelWindow {
    property bool reserve: false
    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusiveZone: reserve ? Theme.barHeight : 0
    anchors { left: true; right: true }
}

import QtQuick

// The top bar: workspaces + window title left, taskbar center, system
// chips right. Modules land here phase by phase.
BarWindow {
    anchors.top: true

    ChipRow {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 8
        spacing: 8
        Workspaces {}
        WindowTitle { anchors.top: parent.top }
    }

    Taskbar {
        anchors.top: parent.top
        // positioned by binding, not anchor, so a width change (a chip
        // coming or going) glides the whole strip instead of jumping it
        x: Math.round((parent.width - width) / 2)
        Behavior on x { NumberAnimation { duration: Theme.slideDuration; easing.type: Easing.OutCubic } }
    }

    ChipRow {
        anchors.top: parent.top
        // positioned by binding, not anchor, so a width change (a chip
        // coming or going) glides the whole strip instead of jumping it
        x: parent.width - width - 8
        Behavior on x { NumberAnimation { duration: Theme.slideDuration; easing.type: Easing.OutCubic } }
        spacing: 8
        Tray {}
        SysChips {}
        HdrChip {}
        BatteryChip {}
        PresenceChip {}
        DeskwatchChip {}
        ClockChip {}
    }
}

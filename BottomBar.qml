import QtQuick

// The bottom bar: browser tabs left, claude strip centre, mpris + volume right.
// One window, one exclusive zone — content items only below here.
BarWindow {
    anchors.bottom: true

    TabStrip {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 8
    }

    ClaudeStrip {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 8
        spacing: 8
        MprisChip {}
        VolumeChip {}
    }
}

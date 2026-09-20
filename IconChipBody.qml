import QtQuick

// An 18 px image centred in a fixed-width slot: taskbar, tray and tab
// chips (which set Chip.contentPadding: 0 and size the slot themselves).
Item {
    property alias source: img.source
    property int slot: 34
    implicitWidth: slot
    height: Theme.barHeight - 4
    Image {
        id: img
        anchors.centerIn: parent
        width: 18; height: 18
        sourceSize: Qt.size(36, 36) // decode above device pixels
    }
}

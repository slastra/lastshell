import QtQuick

// An 18 px image centred in a fixed-width slot: taskbar, tray and tab
// chips (which set Chip.contentPadding: 0 and size the slot themselves).
// With no image to show, a `fallback` name becomes a monogram tile: its
// first letter in a hairline square, so an app without an icon still has
// a face. With neither, a generic window glyph.
Item {
    id: root
    property alias source: img.source
    property int slot: 34
    property string fallback: ""        // app id or title to take a letter from
    property bool placeholder: false    // draw the tile when there is no image

    readonly property bool missing: placeholder
        && (img.source.toString() === "" || img.status === Image.Error)
    readonly property string letter: {
        // org.gnome.Nautilus is "N", not "O"
        const name = fallback.includes(".") ? fallback.split(".").pop() : fallback
        const m = name.match(/[A-Za-z0-9]/)
        return m ? m[0].toUpperCase() : ""
    }

    implicitWidth: slot
    // Chip's content slot sits 1 px low for text ink; images carry no such
    // bias, so the body is 2 px shorter to centre on the chip fill instead.
    height: Theme.barHeight - 6
    Image {
        id: img
        anchors.centerIn: parent
        width: 18; height: 18
        sourceSize: Qt.size(36, 36) // decode above device pixels
        visible: !root.missing
    }
    Rectangle { // the monogram tile
        visible: root.missing
        anchors.centerIn: parent
        width: 18; height: 18
        radius: Math.min(Theme.innerRadius, 4)
        color: Theme.overlay
        border.color: Theme.border
        border.width: Theme.hairline
        PopText {
            visible: root.letter !== ""
            anchors.centerIn: parent
            size: 12; font.bold: true
            text: root.letter
        }
        LucideIcon {
            visible: root.letter === ""
            anchors.centerIn: parent
            name: "app-window"
            font.pixelSize: 12
            color: Theme.text
        }
    }
}

import QtQuick

// SDR brightness chip: the desktop's lift against the HDR range. Click
// toggles 1.0 ↔ last value, wheel steps 0.05, popout drags 1.0–3.0.
Chip {
    id: root
    edge: "top"

    readonly property real b: Hdr.brightness
    readonly property bool lifted: b > 1.0
    readonly property color tone: lifted ? Theme.gold : Theme.text

    onClicked: Hdr.toggle()
    onWheelUp: Hdr.nudge(Hdr.step)
    onWheelDown: Hdr.nudge(-Hdr.step)

    Popout {
        owner: root
        edge: "top"
        ownerHovered: root.hovered

        Column {
            spacing: 8
            Text {
                text: `SDR brightness ${root.b.toFixed(2)}×`
                color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14
                width: 220
            }
            Rectangle { // slider track, 1.0 at the left edge
                width: 220; height: 8; radius: 4
                color: Qt.alpha(Theme.text, 0.22)
                Rectangle {
                    width: parent.width * (root.b - Hdr.min) / (Hdr.max - Hdr.min)
                    height: parent.height; radius: 4
                    color: Theme.gold
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
                MouseArea {
                    anchors.fill: parent
                    function at(x) { Hdr.set(Hdr.min + (Hdr.max - Hdr.min) * Math.max(0, Math.min(1, x / width))) }
                    onPressed: mouse => at(mouse.x)
                    onPositionChanged: mouse => { if (pressed) at(mouse.x) }
                }
            }
        }
    }

    Row {
        height: root.height - 2
        spacing: 8
        leftPadding: 12
        rightPadding: 12
        ValueText {
            color: root.tone
            text: `${root.b.toFixed(1)}×`
        }
        LucideIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "sun"
            color: root.tone
        }
    }
}

import QtQuick

// Session state as a drawn element rather than a font glyph.
//   idle    hollow ring, muted
//   busy    filled dot, slow breathing
//   waiting gold dot with a sonar ping — "needs you" you can see across the room
Item {
    id: root
    property string state: "idle"
    implicitWidth: 12
    implicitHeight: 12

    readonly property color tone:
        state === "waiting" ? Theme.gold :
        state === "busy" ? Theme.foam : Qt.alpha(Theme.text, 0.45)

    Rectangle { // sonar ping (waiting only)
        anchors.centerIn: parent
        width: 10; height: 10; radius: 5
        color: "transparent"
        border.color: Theme.gold
        border.width: 1.5
        visible: root.state === "waiting"
        SequentialAnimation on scale {
            running: root.state === "waiting"; loops: Animation.Infinite
            NumberAnimation { from: 0.8; to: 2.1; duration: 1100; easing.type: Easing.OutCubic }
        }
        SequentialAnimation on opacity {
            running: root.state === "waiting"; loops: Animation.Infinite
            NumberAnimation { from: 0.9; to: 0; duration: 1100 }
        }
    }

    Rectangle { // the dot itself
        id: dot
        anchors.centerIn: parent
        width: 9; height: 9; radius: 4.5
        color: root.state === "idle" ? "transparent" : root.tone
        border.color: root.tone
        border.width: 1.5
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDuration } }

        SequentialAnimation on opacity { // breathing while busy
            running: root.state === "busy"; loops: Animation.Infinite
            onStopped: dot.opacity = 1
            NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
        }
    }
}

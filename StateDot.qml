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

    Canvas { // sonar ping (waiting only) — drawn, not transform-scaled:
             // scaling a Rectangle's stroke across fractional device pixels
             // (1.25 display scale) renders lopsided and the pulse looks
             // off-center. An arc painted at the exact center each frame
             // stays concentric at any radius.
        id: ping
        anchors.centerIn: parent
        width: 26; height: 26
        visible: root.state === "waiting"

        property real p: 0
        SequentialAnimation on p {
            running: root.state === "waiting"; loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        }
        onPChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (root.state !== "waiting") return
            ctx.strokeStyle = Qt.alpha(Theme.gold, 0.9 * (1 - p))
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, 4 + 7.5 * p, 0, 2 * Math.PI)
            ctx.stroke()
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

import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."  // root module: Theme and friends

// Modal overlay base: a full-screen transparent catcher on the overlay
// layer, a centered card, exclusive keyboard while open (None otherwise —
// that flip is what hands focus back on dismiss).
PanelWindow {
    id: root

    property bool open: false
    default property alias content: inner.data
    property alias cardWidth: card.implicitWidth
    property int contentPadding: 18

    function toggle() { open = !open }
    function dismiss() { open = false }

    visible: open || card.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lastshell-overlay"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea { // click-outside dismissal + the backdrop mask
        anchors.fill: parent
        onClicked: root.dismiss()

        // Vignette mask, animated as an iris: the darkness closes in from
        // the edges toward the card as `progress` runs 0->1, and opens back
        // out on dismiss. Repainted per frame — a radial gradient whose
        // bright center shrinks while the edge weight lands.
        Canvas {
            id: maskCanvas
            anchors.fill: parent

            property real progress: root.open ? 1 : 0
            Behavior on progress { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            onProgressChanged: requestPaint()
            visible: progress > 0

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (progress === 0) return
                const p = progress
                const cx = width / 2, cy = height / 2
                // outer = exact corner distance, so the corners actually land
                // on the final stop — spanning past them flattened the whole
                // gradient into an even dim and the vignette vanished
                const outer = Math.hypot(cx, cy)
                // clear pool contracts from everything -> a halo round the card
                const inner = outer * (0.95 - 0.83 * p)
                const g = ctx.createRadialGradient(cx, cy, inner, cx, cy, outer)
                g.addColorStop(0, Qt.alpha(Theme.base, 0.45 * p))
                g.addColorStop(1, Qt.alpha(Theme.base, 1.0 * p))
                ctx.fillStyle = g
                ctx.fillRect(0, 0, width, height)
            }
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.open ? 0 : 10
        implicitHeight: inner.childrenRect.height + root.contentPadding * 2
        radius: Theme.overlayRadius
        color: Theme.surface
        border.color: Theme.overlay
        border.width: 2

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent } // swallow clicks inside the card

        Item {
            id: inner
            x: root.contentPadding; y: root.contentPadding
            width: parent.width - root.contentPadding * 2
            height: parent.height - root.contentPadding * 2
        }
    }
}

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

        // Vignette mask: darkest at the edges, lighter where the card sits,
        // so opening reads as the desktop receding and attention pooling in
        // the middle. Painted once; the transition is transform + opacity —
        // it breathes in with a slight contraction, fully animatable (the
        // reason this replaced compositor blur).
        Canvas {
            id: maskCanvas
            anchors.fill: parent
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 1.12
            transformOrigin: Item.Center
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const g = ctx.createRadialGradient(
                    width / 2, height / 2, Math.min(width, height) * 0.18,
                    width / 2, height / 2, Math.max(width, height) * 0.75)
                g.addColorStop(0, Qt.alpha(Theme.base, 0.80))
                g.addColorStop(1, Qt.alpha(Theme.base, 0.97))
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

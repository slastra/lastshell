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

    function toggle() { open = !open }
    function dismiss() { open = false }

    visible: open || card.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea { // click-outside dismissal + faint dim behind the card
        anchors.fill: parent
        onClicked: root.dismiss()
        Rectangle { anchors.fill: parent; color: Theme.base; opacity: root.open ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } } }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        implicitHeight: inner.childrenRect.height + 32
        radius: Theme.overlayRadius
        color: Theme.surface
        border.color: Theme.overlay
        border.width: 2

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent } // swallow clicks inside the card

        Item {
            id: inner
            x: 16; y: 16
            width: parent.width - 32
            height: parent.height - 32
        }
    }
}

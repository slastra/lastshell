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
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea { // click-outside dismissal + faint dim behind the card
        anchors.fill: parent
        onClicked: root.dismiss()
        Rectangle { anchors.fill: parent; color: Theme.base; opacity: root.open ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } } }
    }

    // Soft depth without shader effects: two translucent halos behind the card.
    Repeater {
        model: [ { pad: 14, a: 0.18 }, { pad: 6, a: 0.30 } ]
        Rectangle {
            required property var modelData
            anchors.centerIn: parent
            anchors.verticalCenterOffset: card.anchors.verticalCenterOffset + 5
            width: card.width + modelData.pad
            height: card.height + modelData.pad
            radius: Theme.overlayRadius + modelData.pad / 2
            color: Qt.alpha("#000000", modelData.a)
            opacity: card.opacity
            scale: card.scale
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

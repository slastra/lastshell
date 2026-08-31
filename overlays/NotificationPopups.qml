import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import ".."  // root module

// Notification server + top-right toast stack (replaces mako). Guarded by
// LASTSHELL_NOTIFS=1 until cutover: two servers on org.freedesktop
// .Notifications conflict, and mako holds the name until it retires.
Scope {
    id: root

    property bool enabled: Quickshell.env("LASTSHELL_NOTIFS") === "1"
    property var toasts: []

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true

        onNotification: n => {
            if (!root.enabled) return
            n.tracked = true
            root.toasts = root.toasts.concat([n])
            // mirror mako's lamp hook so cutover is behavior-neutral
            const lamp = Quickshell.env("HOME") + "/.config/mako/scripts/lamp.sh"
            Quickshell.execDetached(["bash", lamp, n.urgency === 2 ? "alert" : "info"])
        }
    }

    function drop(n) { root.toasts = root.toasts.filter(t => t !== n) }

    PanelWindow {
        visible: root.enabled && root.toasts.length > 0
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + 10; right: 10 }
        implicitWidth: 380
        implicitHeight: stack.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: stack
            width: parent.width
            spacing: 8

            Repeater {
                model: root.toasts.slice(-5)
                NotificationToast {
                    required property var modelData
                    notif: modelData
                    onExpired: root.drop(modelData)
                }
            }
        }
    }

    Timer { // prune notifications dismissed server-side (sender close, dismiss())
        interval: 2000; running: root.toasts.length > 0; repeat: true
        onTriggered: root.toasts = root.toasts.filter(t => t.tracked)
    }
}

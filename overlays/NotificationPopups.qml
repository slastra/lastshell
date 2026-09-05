import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
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

    ListModel { id: toasts }
    ListModel { id: history }
    property ListModel historyModel: history

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true

        onNotification: n => {
            if (!root.enabled) return
            n.tracked = true
            toasts.append({ notif: n })
            if (toasts.count > 5) toasts.remove(0)
            history.insert(0, { notif: n, time: Qt.formatTime(new Date(), "hh:mm AP") })
            if (history.count > 50) history.remove(50)
            const lamp = Quickshell.env("HOME") + "/.config/lastshell/lamp.sh"
            Quickshell.execDetached(["bash", lamp, n.urgency === 2 ? "alert" : "info"])
        }
    }

    function drop(n, dismissToo) {
        for (let i = 0; i < toasts.count; i++)
            if (toasts.get(i).notif === n) { toasts.remove(i); break }
        if (dismissToo) n.dismiss()
    }

    // Focus the window that sent an activated notification, so activation
    // carries the compositor to its virtual desktop. Match by desktop-entry
    // hint first (most reliable), then app name, against open Hyprland
    // clients. Lives here (not in the toast) because the toast delegate is
    // destroyed by the dismiss that accompanies activation.
    property var focusCands: []
    function focusSender(desktopEntry, appName) {
        focusCands = [desktopEntry, appName].filter(s => s).map(s => s.toLowerCase())
        if (focusCands.length > 0) clientsProc.running = true
    }
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let clients
                try { clients = JSON.parse(text) } catch (e) { return }
                const cands = root.focusCands
                const norm = c => (c ?? "").toLowerCase()
                // exact class match beats a heuristic/substring one
                const hit = clients.find(c => c.mapped && cands.includes(norm(c.class)))
                    ?? clients.find(c => c.mapped && cands.some(k =>
                        norm(c.class).includes(k) || k.includes(norm(c.class)) ||
                        norm(DesktopEntries.heuristicLookup(c.class)?.id) === k))
                if (hit) Hyprland.dispatch(`hl.dsp.focus({ window = "address:${hit.address}" })`)
            }
        }
    }

    Timer { // prune dismissed notifications from both models
        interval: 2000; running: toasts.count > 0 || history.count > 0; repeat: true
        onTriggered: {
            for (let i = toasts.count - 1; i >= 0; i--) {
                const n = toasts.get(i).notif
                if (!n || !n.tracked) toasts.remove(i)
            }
            for (let i = history.count - 1; i >= 0; i--) {
                const n = history.get(i).notif
                if (!n || !n.tracked) history.remove(i)
            }
        }
    }

    PanelWindow {
        visible: root.enabled && toasts.count > 0
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + 10; right: 10 }
        implicitWidth: 380
        implicitHeight: stack.contentHeight
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        ListView {
            id: stack
            anchors.fill: parent
            interactive: false
            spacing: 8
            // NOT `model: model` — that self-references the ListView's own
            // model property and silently renders nothing
            model: toasts

            delegate: NotificationToast {
                // `notif` is the component's own required property; the model
                // role fills it — redeclaring here shadows and breaks it
                onWantsOut: dismissToo => root.drop(notif, dismissToo)
                onFocusSender: (entry, app) => root.focusSender(entry, app)
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 40; to: 0; duration: 180; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 170; easing.type: Easing.InCubic }
                NumberAnimation { property: "x"; to: 40; duration: 170; easing.type: Easing.InCubic }
            }
            displaced: Transition {
                NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
            }
        }
    }
}

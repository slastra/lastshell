import Quickshell
import Quickshell.Io
import QtQuick

// Overlay host: IPC surface + the surfaces themselves. Summoned from
// binds.lua via `qs -c lastshell ipc call overlays <fn>`, and from bar
// widgets directly (no IPC round trip in-process).
Scope {
    id: root

    property alias switcher: switcher

    IpcHandler {
        target: "overlays"
        function toggleSwitcher(): void { switcher.toggle() }
    }

    TabSwitcher { id: switcher }
    VolumeOsd {}
}

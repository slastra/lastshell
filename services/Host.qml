pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which machine this is, so one tree serves both. The desk's chips (HDR,
// presence radar, deskwatch, the MQTT lamp) own daemons and hardware only
// the desk has; everything else is shared. LASTSHELL_HOST overrides the
// hostname, so the harness can render either layout from any machine.
Singleton {
    id: root

    readonly property string name: Quickshell.env("LASTSHELL_HOST") || hostname.text().trim()
    readonly property bool desk: name === "desk"
    readonly property bool laptop: name === "lap"

    FileView {
        id: hostname
        path: "/etc/hostname"
        // read before the bars build, so no desk chip flashes on the laptop
        blockLoading: true
    }
}

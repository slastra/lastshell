pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Desk presence, from deskpresence's status snapshot (written tmp+rename, so
// every change is one reload). The daemon owns the sensor and the TV; this
// only mirrors its verdict.
Singleton {
    id: root

    property bool loaded: false
    property bool present: false
    property bool known: false
    property bool sensorOk: false
    property bool busy: false
    property bool paused: false
    property string tv: ""          // "on" | "off" | ""
    property int state: 0           // sensor target: 0 none 1 moving 2 static 3 both
    property int distance: 0        // cm, closest reported target
    property double since: 0        // ms epoch of the last verdict flip
    // last 60 s of the signal the verdict is made from: max moving energy in
    // the near gates per 500 ms bin, oldest first, plus the verdict per bin
    property var history: []
    property var historyPresent: []
    property int threshold: 0

    readonly property string stateWord:
        state === 1 ? "moving" : state === 2 ? "static" : state === 3 ? "both" : "none"

    readonly property string pauseFile: Quickshell.env("XDG_RUNTIME_DIR") + "/deskpresence.pause"

    function togglePause() {
        Quickshell.execDetached(["sh", "-c",
            `if [ -e "${pauseFile}" ]; then rm -f "${pauseFile}"; else : > "${pauseFile}"; fi`])
    }

    function openView() {
        Quickshell.execDetached(["xdg-open", "http://127.0.0.1:7391/"])
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/deskpresence/history.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: parse()
        function parse() {
            try {
                const j = JSON.parse(text())
                root.history = j.near ?? []
                root.historyPresent = j.present ?? []
                root.threshold = j.threshold ?? 0
            } catch (e) { /* mid-write */ }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/deskpresence/status.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: parse()
        function parse() {
            try {
                const j = JSON.parse(text())
                root.present = !!j.present
                root.known = !!j.known
                root.sensorOk = !!j.sensor_ok
                root.busy = !!j.busy
                root.paused = !!j.paused
                root.tv = j.tv ?? ""
                root.state = j.state ?? 0
                root.distance = j.distance ?? 0
                root.since = j.since ?? 0
                root.loaded = true
            } catch (e) { /* mid-write */ }
        }
    }
}

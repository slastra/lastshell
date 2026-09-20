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
    property real fade: 0           // 0..1: how far the absence timer has run into its warning window
    // last 60 s of the signal the verdict is made from: max moving energy in
    // the near gates per 500 ms bin, oldest first, plus the verdict per bin
    property var history: []
    property var historyPresent: []
    property int threshold: 0

    readonly property string stateWord:
        state === 1 ? "moving" : state === 2 ? "static" : state === 3 ? "both" : "none"

    // Office Light follows presence unless this says "off" (read by
    // ~/.config/deskpresence/light-hook on every on|off; persists across reboots)
    property bool lightFollow: true
    readonly property string lightFlag: Quickshell.env("HOME") + "/.local/state/deskpresence/light-follow"
    // audio fade + MPRIS pause, gated inside the daemon by its -audio-flag file
    property bool audioFollow: true
    readonly property string audioFlag: Quickshell.env("HOME") + "/.local/state/deskpresence/audio-follow"
    // "keep awake": a timed pause the daemon expires itself; ms epoch, 0 = none
    property double holdUntil: 0
    readonly property string deskpresence: Quickshell.env("HOME") + "/go/bin/deskpresence"

    readonly property string pauseFile: Quickshell.env("XDG_RUNTIME_DIR") + "/deskpresence.pause"

    function togglePause() {
        Quickshell.execDetached(["sh", "-c",
            `if [ -e "${pauseFile}" ]; then rm -f "${pauseFile}"; else : > "${pauseFile}"; fi`])
    }

    // flip the flag; on re-enable, bring the light in line with the verdict
    // right away instead of waiting for the next presence change
    function toggleLight() {
        const next = lightFollow ? "off" : "on"
        lightFollow = next !== "off"   // our own write does not re-emit loaded
        lightFlagView.setText(next)
        if (next === "on" && known)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/deskpresence/light-hook", present ? "on" : "off"])
    }

    function toggleAudio() {
        audioFollow = !audioFollow
        audioFlagView.setText(audioFollow ? "on" : "off")
    }

    // hold(0) releases; status.json carries hold_until back within a tick
    function hold(minutes) {
        Quickshell.execDetached([deskpresence, "hold", minutes > 0 ? `${minutes}m` : "off"])
    }

    function openView() {
        Quickshell.execDetached(["xdg-open", "http://127.0.0.1:7391/"])
    }

    FileView {
        id: lightFlagView
        path: root.lightFlag
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.lightFollow = text().trim() !== "off"
    }

    FileView {
        id: audioFlagView
        path: root.audioFlag
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.audioFollow = text().trim() !== "off"
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
                root.holdUntil = j.hold_until ?? 0
                root.audioFollow = j.audio_follow ?? true
                root.tv = j.tv ?? ""
                root.state = j.state ?? 0
                root.distance = j.distance ?? 0
                root.since = j.since ?? 0
                root.fade = j.fade ?? 0
                root.loaded = true
            } catch (e) { /* mid-write */ }
        }
    }
}

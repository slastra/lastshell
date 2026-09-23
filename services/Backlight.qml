pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Panel backlight (the laptop; the desk has none, and brightnessctl there
// falls through to a NIC LED, so `present` gates everything). sysfs never
// fires inotify, but the kernel sends a backlight uevent on every change,
// so a udevadm watch reloads the value: hardware keys, the chip and a bare
// brightnessctl all land here the same way.
Singleton {
    id: root

    property string device: ""
    readonly property bool present: device !== ""
    property int max: 0
    property int raw: 0
    readonly property real frac: max > 0 ? raw / max : 0
    readonly property real step: 0.05
    // the floor keeps the panel lit: 0 turns it fully dark
    readonly property real min: 0.01

    function set(f) {
        f = Math.max(min, Math.min(1, f))
        Quickshell.execDetached(["brightnessctl", "-q", "set", `${Math.round(f * 100)}%`])
    }
    function nudge(delta) { set(frac + delta) }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.device = text.trim() }
    }

    FileView {
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 0
    }
    FileView {
        id: cur
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.raw = parseInt(text()) || 0
    }

    Process {
        running: root.present
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        stdout: SplitParser { onRead: line => { if (line.includes(" change ")) cur.reload() } }
    }
}

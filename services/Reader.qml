pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The narrator (Super+T): reads the selection, else the clipboard, aloud.
// scripts/reader.py is the engine (the old piper-reader GTK app's speech
// pipeline, headless): Piper or Kokoro renders passages ahead of the
// playhead into an mpv playlist, and terminal-looking text is rewritten for
// speech on OpenRouter first. It starts on the first read and then idles in
// its main loop, waking for nothing, so voices stay warm between reads.
Singleton {
    id: root

    property var voices: []          // [{key, label}]
    property var config: ({})        // {voice, speed, tidy, tidy_available}
    property var state: ({ active: false })

    readonly property bool active: state.active === true
    readonly property bool playing: active && !state.paused && !state.idle && !state.finished
    readonly property real progress: state.total > 0 ? Math.min(1, state.elapsed / state.total) : 0
    readonly property var tidyModes: ["Off", "Auto", "Always"]

    property var pending: []
    function send(cmd) {
        if (proc.running) proc.write(cmd + "\n")
        else { pending = pending.concat([cmd]); proc.running = true }
    }

    function read() { send("read") }
    function toggle() { if (active) send("toggle") }
    function next() { send("next") }
    function prev() { send("prev") }
    function stop() { send("stop") }
    function setSpeed(x) { send(`speed ${Math.round(x * 20) / 20}`) }
    function cycleVoice(d) {
        if (!voices.length) return
        const i = voices.findIndex(v => v.key === config.voice)
        send(`voice ${voices[(i + d + voices.length) % voices.length].key}`)
    }
    function cycleTidy(d) {
        const i = Math.max(0, tidyModes.indexOf(config.tidy))
        send(`tidy ${tidyModes[(i + d + tidyModes.length) % tidyModes.length]}`)
    }
    function voiceLabel() {
        return voices.find(v => v.key === config.voice)?.label ?? (config.voice || "no voices")
    }
    function clock(s) {
        s = Math.max(0, Math.floor(s || 0))
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = String(s % 60).padStart(2, "0")
        return h ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`
    }

    Process {
        id: proc
        command: ["python3", Quickshell.shellDir + "/scripts/reader.py"]
        stdinEnabled: true
        onStarted: {
            for (const c of root.pending) write(c + "\n")
            root.pending = []
        }
        onExited: root.state = { active: false }
        stdout: SplitParser {
            onRead: line => {
                const sp = line.indexOf(" ")
                if (sp < 0) return
                const kind = line.slice(0, sp)
                let v
                try { v = JSON.parse(line.slice(sp + 1)) } catch (e) { return }
                if (kind === "state") root.state = v
                else if (kind === "config") root.config = v
                else if (kind === "voices") root.voices = v
                else if (kind === "notice")  // comes back in as one of the shell's own toasts
                    Quickshell.execDetached(["notify-send", "-a", "Reader", "Reader", v])
            }
        }
    }

    IpcHandler {
        target: "reader"
        function read(): void { root.read() }
        function toggle(): void { root.toggle() }
        function stop(): void { root.stop() }
    }
}

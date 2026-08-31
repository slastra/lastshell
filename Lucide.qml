pragma Singleton
import QtQuick

// Lucide icon font (user-level install: ~/.local/share/fonts/lucide.ttf).
// Codepoints extracted from lucide.css; add entries as needed. Stroke-style
// icons that sit naturally beside the drawn instruments.
QtObject {
    readonly property string family: "lucide"

    readonly property var glyphs: ({
        "hourglass":     "",
        "calendar-days": "",
        "cpu":           "",
        "memory-stick":  "",
        "hard-drive":    "",
        "ethernet-port": "",
        "unplug":        "",
        "circle-dot":    "",
        "play":          "",
        "pause":         "",
        "music":         "",
        "globe":         "",
        "sparkles":      "",
    })

    function icon(name) { return glyphs[name] ?? "?" }
}

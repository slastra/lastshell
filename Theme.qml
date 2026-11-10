pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The shell's colors and measures. Colors are not chosen here: they come
// from the terminal's color scheme (kitty's colors.conf: background,
// foreground, color0-15), and every surface asks for a ROLE, never a hue.
// Swap the scheme file and the whole shell follows, live.
Singleton {
    id: root

    // ---- the scheme, as the terminal has it
    readonly property string schemePath: Quickshell.env("LASTSHELL_SCHEME")
        || (Quickshell.env("HOME") + "/.config/kitty/colors.conf")
    property var scheme: ({})
    function parse(text) {
        const out = {}
        for (const line of text.split("\n")) {
            const m = line.match(/^\s*([a-z_0-9]+)\s+(#[0-9a-fA-F]{6})\b/)
            if (m) out[m[1]] = m[2]
        }
        return out
    }
    FileView {
        path: root.schemePath
        blockLoading: true      // read before the bars build: no flash of the fallback
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.scheme = root.parse(text())
    }
    // the fallbacks are Vague on black, for a host with no scheme file (the greeter)
    function slot(name, fallback) { return scheme[name] ?? fallback }
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }

    // ---- neutrals: the background, stepped toward the foreground
    readonly property color base:    slot("background", "#000000")
    readonly property color text:    slot("foreground", "#cdcdcd")
    readonly property color surface: mix(base, text, 0.04)   // plates, cards
    readonly property color overlay: mix(base, text, 0.09)   // hover, bands, wells
    readonly property color border:  mix(base, text, 0.20)   // the hairline

    // ---- roles: one meaning each, the same on every surface. On a dark
    // background they take the scheme's bright variants (color9-14), which
    // are the ones drawn to be read against it; on a light one, the normal.
    readonly property bool dark: 0.299 * base.r + 0.587 * base.g + 0.114 * base.b < 0.5
    function hue(n, fallback) {
        const normal = slot("color" + n, fallback)
        return dark ? slot("color" + (n + 8), normal) : normal
    }
    readonly property color accent: hue(6, "#bebeda")   // focus, the active item, selection
    // `quiet` is the one-accent look: color marks what is active or on
    // (accent) and what needs attention (warn, crit), and nothing else.
    // Readings in their normal range are plain text and the supporting
    // hues fold into the accent or a neutral. Set it false for a hue per role.
    readonly property bool quiet: true
    readonly property color neutral: mix(base, text, 0.6)
    readonly property color ok:     quiet ? accent : hue(2, "#99b782")    // on, live, healthy
    readonly property color warn:   hue(3, "#f5cb96")   // waiting on you, warning
    readonly property color crit:   hue(1, "#e08398")   // critical, destructive, recording
    readonly property color info:   quiet ? accent : hue(4, "#8ba9c1")    // network, links, slider fills
    readonly property color agent:  quiet ? neutral : hue(5, "#c9b1ca")   // Claude, the voice assistants, labels
    readonly property color calm:   quiet ? text : ok   // a reading in its normal range

    // text at the alphas the popouts settled on; `track` is the neutral
    // slider/ring track, `divider` the rule between popout sections,
    // `seam` the hairline under modal headers and over footers
    readonly property color textMuted: Qt.alpha(text, 0.45)
    readonly property color textFaint: Qt.alpha(text, 0.35)
    readonly property color track:     Qt.alpha(text, 0.22)
    readonly property color divider:   overlay
    readonly property color seam:      border

    // ---- shape: lines and plates. Nothing is rounded but the instruments
    // (clock, rings, dots), which draw their own circles.
    readonly property int hairline: 1
    readonly property int overlayRadius: 0
    readonly property int innerRadius: 0

    readonly property int barHeight: 34
    readonly property string fontFamily: "ShureTechMono Nerd Font"
    // motion drops to 0 in eco mode: every animated frame is a bar repaint
    readonly property int animDuration: Eco.active ? 0 : 140
    readonly property int slideDuration: Eco.active ? 0 : 220   // item enter/exit
    readonly property int dragDuration: Eco.active ? 0 : 80     // slider fill following the pointer
    readonly property int sweepDuration: Eco.active ? 0 : 320   // gauge/bar sweeps to a new value
    readonly property int blinkDuration: 500   // caret and REC pulse half-period
    readonly property int tipDelay: 400        // ChipTip hover delay
    readonly property int popoutGrace: 250     // Popout hide grace
    readonly property int popoutGap: 0         // popouts and tips hang flush off their plate

    // Left-pad a metric to a fixed digit count, so an item keeps its width
    // as the value crosses 9→10 (the font is monospace; a change of width
    // re-centers the zone and slides everything beside it).
    function pad(v, n) { return String(v).padStart(n, " ") }

    // Threshold color: value against warn/crit cutoffs, `calm` by default.
    function level(v, warnAt, critAt, base) {
        return v >= critAt ? crit : v >= warnAt ? warn : (base ?? calm)
    }
}

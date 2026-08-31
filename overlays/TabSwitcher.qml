import Quickshell
import Quickshell.Io
import QtQuick
import ".."  // root module: Theme and friends

// Fuzzy browser-tab switcher (replaces the rofi tabs.sh script). Reads the
// same live snapshot as the TabStrip; activation re-resolves the row by tab
// id against the freshest parse, since the daemon can rewrite the file
// while the overlay is open and goto is positional.
SearchOverlay {
    id: root

    placeholder: "switch tab…"
    property var raw: []

    FileView {
        id: snap
        path: "/run/user/1000/waybar-fftabs.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: parse()
        function parse() {
            try { root.raw = JSON.parse(text()).tabs ?? [] } catch (e) {}
        }
    }

    items: raw.map((t, i) => ({ key: t.id, label: t.label, iconSource: "file://" + t.icon }))

    onActivated: item => {
        const idx = root.raw.findIndex(t => t.id === item.key)
        if (idx >= 0)
            Quickshell.execDetached(
                [Quickshell.env("HOME") + "/.local/bin/tabstrip", "goto", String(idx + 1)])
    }
}

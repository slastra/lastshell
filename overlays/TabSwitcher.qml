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

    typeIcon: "app-window"
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

    // Action rows: open a fresh window per known browser. Always offered
    // (a browser needn't have tabs connected to be worth launching); tiny
    // negative weight sorts them under real tabs on an empty query, while
    // typing "new" or the browser name fuzzy-finds them instantly.
    readonly property var browsers: [
        { name: "Firefox", cmd: ["firefox", "--new-window"] },
        { name: "Chrome",  cmd: ["google-chrome-stable", "--new-window"] },
    ]

    items: raw.map(t => ({ key: t.id, label: t.label, iconSource: "file://" + t.icon }))
        .concat(browsers.map(b => ({
            key: "new:" + b.name,
            label: `󰐕 New ${b.name} window`,
            iconSource: "file://" + Quickshell.env("HOME")
                + `/.cache/tabctl/favicons/_fallback-${b.name.toLowerCase()}.png`,
            weight: -1,
            cmd: b.cmd,
        })))

    onActivated: item => {
        if (item.cmd) {
            Quickshell.execDetached(item.cmd)
            return
        }
        const idx = root.raw.findIndex(t => t.id === item.key)
        if (idx >= 0)
            Quickshell.execDetached(
                [Quickshell.env("HOME") + "/.local/bin/tabstrip", "goto", String(idx + 1)])
    }
}

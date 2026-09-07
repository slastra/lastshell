import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import ".."  // root module: Theme and friends

// Launcher + window switcher in one (replaces rofi combi): open windows
// first, ordered by focus recency, then apps ranked by frecency. Enter on
// a window focuses it; on an app, launches it.
SearchOverlay {
    id: root

    typeIcon: "rocket"

    property var windows: []

    // Browser windows are left out: the tab switcher (SUPER+W) already
    // reaches every tab directly, so listing the windows here is noise.
    // Anchored on purpose — a loose /chrom|zen/ would also swallow Chrome
    // PWAs (chrome-<id>-Profile_N, app windows the switcher can't reach)
    // and Zenity/zenmap.
    readonly property var browserClass:
        /^(firefox(-\w+)?|librewolf|zen(-\w+)?|helium|brave-browser|vivaldi(-stable)?|chromium|google-chrome(-\w+)?|chrome)$/i

    // Refresh the window list at the moment of summoning — focusHistoryID
    // is the compositor's own recency order (0 = the window you came from).
    onOpenChanged: if (open) clientsProc.running = true
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(text)
                        .filter(c => c.mapped && c.title !== "" && !root.browserClass.test(c.class))
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                } catch (e) { root.windows = [] }
            }
        }
    }

    items: {
        const rows = []
        // Windows: most recent first; weight well above any app so they own
        // the top of an empty query. The window you're in sorts last of the
        // windows — you rarely switch to where you already are.
        root.windows.forEach((c, i) => {
            const entry = DesktopEntries.heuristicLookup(c.class)
            rows.push({
                key: "win:" + c.address,
                label: c.title,
                sublabel: c.class,
                iconSource: entry?.icon ? Quickshell.iconPath(entry.icon, "application-x-executable") : "",
                weight: c.focusHistoryID === 0 ? 500 : 1000 - i,
                address: c.address,
            })
        })
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            rows.push({
                key: e.id,
                label: e.name,
                sublabel: [e.genericName, (e.keywords ?? []).join(" ")].filter(x => x).join(" "),
                iconSource: e.icon ? Quickshell.iconPath(e.icon, "application-x-executable") : "",
                weight: Frecency.weight(e.id),
                entry: e,
            })
        }
        return rows
    }

    onActivated: item => {
        if (item.address) {
            // The overlay holds exclusive keyboard focus; SearchOverlay calls
            // dismiss() right after this, and when the layer surface releases
            // focus Hyprland hands it back to the PREVIOUS window (and its
            // workspace) — stomping a focus dispatch issued before that
            // handback. Let the release land first; the close fade hides it.
            focusLater.address = item.address
            focusLater.restart()
        } else {
            Frecency.record(item.key)
            item.entry.execute()
        }
    }
    Timer {
        id: focusLater
        property string address: ""
        interval: 80
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address}" })`)
    }
}

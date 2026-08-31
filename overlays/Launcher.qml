import Quickshell
import QtQuick
import ".."  // root module: Theme and friends

// App launcher (replaces rofi drun): fuzzy over desktop entries, ranked by
// match quality x frecency; empty query shows most-used apps.
SearchOverlay {
    id: root

    placeholder: "launch…"

    items: {
        const out = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            out.push({
                key: e.id,
                label: e.name,
                sublabel: [e.genericName, (e.keywords ?? []).join(" ")].filter(x => x).join(" "),
                iconSource: e.icon ? Quickshell.iconPath(e.icon, "application-x-executable") : "",
                weight: Frecency.weight(e.id),
                entry: e,
            })
        }
        // Empty query: SearchOverlay scores everything 1, weight decides.
        return out
    }

    onActivated: item => {
        Frecency.record(item.key)
        item.entry.execute()
    }
}

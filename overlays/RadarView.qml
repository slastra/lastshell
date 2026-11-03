import Quickshell
import QtQuick
import ".."  // root module

// Full storm view (SUPER+Shift+R, or click the radar chip). One pane at a
// time, since the card has to fit a 1536x864 logical screen: reflectivity
// with ProbSevere storms and the tracked vortex, dealiased velocity, MRMS
// rotation track, and the reflectivity loop. Images come from deskwatch's
// renderer under names that change per render, so a new render reloads.
Overlay {
    id: root

    cardWidth: 1120
    contentPadding: 2

    property int pane: 0
    readonly property var panes: [
        { key: "map", label: "Reflectivity" },
        { key: "velocity", label: "Velocity" },
        { key: "mrms", label: "Rotation" },
        { key: "loop", label: "Loop" },
    ]
    readonly property string src: Radar.url(Radar.images[panes[pane].key] ?? "")

    function point(deg) {
        const p = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        return p[Math.floor(((deg + 11.25) % 360) / 22.5) % 16]
    }
    function miles(km) { const m = km / 1.609; return m < 1 ? "<1 mi" : `${Math.round(m)} mi` }
    function clock(iso) { const d = Radar.parseLocal(iso); return d ? Qt.formatTime(d, "h:mm AP") : "" }
    function tierTone(s) { return s.tier === "urgent" ? Theme.love : s.tier === "high" ? Theme.gold : Theme.text }

    Column {
        width: parent.width
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) root.dismiss()
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.pane = (root.pane + 1) % root.panes.length
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.pane = (root.pane + root.panes.length - 1) % root.panes.length
            else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_4) root.pane = event.key - Qt.Key_1
            else return
            event.accepted = true
        }

        ModalHeader {
            icon: Radar.level === "urgent" ? "tornado" : "cloud-lightning"
            title: Radar.tornadoWarning ? "Radar · TORNADO WARNING"
                : Radar.severeWarning ? "Radar · severe thunderstorm warning"
                : Radar.watch ? "Radar · watch in effect" : "Radar"
            showQuery: false
            active: root.open

            Segmented {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 18
                width: 420
                options: root.panes.map((p, i) => ({ value: i, label: `${i + 1} ${p.label}` }))
                current: root.pane
                onPicked: v => root.pane = v
            }
        }

        Row {
            x: 18
            topPadding: 12
            bottomPadding: 12
            spacing: 18

            Item { // image pane, square-ish at the renderer's aspect
                width: 680
                height: 636

                Image {
                    anchors.fill: parent
                    visible: root.panes[root.pane].key !== "loop"
                    source: visible ? root.src : ""
                    cache: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                AnimatedImage {
                    anchors.fill: parent
                    visible: root.panes[root.pane].key === "loop"
                    source: visible ? root.src : ""
                    playing: visible && root.open
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                PopText {
                    anchors.centerIn: parent
                    visible: root.src === ""
                    text: "no imagery yet: the renderer runs while storms are near"
                    dim: 0.5
                }
            }

            Column { // what the daemon knows
                width: 1120 - 36 - 680 - 18
                spacing: 10

                Repeater {
                    model: Radar.homeAlerts.filter(a => /Warning|Watch/.test(a.event))
                    Column {
                        required property var modelData
                        width: parent.width
                        spacing: 1
                        PopText {
                            text: `${modelData.event}${modelData.ends ? "  until " + root.clock(modelData.ends) : ""}`
                            color: /Warning/.test(modelData.event) ? Theme.love : Theme.gold
                            font.bold: true
                            size: 14
                        }
                        PopText {
                            width: parent.width
                            text: modelData.headline ?? ""
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            dim: 0.55
                            size: 12
                        }
                    }
                }

                PopText {
                    visible: !!Radar.images.vortex
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Theme.love
                    size: 13
                    text: Radar.images.vortex
                        ? `Rotation tracked over ${Radar.images.vortex.scans} scans: ${Math.round(Radar.images.vortex.dv_kt)} kt ΔV, ${Radar.images.vortex.mph} mph → ${root.point(Radar.images.vortex.heading)}`
                        : ""
                }

                Divider { width: parent.width }

                Repeater {
                    model: Radar.notable.slice(0, 6)
                    Column {
                        required property var modelData
                        width: parent.width
                        spacing: 2
                        PopText {
                            text: `#${modelData.id}   Tor ${modelData.probtor}%  wind ${modelData.probwind}%  hail ${modelData.probhail}%`
                            color: root.tierTone(modelData)
                            font.bold: modelData.tier !== ""
                            size: 13
                        }
                        PopText {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            dim: 0.7
                            size: 12
                            text: modelData.over_home ? "over home now"
                                : `${root.miles(modelData.dist_km)} ${root.point(modelData.bearing)} · ${Math.round(modelData.mph)} mph → ${root.point(modelData.heading)}`
                                  + (modelData.eta_min >= 0 ? ` · passes ${root.miles(modelData.cpa_km)} ${root.point(modelData.pass_dir)} ~${root.clock(modelData.eta_at)}` : " · moving away")
                        }
                        PopText {
                            dim: 0.45
                            size: 11
                            text: `SRH ${Math.round(modelData.env.srh01)} · shear ${Math.round(modelData.env.ebshear)} kt · CAPE ${Math.round(modelData.env.mlcape)} · LCL ${Math.round(modelData.env.lcl)} m`
                                + (modelData.tor_hist.length > 1 ? ` · tor ${modelData.tor_hist.slice(-6).join("→")}` : "")
                        }
                    }
                }

                PopText {
                    visible: Radar.notable.length === 0
                    text: "no storm near home is scoring a tornado or wind signal"
                    dim: 0.5
                    size: 12
                }
            }
        }

        ModalFooter {
            hint: "1-4 or ←→ switch pane   esc close"
            count: [
                Radar.payload.valid ? `ProbSevere ${root.clock(Radar.payload.valid)}` : "",
                Radar.images.scan ? `${Radar.payload.radar ?? ""} ${Radar.images.scan}` : "",
                Radar.images.rendered_at ? `rendered ${root.clock(Radar.images.rendered_at)}` : "",
            ].filter(s => s).join("  ·  ")
        }
    }
}

import Quickshell
import QtQuick

// Storm radar chip. Absent on quiet days; foam radar while storms are
// around but none is aimed at home; gold lightning under a watch or a
// storm tracking toward home; love tornado, pulsing, under a tornado
// warning or an urgent track. The badge counts down to the nearest
// threat. Hover summarises, click opens RadarView (SUPER+Shift+R).
Chip {
    id: root
    edge: "top"
    present: Radar.active

    readonly property color tone:
        Radar.level === "urgent" ? Theme.love
        : Radar.level === "watch" ? Theme.gold
        : Theme.foam

    function tierTone(s) {
        return s.tier === "urgent" ? Theme.love : s.tier === "high" ? Theme.gold : Theme.text
    }

    // 16-point rose, as the daemon words its notifications.
    function point(deg) {
        const p = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        return p[Math.floor(((deg + 11.25) % 360) / 22.5) % 16]
    }
    function miles(km) { const m = km / 1.609; return m < 1 ? "<1 mi" : `${Math.round(m)} mi` }
    function clock(iso) { const d = Radar.parseLocal(iso); return d ? Qt.formatTime(d, "h:mm AP") : "" }

    function trackLine(s) {
        if (s.over_home) return "over home now"
        const pass = s.eta_min >= 0
            ? `passes ${miles(s.cpa_km)} ${point(s.pass_dir)} of home in ${Math.round(s.eta_min)}m`
            : "moving away"
        return `${miles(s.dist_km)} ${point(s.bearing)} · ${Math.round(s.mph)} mph → ${point(s.heading)} · ${pass}`
    }

    onClicked: Quickshell.execDetached(["qs", "-c", "lastshell", "ipc", "call", "overlays", "toggleRadar"])

    ChipBody {
        Badge {
            visible: Radar.nearest !== null && Radar.nearest.eta_min >= 0
            anchors.verticalCenter: parent.verticalCenter
            tone: root.tone
            text: Radar.nearest ? `${Math.round(Radar.nearest.eta_min)}m` : ""
        }

        LucideIcon {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            name: Radar.level === "urgent" ? "tornado"
                : Radar.level === "watch" ? "cloud-lightning" : "radar"
            color: root.tone

            // same pulse as the REC chip
            SequentialAnimation on opacity {
                running: Radar.level === "urgent"
                loops: Animation.Infinite
                NumberAnimation { to: 0.45; duration: Theme.blinkDuration }
                NumberAnimation { to: 1.0; duration: Theme.blinkDuration }
                onRunningChanged: if (!running) glyph.opacity = 1
            }
        }
    }

    Popout {
        owner: root

        Column {
            spacing: 8
            width: 380

            PopoutHeader {
                title: "Storms near home"
                status: Radar.tornadoWarning ? "tornado warning"
                    : Radar.severeWarning ? "severe t-storm warning"
                    : Radar.watch ? "watch"
                    : Radar.threats.length > 0 ? "storm headed this way" : "storms nearby"
                tone: root.tone
            }

            Repeater {
                model: Radar.homeAlerts.filter(a => /Warning|Watch/.test(a.event))
                Row {
                    required property var modelData
                    spacing: 6
                    readonly property color atone: /Warning/.test(modelData.event) ? Theme.love : Theme.gold
                    LucideIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: /Warning/.test(modelData.event) ? "siren" : "eye"
                        color: parent.atone
                        font.pixelSize: 13
                    }
                    PopText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${modelData.event}${modelData.ends ? "  until " + root.clock(modelData.ends) : ""}`
                        color: parent.atone
                        size: 13
                    }
                }
            }

            Divider { width: parent.width; visible: Radar.notable.length > 0 && Radar.homeAlerts.length > 0 }

            Repeater {
                model: Radar.notable.slice(0, 4)
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 1
                    PopText {
                        text: `Tor ${modelData.probtor}%  ·  wind ${modelData.probwind}%  ·  hail ${modelData.probhail}%`
                        color: root.tierTone(modelData)
                        font.bold: modelData.tier !== ""
                        size: 13
                    }
                    PopText {
                        width: parent.width
                        text: root.trackLine(modelData)
                        wrapMode: Text.WordWrap
                        dim: 0.7
                        size: 12
                    }
                }
            }

            Image {
                visible: status === Image.Ready
                width: parent.width
                height: visible ? width * sourceSize.height / Math.max(1, sourceSize.width) : 0
                source: Radar.url(Radar.images.map ?? "")
                cache: false
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            PopText {
                width: parent.width
                elide: Text.ElideRight
                text: [
                    Radar.payload.valid ? `ProbSevere ${root.clock(Radar.payload.valid)}` : "",
                    Radar.images.scan ? `${Radar.payload.radar} ${Radar.images.scan}` : "",
                    "click for more",
                ].filter(s => s).join("  ·  ")
                dim: 0.45
                size: 12
            }
        }
    }
}

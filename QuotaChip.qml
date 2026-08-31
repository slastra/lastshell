import QtQuick
import QtQuick.Controls

// Usage gauge: shows one quota frame, click cycles. Accent follows the
// WORST limit, not the shown one — critical stays loud while you browse.
// A thin fill bar along the chip's bottom edge draws the shown pct.
Chip {
    id: root
    edge: "bottom"
    visible: Claude.quota.frames.length > 0
    height: Theme.barHeight - 2

    property int frame: 0
    onClicked: frame = (frame + 1) % Math.max(1, Claude.quota.frames.length)

    readonly property var shown: Claude.quota.frames[frame % Math.max(1, Claude.quota.frames.length)] ?? { id: "", pct: 0 }
    readonly property color accent: Theme.level(Claude.quota.worstPct, 70, 90, Theme.foam)

    ChipText {
        height: root.height
        padRight: 17
        color: root.accent
        text: {
            const icon = root.shown.id === "5h" ? "󰔟" : "󰨴"
            return `${Math.round(root.shown.pct)}% ${icon}` + (Claude.quota.stale ? "*" : "")
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 2
        height: 2
        width: (parent.width - 4) * Math.min(1, root.shown.pct / 100)
        color: root.accent
        Behavior on width { NumberAnimation { duration: Theme.animDuration } }
    }

    ToolTip.visible: root.hovered
    ToolTip.delay: 400
    ToolTip.text: Claude.quota.frames.map(f =>
        `${f.id}: ${f.pct.toFixed(1)}%`).join("\n")
        + (Claude.quota.stale ? "\n(stale data)" : "")
}

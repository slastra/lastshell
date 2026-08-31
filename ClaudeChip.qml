import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls

// One Claude session: glyph shows Claude's state, border shows whether the
// session's terminal is the focused window (same active language as tabs).
// waiting = this session needs you: gold, gently pulsing.
Chip {
    id: root
    required property var session

    edge: "bottom"
    active: session.focused
    height: Theme.barHeight - 2

    readonly property bool waiting: session.state === "waiting"
    readonly property bool busy: session.state === "busy"

    onClicked: if (session.address)
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${session.address}" })`)

    ChipText {
        id: label
        height: root.height
        rightPadding: 12
        color: root.waiting ? Theme.gold : Theme.text
        text: {
            const glyph = root.waiting ? "󰋖" : root.busy ? "●" : "○"
            const xn = root.session.agents > 1 ? ` ×${root.session.agents}` : ""
            return `${glyph} ${root.session.label}${xn}`
        }
        SequentialAnimation on opacity {
            running: root.waiting
            loops: Animation.Infinite
            onStopped: label.opacity = 1
            NumberAnimation { to: 0.55; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
        }
    }

    ToolTip.visible: root.hovered
    ToolTip.delay: 400
    ToolTip.text: {
        const s = root.session
        const jobs = (s.jobs ?? []).map(j => `bg job: ${j.name} — ${j.status}`).join("\n")
        return [s.cwd, `status: ${s.state}`, jobs, `session: ${s.session ?? "—"}`,
                `uptime: ${s.uptime}`].filter(x => x).join("\n")
    }
}

import QtQuick

// Panel backlight chip, the laptop's counterpart to HdrChip. Wheel steps
// 5%, popout drags the full range. Absent wherever there is no backlight.
StatChip {
    id: root
    edge: "top"
    present: Backlight.present

    readonly property real b: Backlight.frac
    value: `${Math.round(b * 100)}%`
    icon: "sun"

    onWheelUp: Backlight.nudge(Backlight.step)
    onWheelDown: Backlight.nudge(-Backlight.step)

    Popout {
        owner: root

        Column {
            spacing: 8
            PopText {
                text: `Brightness ${Math.round(root.b * 100)}%`
                size: 14
                width: 220
            }
            SliderTrack {
                width: 220
                frac: root.b
                fill: Theme.gold
                interactive: true
                onSeek: f => Backlight.set(f)
            }
        }
    }
}

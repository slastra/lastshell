import Quickshell
import QtQuick

// Clock chip: 12h time, click toggles to the date form (waybar format-alt).
Chip {
    id: root
    edge: "top"

    property bool showDate: false
    onClicked: showDate = !showDate

    SystemClock { id: clock; precision: SystemClock.Seconds }

    ChipText {
        height: root.height
        padRight: 17
        text: root.showDate
            ? Qt.formatDateTime(clock.date, "ddd, dd MMM yyyy") + " 󰃭"
            : Qt.formatDateTime(clock.date, "hh:mm AP") + " "
    }
}

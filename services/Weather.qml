pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// wttrbar on a 30-minute cadence, exactly waybar's custom/weather.
Singleton {
    id: root

    property string text: ""
    property string tooltip: ""

    Timer {
        interval: 1800000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["wttrbar", "--fahrenheit", "--mph", "--nerd",
                  "--custom-indicator", "{temp_F}°F {ICON}"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    root.text = j.text ?? ""
                    root.tooltip = j.tooltip ?? ""
                } catch (e) { /* network hiccup; old value stands */ }
            }
        }
    }
}

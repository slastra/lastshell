import QtQuick

// The foam-family stat cluster: network, cpu, temp, disk, memory, recording,
// weather — thin views over the polled singletons, waybar thresholds kept.
Row {
    spacing: 8

    Chip {
        id: net
        edge: "top"
        visible: true
        ChipText {
            height: net.height
            padRight: 17
            color: Net.connected ? Theme.foam : Theme.love
            text: Net.connected ? `${Net.ip} 󰈀` : "Disconnected 󰈂"
        }
    }

    Chip {
        id: cpu
        edge: "top"
        ChipText {
            height: cpu.height
            padRight: 17
            color: Theme.level(SysStat.cpuPct, 25, 50)
            text: `${SysStat.cpuPct}% 󰻠`  // nf-md cpu; waybar's U+F4BC glyph doesn't resolve in Qt
        }
    }

    Chip {
        id: temp
        edge: "top"
        ChipText {
            height: temp.height
            padRight: 17
            color: Theme.level(SysStat.tempC, 70, 80)
            text: `${SysStat.tempC}°C 󰟈`
        }
    }

    Chip {
        id: disk
        edge: "top"
        ChipText {
            height: disk.height
            padRight: 17
            color: Theme.level(SysStat.diskPct, 70, 90)
            text: `${SysStat.diskPct}% 󰋊`
        }
    }

    Chip {
        id: mem
        edge: "top"
        ChipText {
            height: mem.height
            padRight: 17
            color: Theme.level(SysStat.memPct, 50, 75)
            text: `${SysStat.memPct}% 󰍛`  // nf-md memory; same story as cpu
        }
    }

    Chip {
        id: rec
        edge: "top"
        visible: Recorder.recording
        onClicked: Recorder.stop()
        ChipText {
            id: recText
            height: rec.height
            padRight: 17
            color: Theme.love
            text: "󰑊 REC"
            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.5; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }
    }

    Chip {
        id: weather
        edge: "top"
        visible: Weather.text !== ""
        ChipText {
            height: weather.height
            padRight: 17
            color: Theme.foam
            text: Weather.text
        }
    }
}

import QtQuick

// The foam-family stat cluster: network, cpu, temp, disk, memory, recording,
// weather — thin views over the polled singletons, waybar thresholds kept.
Row {
    spacing: 8

    Chip {
        id: net
        edge: "top"
        visible: true

        Popout {
            owner: net
            edge: "top"
            ownerHovered: net.hovered
            Column {
                spacing: 6
                Text {
                    text: `${Net.iface}: ${Net.ip}`
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14
                }
                Text {
                    function fmt(b) {
                        return b > 1e6 ? `${(b / 1e6).toFixed(1)} MB/s`
                             : b > 1e3 ? `${(b / 1e3).toFixed(0)} kB/s` : `${b.toFixed(0)} B/s`
                    }
                    text: `↓ ${fmt(Net.rxBps)}   ↑ ${fmt(Net.txBps)}`
                    color: Theme.foam; font.family: Theme.fontFamily; font.pixelSize: 14
                }
                NetGraph { width: 240; height: 60 }
            }
        }

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

        Popout {
            owner: weather
            edge: "top"
            ownerHovered: weather.hovered

            Column {
                spacing: 8

                Row {
                    spacing: 8
                    Text {
                        text: `${Weather.now.condition ?? "—"}`
                        color: Theme.text; font.family: Theme.fontFamily
                        font.pixelSize: 15; font.bold: true
                    }
                    Text {
                        text: `${Weather.now.temp ?? "?"}°`
                        color: Theme.foam; font.family: Theme.fontFamily
                        font.pixelSize: 15
                    }
                }
                Text {
                    text: `feels ${Weather.now.feels ?? "?"}°  ·  ${Weather.now.wind ?? ""}  ·  ${Weather.now.humidity ?? ""}`
                    color: Qt.alpha(Theme.text, 0.6)
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }
                Rectangle { width: 200; height: 1; color: Theme.overlay }
                Repeater {
                    model: Weather.days
                    Item {
                        required property var modelData
                        width: 200; height: 20
                        Text {
                            anchors.left: parent.left
                            text: modelData.name
                            color: Qt.alpha(Theme.text, 0.8)
                            font.family: Theme.fontFamily; font.pixelSize: 13
                        }
                        Text {
                            anchors.right: parent.right
                            text: `${modelData.hi}° / ${modelData.lo}°`
                            color: Theme.foam
                            font.family: Theme.fontFamily; font.pixelSize: 13
                        }
                    }
                }
            }
        }

        ChipText {
            height: weather.height
            padRight: 17
            color: Theme.foam
            text: Weather.text
        }
    }
}

import Quickshell
import QtQuick

// deskwatch chip: the desk's health at a glance. A quiet activity trace
// while everything is fine; a shield with a count when something needs
// you. Hover lists what is bad with the exact fix, plus the last verdicts
// the triager returned. Click opens the daemon's status in a terminal.
Chip {
    id: root
    edge: "top"
    visible: Deskwatch.loaded

    readonly property bool bad: Deskwatch.bad.length > 0
    readonly property color tone:
        Deskwatch.stale || !Deskwatch.tailUp ? Qt.alpha(Theme.text, 0.45)
        : bad ? Deskwatch.tone(Deskwatch.level)
        : Theme.foam

    onClicked: Quickshell.execDetached(
        ["kitty", "--hold", "-e", Quickshell.env("HOME") + "/go/bin/deskwatch", "status"])

    Row {
        height: root.height - 2
        spacing: 8
        leftPadding: 12
        rightPadding: 12

        Rectangle { // attention badge, only when crit/high is live
            visible: Deskwatch.attention > 0
            anchors.verticalCenter: parent.verticalCenter
            width: badgeText.implicitWidth + 10
            height: 16
            radius: 8
            color: Theme.overlay
            border.color: Qt.alpha(Theme.love, 0.6)
            border.width: 1
            Text {
                id: badgeText
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.love
                text: String(Deskwatch.attention)
            }
        }

        LucideIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: Deskwatch.stale || !Deskwatch.tailUp ? "radar"
                : root.bad ? "shield-alert" : "activity"
            color: root.tone
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
    }

    Popout {
        owner: root
        edge: "top"
        ownerHovered: root.hovered

        Column {
            spacing: 8
            width: 360

            Row {
                spacing: 8
                Text {
                    text: "deskwatch"
                    color: Theme.text; font.family: Theme.fontFamily
                    font.pixelSize: 14; font.bold: true
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: Deskwatch.stale ? "stale snapshot"
                        : !Deskwatch.tailUp ? "gateway tail down"
                        : root.bad ? Deskwatch.level : "all clear"
                    color: root.tone
                    font.family: Theme.fontFamily; font.pixelSize: 13
                }
            }

            Repeater {
                model: Deskwatch.bad
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 2
                    Text {
                        text: `${modelData.key}  ·  ${modelData.level}`
                        color: Deskwatch.tone(modelData.level)
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        width: parent.width
                        text: modelData.detail
                        wrapMode: Text.WordWrap
                        color: Qt.alpha(Theme.text, 0.85)
                        font.family: Theme.fontFamily; font.pixelSize: 13
                    }
                    Text {
                        visible: (modelData.fix ?? "") !== ""
                        width: parent.width
                        text: `$ ${modelData.fix}`
                        wrapMode: Text.WrapAnywhere
                        color: Qt.alpha(Theme.foam, 0.8)
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.overlay
                        visible: Deskwatch.verdicts.length > 0 }

            Repeater {
                model: Deskwatch.verdicts.slice(0, 3)
                Column {
                    required property var modelData
                    width: parent.width
                    spacing: 1
                    Text {
                        width: parent.width
                        elide: Text.ElideMiddle
                        text: `${modelData.verdict}  ${modelData.gkey.split("|").slice(0, 2).join(" ")}`
                        color: modelData.verdict === "benign" ? Qt.alpha(Theme.text, 0.6)
                             : modelData.verdict === "watch" ? Theme.gold : Theme.love
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    Text {
                        width: parent.width
                        text: modelData.reason
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Qt.alpha(Theme.text, 0.55)
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Text {
                text: [
                    Deskwatch.presence ? `presence ${Deskwatch.presence}` : "",
                    `${Deskwatch.evalsLastHour} evals/h`,
                    `gateway ${Deskwatch.age}s ago`,
                ].filter(s => s).join("  ·  ")
                color: Qt.alpha(Theme.text, 0.45)
                font.family: Theme.fontFamily; font.pixelSize: 12
            }
        }
    }
}

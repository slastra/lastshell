import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

// Bottom-bar browser tab strip. Pure view: tabstrip (the Go daemon) owns
// discovery, favicon fetch/processing, and ordering; this renders its
// snapshot and sends clicks back through the same CLI waybar used.
PanelWindow {
    id: root

    property var tabs: []

    anchors { bottom: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"

    FileView {
        id: snapshot
        path: "/run/user/1000/waybar-fftabs.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: parse()
        function parse() {
            try {
                root.tabs = JSON.parse(text()).tabs ?? []
            } catch (e) {
                // mid-write read; the rename lands momentarily
            }
        }
    }

    // No panel background — matches waybar's `window#waybar.fftabs
    // { background-color: transparent }`: the chips float on whatever is
    // behind the bar, carrying their own fills.
    Item {
        anchors.fill: parent

        Row {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 8
            spacing: 8

            Repeater {
                model: root.tabs

                // A literal browser-tab chip, matching the waybar CSS: surface
                // fill, 2px overlay border on top/left/right, rounded top
                // corners, open bottom edge; rose border when active. The
                // outer rect is the border, the inner rect the fill, inset on
                // three sides only so the chip stays attached to the bar edge.
                Rectangle {
                    id: chip
                    required property var modelData
                    required property int index

                    width: icon.width + 20
                    height: Theme.barHeight - 2
                    anchors.bottom: parent.bottom
                    topLeftRadius: 8
                    topRightRadius: 8
                    color: modelData.active ? Theme.rose : Theme.overlay

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        topLeftRadius: 6
                        topRightRadius: 6
                        color: mouse.containsMouse ? Theme.overlay : Theme.surface

                        Image {
                            id: icon
                            anchors.centerIn: parent
                            width: 18; height: 18
                            source: "file://" + chip.modelData.icon
                            sourceSize: Qt.size(36, 36) // decode above device pixels
                            smooth: true
                            // brightness is baked into the chip the daemon picked
                            // (bright vs -dim.png, by window focus) — don't re-dim
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/rofi/scripts/tabs.sh"])
                            else
                                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/tabstrip", "goto", String(chip.index + 1)])
                        }
                        onWheel: wheel => {
                            const dir = wheel.angleDelta.y > 0 ? "next" : "prev"
                            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/tabstrip", dir])
                        }
                        ToolTip.visible: containsMouse
                        ToolTip.delay: 400
                        ToolTip.text: chip.modelData.label ?? ""
                    }
                }
            }
        }
    }
}

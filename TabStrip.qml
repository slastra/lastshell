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

    Rectangle {
        anchors.fill: parent
        color: Theme.base

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 6
            spacing: 4

            Repeater {
                model: root.tabs

                Rectangle {
                    required property var modelData
                    required property int index

                    width: 22; height: 22; radius: 5
                    color: modelData.active ? Theme.overlay : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        source: "file://" + modelData.icon
                        sourceSize: Qt.size(36, 36) // decode above device pixels
                        smooth: true
                        // brightness is baked into the chip the daemon picked
                        // (bright vs -dim.png, by window focus) — don't re-dim
                    }

                    Rectangle { // active underline, reads at a glance like waybar's marker
                        visible: modelData.active
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 14; height: 2; radius: 1
                        color: Theme.iris
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/rofi/scripts/tabs.sh"])
                            else
                                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/tabstrip", "goto", String(index + 1)])
                        }
                        onWheel: wheel => {
                            const dir = wheel.angleDelta.y > 0 ? "next" : "prev"
                            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/tabstrip", dir])
                        }
                        ToolTip.visible: containsMouse
                        ToolTip.delay: 400
                        ToolTip.text: modelData.label ?? ""
                    }
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// System tray: one icon per StatusNotifierItem, left-click activate,
// right-click opens the item's DBus menu anchored to the icon.
Chip {
    id: root
    edge: "top"
    visible: SystemTray.items.values.length > 0

    Row {
        height: root.height
        spacing: 10
        leftPadding: 12
        rightPadding: 12

        Repeater {
            model: SystemTray.items

            Item {
                id: slot
                required property SystemTrayItem modelData
                width: 18
                height: root.height

                Image {
                    anchors.centerIn: parent
                    width: 18; height: 18
                    source: slot.modelData.icon
                    sourceSize: Qt.size(36, 36)
                }

                QsMenuAnchor {
                    id: menu
                    menu: slot.modelData.menu
                    anchor.item: slot
                    anchor.edges: Edges.Bottom
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton || slot.modelData.onlyMenu)
                            menu.open()
                        else
                            slot.modelData.activate()
                    }
                }
            }
        }
    }
}

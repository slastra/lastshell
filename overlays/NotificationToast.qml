import QtQuick
import ".."  // root module

// One notification card: urgency-colored border, icon, actions as chips.
Rectangle {
    id: root
    required property var notif
    signal expired()

    readonly property color urgencyColor:
        notif.urgency === 2 ? Theme.love : notif.urgency === 0 ? Theme.foam : Theme.rose

    width: 380
    implicitHeight: layout.implicitHeight + 24
    radius: Theme.overlayRadius
    color: Theme.surface
    border.color: urgencyColor
    border.width: 2

    Timer {
        id: expiry
        // critical (2) is sticky; hover pauses via running binding
        interval: 6000
        running: root.notif.urgency !== 2 && !hover.hovered
        onTriggered: root.expired()
    }
    HoverHandler { id: hover }

    TapHandler {
        onTapped: {
            const def = root.notif.actions?.find(a => a.identifier === "default") ?? root.notif.actions?.[0]
            if (def) def.invoke()
            root.notif.dismiss()
        }
    }

    Column {
        id: layout
        x: 12; y: 12
        width: parent.width - 24
        spacing: 6

        Row {
            spacing: 10
            width: parent.width
            Image {
                width: 32; height: 32
                visible: source != ""
                source: root.notif.image || root.notif.appIcon || ""
                sourceSize: Qt.size(64, 64)
            }
            Column {
                width: parent.width - 80
                spacing: 2
                Text {
                    text: root.notif.appName ?? ""
                    color: Theme.iris; font.family: Theme.fontFamily; font.pixelSize: 12
                    visible: text !== ""
                }
                Text {
                    text: root.notif.summary ?? ""
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 15
                    font.bold: true; width: parent.width; elide: Text.ElideRight
                }
                Text {
                    text: root.notif.body ?? ""
                    color: Qt.alpha(Theme.text, 0.8)
                    font.family: Theme.fontFamily; font.pixelSize: 13
                    width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3
                    elide: Text.ElideRight; visible: text !== ""
                    textFormat: Text.StyledText
                }
            }
            Text { // close
                text: "✕"; color: Qt.alpha(Theme.text, 0.5)
                font.pixelSize: 14
                TapHandler { onTapped: root.notif.dismiss() }
            }
        }

        Row {
            spacing: 6
            visible: (root.notif.actions?.length ?? 0) > 0
            Repeater {
                model: root.notif.actions ?? []
                Rectangle {
                    required property var modelData
                    width: actionText.implicitWidth + 20; height: 24; radius: 5
                    color: Theme.overlay
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    TapHandler { onTapped: { parent.modelData.invoke(); root.notif.dismiss() } }
                }
            }
        }
    }
}

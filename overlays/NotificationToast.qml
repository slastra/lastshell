import Quickshell
import QtQuick
import ".."  // root module

// One notification card. Urgency lives in the left accent bar and app-name
// tone, not a full border — critical is loud, normal is present, low is
// quiet. A countdown line drains along the bottom and pauses on hover;
// cards slide in from the right.
Rectangle {
    id: root
    required property var notif

    readonly property int urgency: notif.urgency ?? 1
    readonly property color urgencyColor:
        urgency === 2 ? Theme.love : urgency === 0 ? Theme.foam : Theme.rose
    readonly property int timeout: 6000
    readonly property bool sticky: urgency === 2

    width: 380
    implicitHeight: layout.implicitHeight + 24
    radius: Theme.overlayRadius
    color: Theme.surface
    border.color: Theme.overlay
    border.width: 2
    clip: true

    // Motion is owned by the ListView (add/remove/displaced transitions);
    // the card only decides WHEN to go and asks the stack to remove it.
    signal wantsOut(bool dismissToo)

    Timer {
        id: expiry
        interval: root.timeout
        running: !root.sticky && !hover.hovered
        onTriggered: root.wantsOut(false)
    }
    HoverHandler { id: hover }

    TapHandler {
        onTapped: {
            const def = root.notif.actions?.find(a => a.identifier === "default") ?? root.notif.actions?.[0]
            if (def) def.invoke()
            root.wantsOut(true)
        }
    }

    Text { // close — anchored to the card corner
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 12
        z: 1
        text: "✕"; color: Qt.alpha(Theme.text, 0.5)
        font.pixelSize: 14
        TapHandler { onTapped: root.wantsOut(true) }
    }

    Column {
        id: layout
        x: 16; y: 12
        width: parent.width - 32
        spacing: 6

        Row {
            id: headRow
            spacing: 10
            width: parent.width
            Image {
                id: appImage
                width: 32; height: 32
                visible: status === Image.Ready
                sourceSize: Qt.size(64, 64)
                source: {
                    const n = root.notif
                    if (n.image) return n.image
                    if (!n.appIcon) return ""
                    // appIcon may be a path or a themed icon name
                    return n.appIcon.startsWith("/") || n.appIcon.startsWith("file:")
                        ? n.appIcon : Quickshell.iconPath(n.appIcon, "")
                }
            }
            Column {
                width: headRow.width - (appImage.visible ? appImage.width + headRow.spacing : 0) - 28
                spacing: 2
                Item {
                    width: parent.width; height: appName.implicitHeight
                    Text {
                        id: appName
                        text: root.notif.appName ?? ""
                        color: Qt.alpha(root.urgencyColor, 0.9)
                        font.family: Theme.fontFamily; font.pixelSize: 12
                        visible: text !== ""
                    }
                    Text {
                        anchors.right: parent.right
                        text: Qt.formatTime(new Date(), "hh:mm AP")
                        color: Qt.alpha(Theme.text, 0.35)
                        font.family: Theme.fontFamily; font.pixelSize: 11
                    }
                }
                Text {
                    text: root.notif.summary ?? ""
                    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 15
                    font.bold: true; width: parent.width; elide: Text.ElideRight
                }
                Text {
                    text: root.notif.body ?? ""
                    color: Qt.alpha(Theme.text, 0.75)
                    font.family: Theme.fontFamily; font.pixelSize: 13
                    width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3
                    elide: Text.ElideRight; visible: text !== ""
                    textFormat: Text.StyledText
                }
            }
        }

        Row {
            spacing: 6
            visible: (root.notif.actions?.length ?? 0) > 0
            Repeater {
                model: root.notif.actions ?? []
                Rectangle {
                    required property var modelData
                    width: actionText.implicitWidth + 22; height: 26; radius: 6
                    color: actionHover.hovered ? Theme.overlay : "transparent"
                    border.color: Qt.alpha(Theme.iris, 0.5)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animDuration } }
                    HoverHandler { id: actionHover }
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: Theme.iris; font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                    TapHandler { onTapped: { parent.modelData.invoke(); root.wantsOut(true) } }
                }
            }
        }
    }

    Rectangle { // countdown: drains toward expiry, holds while hovered
        visible: !root.sticky
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.bottomMargin: 2
        height: 2
        color: Qt.alpha(root.urgencyColor, 0.55)
        width: parent.width - 4
        NumberAnimation on width {
            id: drain
            running: !root.sticky
            from: root.width - 4; to: 0
            duration: root.timeout
        }
        // hover pauses the timer; pause the drain with it
        Connections {
            target: hover
            function onHoveredChanged() {
                if (hover.hovered) drain.pause()
                else drain.resume()
            }
        }
    }
}

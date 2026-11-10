import Quickshell
import QtQuick
import ".."  // root module

// One notification card. Urgency lives in the app name's tone and a faint
// wash of it over the card: critical is loud, normal is present, low is
// quiet. A countdown ring drains around the close button and waits while
// the pointer is on the stack; cards slide in from the right.
Rectangle {
    id: root
    required property var notif
    required property string time
    // bumped when the sender replaces the notification: the countdown restarts
    required property int rev
    // the pointer is on the stack: every countdown waits
    property bool held: false

    readonly property int urgency: notif.urgency ?? 1
    readonly property color urgencyColor: body.tone
    // the sender's expire_timeout when it gave one (2-30 s); 0 and -1 both
    // fall to the default, since plenty of senders pass 0 unconditionally
    readonly property int timeout: notif.expireTimeout > 0
        ? Math.min(30000, Math.max(2000, notif.expireTimeout)) : 6000
    readonly property bool sticky: urgency === 2

    width: 380
    implicitHeight: layout.implicitHeight + 24
    radius: Theme.overlayRadius
    // surface washed with the urgency tone — enough to read at a glance,
    // faint enough that Rosé Pine still owns the card
    color: Qt.tint(Theme.surface, Qt.alpha(urgencyColor, 0.09))
    border.color: Qt.tint(Theme.border, Qt.alpha(urgencyColor, 0.18))
    border.width: 2
    clip: true

    // Motion is owned by the ListView (add/remove/displaced transitions);
    // the card only decides WHEN to go and asks the stack to remove it.
    signal wantsOut(bool dismissToo)
    // Body click. The action invoke + window focus + dismiss all happen in
    // the stable Popups scope: they are async and this delegate is gone
    // once the toast leaves the stack.
    signal activated()
    // An action button. Same reason: invoking it can make the sender close
    // the notification, which destroys this delegate mid-handler.
    signal actionChosen(var action)

    // One clock for the card: the ring is drawn from `remaining` and the
    // card leaves when it runs out, so the two cannot disagree. Stepped by
    // a Timer, not animated: an animation would repaint the stack at display
    // refresh for the whole life of every toast. Eco takes coarser steps.
    property real remaining: 1
    onRevChanged: remaining = 1
    Timer {
        // measured, not counted: a late tick still takes off the time it took
        property double last: 0
        interval: Eco.active ? 500 : 50
        repeat: true
        running: !root.sticky && !root.held && root.remaining > 0
        onRunningChanged: last = Date.now()
        onTriggered: {
            const now = Date.now()
            root.remaining = Math.max(0, root.remaining - (now - last) / root.timeout)
            last = now
            if (root.remaining === 0) root.wantsOut(false)
        }
    }

    // The buttons inside take the press for themselves (WithinBounds is an
    // exclusive grab, and one TapHandler does not take over from another),
    // so a tap on one is not also a tap on the card.
    TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: root.activated() }

    Item { // close, with the countdown as a ring draining around it
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 10
        z: 1
        width: 24; height: 24

        Canvas {
            id: ring
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (root.sticky) return
                const c = width / 2, r = c - 1.5
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.strokeStyle = Qt.alpha(Theme.text, 0.15)
                ctx.beginPath(); ctx.arc(c, c, r, 0, 2 * Math.PI); ctx.stroke()
                if (root.remaining > 0) {
                    ctx.strokeStyle = Qt.alpha(root.urgencyColor, 0.8)
                    ctx.beginPath()
                    ctx.arc(c, c, r, -Math.PI / 2,
                            -Math.PI / 2 + 2 * Math.PI * root.remaining)
                    ctx.stroke()
                }
            }
        }
        Connections {
            target: root
            function onRemainingChanged() { ring.requestPaint() }
            function onUrgencyColorChanged() { ring.requestPaint() }
        }

        Text {
            anchors.centerIn: parent
            // the glyph's ink sits high in its em box; nudge down to center
            // it inside the ring optically
            anchors.verticalCenterOffset: 1
            text: "✕"; color: Qt.alpha(Theme.text, 0.55)
            font.pixelSize: 12
        }
        TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: root.wantsOut(true) }
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
            NotifBody {
                id: body
                width: headRow.width - (appImage.visible ? appImage.width + headRow.spacing : 0) - 28
                notif: root.notif
                time: root.time
            }
        }

        Row {
            spacing: 6
            // Only actions with a visible label become buttons. Senders often
            // attach a "default" action with empty text — that one is meant
            // for the body click (which invokes it above), not a chip; it was
            // rendering as an empty button.
            readonly property var shownActions:
                (root.notif.actions ?? []).filter(a => (a.text ?? "").trim() !== "")
            visible: shownActions.length > 0
            Repeater {
                model: parent.shownActions
                Rectangle {
                    required property var modelData
                    width: actionText.implicitWidth + 22; height: 26; radius: Theme.innerRadius
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
                    TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: root.actionChosen(parent.modelData) }
                }
            }
        }
    }

}

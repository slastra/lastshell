import QtQuick
import ".."  // root module: Theme and friends
import "Fuzzy.js" as Fuzzy

// Shared switcher/launcher chrome: type-to-filter list, keyboard driven.
// Feed `items` ([{key,label,sublabel,iconSource,weight,...}]). Matched
// characters light up gold; a rose blade slides between rows instead of
// each row painting its own cursor.
Overlay {
    id: root

    property var items: []
    property string query: ""
    property string placeholder: ""
    property int maxRows: 14
    signal activated(var item)

    cardWidth: 560
    readonly property int rowH: 40

    readonly property var filtered: {
        const out = []
        for (const it of items) {
            const m = Fuzzy.match(query, it.label + " " + (it.sublabel ?? ""))
            if (m.score > 0)
                out.push(Object.assign({ _score: m.score, _idx: m.idx }, it))
        }
        out.sort((a, b) => b._score - a._score || (b.weight ?? 0) - (a.weight ?? 0))
        return out.slice(0, maxRows)
    }
    property int cursor: 0
    onQueryChanged: cursor = 0
    onOpenChanged: if (open) { query = ""; cursor = 0 }

    function activate() {
        if (filtered[cursor]) { activated(filtered[cursor]); dismiss() }
    }

    Column {
        width: parent.width
        spacing: 10
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                root.query !== "" ? root.query = "" : root.dismiss()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.activate()
            else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)))
                root.cursor = Math.min(root.filtered.length - 1, root.cursor + 1)
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
                root.cursor = Math.max(0, root.cursor - 1)
            else if (event.key === Qt.Key_Backspace)
                root.query = root.query.slice(0, -1)
            else if (event.text && event.text >= " ")
                root.query += event.text
            else
                return
            event.accepted = true
        }

        Rectangle { // query field: the modal's focal point
            width: parent.width
            height: 42
            radius: 7
            color: Theme.overlay
            // hairline that warms up while a query is live
            border.width: 1
            border.color: root.query !== "" ? Qt.alpha(Theme.rose, 0.5) : Qt.alpha(Theme.iris, 0.25)
            Behavior on border.color { ColorAnimation { duration: Theme.animDuration } }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: 14
                spacing: 10
                Text { // prompt glyph
                    anchors.verticalCenter: parent.verticalCenter
                    text: "❯"
                    color: root.query !== "" ? Theme.rose : Qt.alpha(Theme.iris, 0.7)
                    font.family: Theme.fontFamily; font.pixelSize: 16
                    Behavior on color { ColorAnimation { duration: Theme.animDuration } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: root.query === "" ? Qt.alpha(Theme.text, 0.35) : Theme.text
                    text: root.query === "" ? root.placeholder : root.query
                }
                Rectangle { // caret
                    visible: root.open
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2; height: 20; color: Theme.rose
                    SequentialAnimation on opacity {
                        running: root.open; loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }
            }
        }

        Item { // result list with a sliding cursor blade
            width: parent.width
            height: root.filtered.length > 0
                ? root.filtered.length * root.rowH + (root.filtered.length - 1) * 2
                : 34

            Rectangle { // cursor plate: rose outline, gliding between rows —
                        // the same active language the bar chips speak
                visible: root.filtered.length > 0
                y: root.cursor * (root.rowH + 2)
                width: parent.width
                height: root.rowH
                radius: 6
                color: Theme.overlay
                border.width: 2
                border.color: Qt.alpha(Theme.rose, 0.8)
                Behavior on y { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            }

            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.filtered

                    Item {
                        id: row
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: root.rowH

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 14
                            spacing: 10
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20
                                source: row.modelData.iconSource ?? ""
                                sourceSize: Qt.size(40, 40)
                                visible: source != ""
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                color: row.index === root.cursor ? Theme.text : Qt.alpha(Theme.text, 0.75)
                                textFormat: Text.StyledText
                                text: Fuzzy.highlight(row.modelData.label, row.modelData._idx, Theme.gold.toString())
                                width: 460
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.cursor = row.index; root.activate() }
                        }
                    }
                }
            }

            Text { // empty state
                visible: root.filtered.length === 0
                anchors.centerIn: parent
                text: "no matches"
                color: Qt.alpha(Theme.love, 0.7)
                font.family: Theme.fontFamily; font.pixelSize: 14
                font.italic: true
            }
        }

        Item { // footer: hints left, count right
            width: parent.width
            height: 18
            Text {
                anchors.left: parent.left
                text: "↑↓ navigate   ↵ open   esc close"
                color: Qt.alpha(Theme.iris, 0.55)
                font.family: Theme.fontFamily; font.pixelSize: 12
            }
            Text {
                anchors.right: parent.right
                text: root.query === "" ? `${root.items.length}` : `${root.filtered.length}/${root.items.length}`
                color: Qt.alpha(Theme.text, 0.4)
                font.family: Theme.fontFamily; font.pixelSize: 12
            }
        }
    }
}

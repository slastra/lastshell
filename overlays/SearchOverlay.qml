import QtQuick
import ".."  // root module: Theme and friends
import "Fuzzy.js" as Fuzzy

// Shared switcher/launcher chrome: type-to-filter list, keyboard driven.
// Feed `items` ([{key,label,sublabel,iconSource,...}]); rows are scored by
// label (+sublabel) and re-sorted live. Enter/click emit activated(item).
Overlay {
    id: root

    property var items: []
    property string query: ""
    property string placeholder: ""
    property int maxRows: 14
    signal activated(var item)

    cardWidth: 560

    readonly property var filtered: {
        const out = []
        for (const it of items) {
            const s = Fuzzy.score(query, it.label + " " + (it.sublabel ?? ""))
            if (s > 0) out.push(Object.assign({ _score: s }, it))
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
        spacing: 8
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

        Rectangle { // query field
            width: parent.width
            height: 36
            radius: 6
            color: Theme.overlay
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 12
                font.family: Theme.fontFamily
                font.pixelSize: 16
                color: root.query === "" ? Qt.alpha(Theme.text, 0.4) : Theme.text
                text: root.query === "" ? root.placeholder : root.query
            }
            Rectangle { // caret
                visible: root.open
                x: 12 + queryMetrics.advanceWidth + 2
                anchors.verticalCenter: parent.verticalCenter
                width: 2; height: 20; color: Theme.rose
                SequentialAnimation on opacity {
                    running: root.open; loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 500 }
                    NumberAnimation { to: 1; duration: 500 }
                }
            }
            TextMetrics {
                id: queryMetrics
                font.family: Theme.fontFamily
                font.pixelSize: 16
                text: root.query
            }
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: root.filtered

                Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: 38
                    radius: 6
                    color: index === root.cursor ? Theme.overlay : "transparent"

                    Rectangle { // rose cursor accent
                        visible: row.index === root.cursor
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: 22; radius: 1.5
                        color: Theme.rose
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
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
                            color: row.index === root.cursor ? Theme.rose : Theme.text
                            text: row.modelData.label
                            width: 440
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
    }
}

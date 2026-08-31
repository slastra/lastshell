import QtQuick

// One lucide glyph, tinted like text. Sized slightly under the text size —
// lucide draws to the full em square and reads large beside ShureTechMono.
Text {
    property string name
    // lucide draws low on its em square next to ShureTechMono's centerline;
    // one logical pixel up optically centers it wherever the icon is
    // verticalCenter-anchored (offset applies only when that anchor is set)
    anchors.verticalCenterOffset: -1
    font.family: Lucide.family
    font.pixelSize: 15
    color: Theme.text
    text: Lucide.icon(name)
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.animDuration } }
}

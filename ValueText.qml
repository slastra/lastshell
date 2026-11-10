import QtQuick

// Chip value text, centered by its INK rather than its line box: the
// baseline sits half a cap height below the slot's center, so digits and
// capitals straddle the same center line as the icons beside them, whatever
// the font. (Centering the line box put ShureTechMono high and Geist Mono
// low, since each leaves different room above and below its letters.)
//
// Placing by baseline also keeps a glyph from a fallback font (Claude's ◐
// spinner in a window title comes from Noto Sans Mono) from growing the
// line box and dropping the whole line 1-2 px.
Text {
    id: root
    anchors.baseline: parent.verticalCenter
    // FontMetrics has no capHeight; a digit is the same height
    anchors.baselineOffset: metrics.tightBoundingRect("0").height / 2
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(16 * Theme.fontScale)
    color: Theme.text
    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    FontMetrics { id: metrics; font: root.font }
}

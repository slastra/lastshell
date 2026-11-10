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
    // FontMetrics has no capHeight, so a digit is measured instead, and at
    // a large size: at text size the answer is rounded to whole pixels and
    // changes with the display scale (10 at 1.0, 12 at 1.25 for the same
    // 14 px Geist Mono), which sank the text on a fractionally scaled screen.
    // Less 0.6 px: the icons' ink rides that much above the true center
    // (measured at 1.0 and 1.25 scale), and text has to agree with them.
    anchors.baselineOffset: font.pixelSize * probe.tightBoundingRect("0").height / 400 / 2 - 0.6
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(16 * Theme.fontScale)
    color: Theme.text
    Behavior on color { ColorAnimation { duration: Theme.animDuration } }

    FontMetrics { id: probe; font.family: root.font.family; font.pixelSize: 400 }
}

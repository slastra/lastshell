import QtQuick

// Package-temperature sparkline over SysStat.tempHistory. Fixed 30..90°C
// scale (same span as the chip's thermometer) rather than NetGraph's
// peak-relative one, so height reads as absolute heat; dashed guides mark
// the 70° warning and 80° critical lines, and the trace takes the current
// reading's tone.
Canvas {
    id: canvas

    readonly property real lo: 30
    readonly property real hi: 90

    Connections { target: SysStat; function onTempHistoryChanged() { canvas.requestPaint() } }

    function yFor(t) {
        const frac = Math.max(0, Math.min(1, (t - lo) / (hi - lo)))
        return height - frac * (height - 2) - 1
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        // threshold guides
        ctx.lineWidth = 1
        ctx.setLineDash([3, 3])
        for (const [t, color] of [[70, Theme.gold], [80, Theme.love]]) {
            const y = Math.round(yFor(t)) + 0.5
            ctx.strokeStyle = Qt.alpha(color, 0.35)
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
        }
        ctx.setLineDash([])

        const h = SysStat.tempHistory
        if (h.length < 2) return
        const tone = Theme.level(SysStat.tempC, 70, 80)
        const xFor = i => i / (h.length - 1) * width

        // soft fill under the trace
        ctx.fillStyle = Qt.alpha(tone, 0.12)
        ctx.beginPath()
        ctx.moveTo(xFor(0), height)
        h.forEach((t, i) => ctx.lineTo(xFor(i), yFor(t)))
        ctx.lineTo(xFor(h.length - 1), height)
        ctx.closePath()
        ctx.fill()

        // the trace
        ctx.strokeStyle = tone
        ctx.lineWidth = 1.5
        ctx.beginPath()
        h.forEach((t, i) => i === 0 ? ctx.moveTo(xFor(i), yFor(t)) : ctx.lineTo(xFor(i), yFor(t)))
        ctx.stroke()
    }
}

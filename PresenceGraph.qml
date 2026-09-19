import QtQuick

// The presence signal itself: max moving energy in the near gates over the
// last minute, on a fixed 0..100 scale, with the daemon's threshold as a
// dashed guide and its verdict as a strip along the bottom. Same idiom as
// TempGraph: absolute scale, guide lines, soft fill under the trace.
Canvas {
    id: canvas

    Connections { target: Presence; function onHistoryChanged() { canvas.requestPaint() } }

    readonly property real stripH: 3
    function yFor(e) {
        const frac = Math.max(0, Math.min(1, e / 100))
        return (height - stripH - 2) - frac * (height - stripH - 4) - 1
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const h = Presence.history
        const pr = Presence.historyPresent
        const n = h.length
        if (n < 2) return
        const xFor = i => i / (n - 1) * width

        // threshold guide
        if (Presence.threshold > 0) {
            const y = Math.round(yFor(Presence.threshold)) + 0.5
            ctx.lineWidth = 1
            ctx.setLineDash([3, 3])
            ctx.strokeStyle = Qt.alpha(Theme.text, 0.35)
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
            ctx.setLineDash([])
        }

        // soft fill, then the trace
        const tone = Presence.present ? Theme.foam : Qt.alpha(Theme.text, 0.5)
        ctx.beginPath()
        ctx.moveTo(0, yFor(0))
        h.forEach((e, i) => ctx.lineTo(xFor(i), yFor(e)))
        ctx.lineTo(width, yFor(0))
        ctx.closePath()
        ctx.fillStyle = Qt.alpha(tone, 0.12)
        ctx.fill()

        ctx.strokeStyle = tone
        ctx.lineWidth = 1.5
        ctx.lineJoin = "round"
        ctx.beginPath()
        h.forEach((e, i) => i === 0 ? ctx.moveTo(xFor(i), yFor(e)) : ctx.lineTo(xFor(i), yFor(e)))
        ctx.stroke()

        // verdict strip: foam while present, muted while away
        const w = width / n
        for (let i = 0; i < n; i++) {
            ctx.fillStyle = pr[i] ? Qt.alpha(Theme.foam, 0.8) : Qt.alpha(Theme.text, 0.18)
            ctx.fillRect(i * w, height - stripH, w + 0.5, stripH)
        }
    }
}

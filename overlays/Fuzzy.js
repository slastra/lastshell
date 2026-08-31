// Subsequence fuzzy scorer: every query char must appear in order.
// Bonuses for word starts and consecutive runs; 0 = no match.
.pragma library

function score(query, target) {
    if (!query) return 1
    const q = query.toLowerCase(), t = target.toLowerCase()
    let qi = 0, s = 0, streak = 0
    for (let ti = 0; ti < t.length && qi < q.length; ti++) {
        if (t[ti] === q[qi]) {
            streak++
            s += 1 + streak * 2
            if (ti === 0 || t[ti - 1] === " " || t[ti - 1] === "-" || t[ti - 1] === "/")
                s += 8
            qi++
        } else {
            streak = 0
        }
    }
    return qi === q.length ? s : 0
}

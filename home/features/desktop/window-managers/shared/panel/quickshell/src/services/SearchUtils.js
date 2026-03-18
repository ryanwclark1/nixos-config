.pragma library

// Fuzzy-score how well `query` matches `target` (both lowercase).
// Returns 0 for no match; higher = better.
// Exact substring → 1000 + position bonus.
// Fuzzy consecutive chars → sum of match bonuses with gap penalties.
// Options:
//   minFuzzyLength — minimum query length for fuzzy matching (default 0)
//   minFuzzyScore  — minimum score threshold for short queries (default 0)
function fuzzyScore(query, target, options) {
    if (!query || !target)
        return 0;

    // Exact substring gets highest priority
    var exactIdx = target.indexOf(query);
    if (exactIdx !== -1)
        return 1000 + (1.0 / (1 + exactIdx));

    var minLen = (options && options.minFuzzyLength) || 0;
    if (query.length <= minLen)
        return 0;

    // Fuzzy: walk through query chars, find them in order in target
    var qi = 0, score = 0, lastMatch = -1;
    for (var ti = 0; ti < target.length && qi < query.length; ti++) {
        if (target[ti] === query[qi]) {
            var gap = lastMatch >= 0 ? (ti - lastMatch - 1) : 0;
            score += 10 - Math.min(gap, 8);
            if (ti === 0 || target[ti - 1] === ' ' || target[ti - 1] === '/' || target[ti - 1] === '-' || target[ti - 1] === '_')
                score += 5;
            lastMatch = ti;
            qi++;
        }
    }

    if (qi !== query.length)
        return 0;

    var minScore = (options && options.minFuzzyScore) || 0;
    return score >= minScore ? score : 0;
}

// Filter and sort an array of items by fuzzy relevance.
// `textFn(item)` must return the lowercase search text for each item.
// Returns items sorted by score (highest first), excluding non-matches.
function filterByFuzzy(items, query, textFn, options) {
    if (!query)
        return items;
    var q = query.toLowerCase();
    var scored = [];
    for (var i = 0; i < items.length; i++) {
        var item = items[i];
        var text = textFn(item);
        if (!text)
            continue;
        var s = fuzzyScore(q, text, options);
        if (s > 0)
            scored.push({ item: item, score: s });
    }
    scored.sort(function(a, b) { return b.score - a.score; });
    var result = [];
    for (var j = 0; j < scored.length; j++)
        result.push(scored[j].item);
    return result;
}

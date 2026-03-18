.pragma library

function highlightMatch(fullText, query, stripPrefixFn) {
    if (!query || !fullText)
        return fullText;
    
    var cleanQuery = stripPrefixFn ? stripPrefixFn(query) : query;
    if (!cleanQuery || cleanQuery.trim() === "")
        return fullText;

    var q = cleanQuery.toLowerCase();
    var t = fullText.toLowerCase();
    
    // Direct substring match (preferred)
    var directIdx = t.indexOf(q);
    if (directIdx !== -1) {
        return fullText.substring(0, directIdx) + 
               "<b>" + fullText.substring(directIdx, directIdx + q.length) + "</b>" + 
               fullText.substring(directIdx + q.length);
    }

    // Fuzzy character match
    var result = "";
    var queryIdx = 0;
    var inBold = false;

    for (var i = 0; i < fullText.length; i++) {
        var char = fullText[i];
        if (queryIdx < q.length && char.toLowerCase() === q[queryIdx]) {
            if (!inBold) {
                result += "<b>";
                inBold = true;
            }
            result += char;
            queryIdx++;
        } else {
            if (inBold) {
                result += "</b>";
                inBold = false;
            }
            result += char;
        }
    }
    
    if (inBold) result += "</b>";
    return result;
}

function fuzzyMatchLower(s, p) {
    if (!p)
        return 100;
    if (!s)
        return 0;
    if (s.startsWith(p))
        return 100 + (p.length / s.length);
    if (s.indexOf(p) !== -1)
        return 50 + (p.length / s.length);
    var pIdx = 0;
    var sIdx = 0;
    while (sIdx < s.length && pIdx < p.length) {
        if (s[sIdx] === p[pIdx])
            pIdx++;
        sIdx++;
    }
    if (pIdx === p.length)
        return 10 + (p.length / s.length);
    return 0;
}

function ensureItemRankCache(item) {
    if (!item || item._rankCacheReady)
        return;
    item._nameLower = item.name ? String(item.name).toLowerCase() : "";
    item._titleLower = item.title ? String(item.title).toLowerCase() : "";
    item._execLower = item.exec ? String(item.exec).toLowerCase() : (item.class ? String(item.class).toLowerCase() : "");
    item._bodyLower = [item.body, item.description, item.fullPath].filter(Boolean).join(" ").toLowerCase();
    item._relativePathLower = item.relativePath ? String(item.relativePath).toLowerCase() : "";
    item._parentPathLower = item.parentPath ? String(item.parentPath).toLowerCase() : "";
    item._displayPathLower = item.displayPath ? String(item.displayPath).toLowerCase() : "";
    item._extensionLower = item.extension ? String(item.extension).toLowerCase() : "";
    item._pathDepth = Number(item.pathDepth || 0);
    var category = item.category ? String(item.category).toLowerCase() : "";
    var keywords = item.keywords ? String(item.keywords).toLowerCase() : "";
    var tokens = [];
    var rawTokens = category.split(/[\s;,/|]+/);
    for (var i = 0; i < rawTokens.length; ++i) {
        var token = String(rawTokens[i] || "").trim();
        if (token === "")
            continue;
        if (tokens.indexOf(token) === -1)
            tokens.push(token);
    }
    item._categoryTokens = tokens;
    item._primaryCategoryKey = tokens.length > 0 ? tokens[0] : "";
    item._categoryKeywordsLower = (category + " " + keywords).trim();
    item._rankCacheReady = true;
}

function rankItem(item, clean, cleanLower, mode, weights) {
    if (clean === "")
        return 1;
    if (mode === "files")
        return rankFileItem(item, cleanLower);
    ensureItemRankCache(item);
    var categoryScore = mode === "drun" ? (fuzzyMatchLower(item._categoryKeywordsLower, cleanLower) * weights.category) : 0;
    var bestScore = Math.max(fuzzyMatchLower(item._nameLower, cleanLower) * weights.name, fuzzyMatchLower(item._titleLower, cleanLower) * weights.title, fuzzyMatchLower(item._execLower, cleanLower) * weights.exec, fuzzyMatchLower(item._bodyLower, cleanLower) * weights.body, categoryScore);
    if (mode === "drun")
        bestScore += Number(item._drunUsageBoost || 0);
    return bestScore;
}

function rankFileItem(item, cleanLower) {
    ensureItemRankCache(item);
    // Fast reject: skip expensive fuzzy scoring when first query char absent
    if (cleanLower !== ""
        && item._relativePathLower.indexOf(cleanLower[0]) === -1
        && item._extensionLower.indexOf(cleanLower[0]) === -1)
        return 0;
    var exactName = item._nameLower === cleanLower;
    var namePrefix = cleanLower !== "" && item._nameLower.startsWith(cleanLower);
    var relPrefix = cleanLower !== "" && item._relativePathLower.startsWith(cleanLower);
    var parentPrefix = cleanLower !== "" && item._parentPathLower.startsWith(cleanLower);
    var bestScore = Math.max(fuzzyMatchLower(item._nameLower, cleanLower) * 2.2, fuzzyMatchLower(item._relativePathLower, cleanLower) * 1.2, fuzzyMatchLower(item._parentPathLower, cleanLower) * 0.75, fuzzyMatchLower(item._titleLower, cleanLower) * 0.65, fuzzyMatchLower(item._extensionLower, cleanLower) * 0.35);
    if (exactName)
        bestScore += 220;
    else if (namePrefix)
        bestScore += 160;
    else if (relPrefix)
        bestScore += 90;
    else if (parentPrefix)
        bestScore += 30;
    bestScore -= Math.min(20, item._pathDepth * 2);
    bestScore -= Math.min(16, Math.floor(item._relativePathLower.length / 24));
    return bestScore;
}

// Safe arithmetic evaluator — handles +, -, *, /, parentheses, decimals.
// Replaces eval() for calculator mode to eliminate code injection surface.
function safeCalcEval(expr) {
    var s = expr.replace(/[^-+/*() .0-9]/g, "").replace(/\s+/g, "");
    if (s === "")
        return NaN;
    var pos = 0;
    function peek() { return pos < s.length ? s[pos] : ""; }
    function advance() { return s[pos++]; }
    function parseNumber() {
        var start = pos;
        if (peek() === "-") advance();
        while (pos < s.length && ((s[pos] >= "0" && s[pos] <= "9") || s[pos] === ".")) pos++;
        return pos > start ? parseFloat(s.substring(start, pos)) : NaN;
    }
    function parseFactor() {
        if (peek() === "(") { advance(); var v = parseExpr(); if (peek() === ")") advance(); return v; }
        if (peek() === "-" && (pos === 0 || s[pos - 1] === "(" || s[pos - 1] === "+" || s[pos - 1] === "-" || s[pos - 1] === "*" || s[pos - 1] === "/")) {
            advance(); return -parseFactor();
        }
        return parseNumber();
    }
    function parseTerm() {
        var v = parseFactor();
        while (peek() === "*" || peek() === "/") { var op = advance(); v = op === "*" ? v * parseFactor() : v / parseFactor(); }
        return v;
    }
    function parseExpr() {
        var v = parseTerm();
        while (peek() === "+" || peek() === "-") { var op = advance(); v = op === "+" ? v + parseTerm() : v - parseTerm(); }
        return v;
    }
    var result = parseExpr();
    return pos >= s.length ? result : NaN;
}

function compareLauncherItemsAlpha(a, b) {
    var aName = String(a && a.name ? a.name : "");
    var bName = String(b && b.name ? b.name : "");
    var byName = aName.localeCompare(bName);
    if (byName !== 0)
        return byName;
    var aExec = String(a && a.exec ? a.exec : "");
    var bExec = String(b && b.exec ? b.exec : "");
    var byExec = aExec.localeCompare(bExec);
    if (byExec !== 0)
        return byExec;
    var aTitle = String(a && a.title ? a.title : "");
    var bTitle = String(b && b.title ? b.title : "");
    return aTitle.localeCompare(bTitle);
}

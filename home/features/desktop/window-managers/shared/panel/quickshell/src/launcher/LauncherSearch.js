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
    // Fast reject: skip expensive walk when first query char is absent
    if (s.indexOf(p[0]) === -1)
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

function stripCharacterTrigger(searchText, trigger) {
    var value = String(searchText || "");
    var activeTrigger = String(trigger || ":");
    if (activeTrigger !== "" && value.startsWith(activeTrigger))
        return value.substring(activeTrigger.length).trim();
    if (value.startsWith(":"))
        return value.substring(1).trim();
    return value;
}

function tokenizeLower(text) {
    return String(text || "").toLowerCase().split(/\s+/).filter(function(token) {
        return token !== "";
    });
}

function ensureItemRankCache(item) {
    if (!item || item._rankCacheReady)
        return;
    item._nameLower = item.name ? String(item.name).toLowerCase() : "";
    item._titleLower = item.title ? String(item.title).toLowerCase() : "";
    item._execLower = item.exec ? String(item.exec).toLowerCase() : (item.class ? String(item.class).toLowerCase() : "");
    item._bodyLower = [item.body, item.description, item.fullPath].filter(Boolean).join(" ").toLowerCase();
    item._keywordsLower = Array.isArray(item.keywords) ? item.keywords.map(function (keyword) {
        return String(keyword || "").toLowerCase();
    }) : [];
    item._aliasesLower = Array.isArray(item.aliases) ? item.aliases.map(function (alias) {
        return String(alias || "").toLowerCase();
    }) : [];
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
    if (mode === "emoji")
        return rankCharacterItem(item, clean, cleanLower);
    if (mode === "files")
        return rankFileItem(item, cleanLower);
    ensureItemRankCache(item);
    // Fast path: strong name match skips other field scoring
    var nameScore = fuzzyMatchLower(item._nameLower, cleanLower);
    if (nameScore >= 100) {
        var fast = nameScore * weights.name;
        if (mode === "drun")
            fast += Number(item._drunUsageBoost || 0);
        return fast;
    }
    var categoryScore = mode === "drun" ? (fuzzyMatchLower(item._categoryKeywordsLower, cleanLower) * weights.category) : 0;
    var bestScore = Math.max(nameScore * weights.name, fuzzyMatchLower(item._titleLower, cleanLower) * weights.title, fuzzyMatchLower(item._execLower, cleanLower) * weights.exec, fuzzyMatchLower(item._bodyLower, cleanLower) * weights.body, categoryScore);
    if (mode === "drun")
        bestScore += Number(item._drunUsageBoost || 0);
    return bestScore;
}

function characterTokenScore(item, token) {
    if (token === "")
        return 0;
    if (item._nameLower === token)
        return 5200;
    if (item._titleLower === token)
        return 5000;
    if (item._nameLower.indexOf(token) !== -1)
        return 3200;
    for (var i = 0; i < item._keywordsLower.length; ++i) {
        var keyword = item._keywordsLower[i];
        if (keyword === token)
            return 4600 - Math.min(400, i * 20);
        if (keyword.startsWith(token))
            return 3600 - Math.min(300, i * 15);
        if (keyword.indexOf(token) !== -1)
            return 2800 - Math.min(250, i * 10);
    }
    for (var j = 0; j < item._aliasesLower.length; ++j) {
        var alias = item._aliasesLower[j];
        if (alias === token)
            return 4400 - Math.min(300, j * 15);
        if (alias.startsWith(token))
            return 3400 - Math.min(200, j * 10);
        if (alias.indexOf(token) !== -1)
            return 2600 - Math.min(160, j * 8);
    }
    if (item._titleLower.startsWith(token))
        return 3000;
    if (item._titleLower.indexOf(token) !== -1)
        return 2400;
    var fuzzy = Math.max(
        fuzzyMatchLower(item._titleLower, token),
        fuzzyMatchLower(item._categoryKeywordsLower, token)
    );
    if (fuzzy > 0)
        return Math.round(fuzzy * 30);
    return 0;
}

function rankCharacterItem(item, clean, cleanLower) {
    ensureItemRankCache(item);
    var tokens = tokenizeLower(cleanLower);
    if (tokens.length === 0)
        return 1;
    var total = 0;
    for (var i = 0; i < tokens.length; ++i) {
        var tokenScore = characterTokenScore(item, tokens[i]);
        if (tokenScore <= 0)
            return 0;
        total += tokenScore;
    }
    if (item._nameLower === cleanLower)
        total += 2400;
    if (item._titleLower === cleanLower)
        total += 1800;
    if (tokens.length > 1)
        total += 200;
    return total;
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

// Sort comparator: score desc → usage desc → alpha. Used for drun/general modes.
function compareByScoreThenUsage(a, b) {
    if (b._score !== a._score)
        return b._score - a._score;
    var usageDelta = Number(b._usageScore || 0) - Number(a._usageScore || 0);
    if (Math.abs(usageDelta) > 0.01)
        return usageDelta > 0 ? 1 : -1;
    return compareLauncherItemsAlpha(a, b);
}

// Sort comparator: score desc → pathDepth asc → path alpha. Used for files mode.
function compareByScoreThenDepth(a, b) {
    if (b._score !== a._score)
        return b._score - a._score;
    var aDepth = Number(a.pathDepth || 0);
    var bDepth = Number(b.pathDepth || 0);
    if (aDepth !== bDepth)
        return aDepth - bDepth;
    var aPath = a.relativePath || a.fullPath || a.title || "";
    var bPath = b.relativePath || b.fullPath || b.title || "";
    return aPath < bPath ? -1 : aPath > bPath ? 1 : 0;
}

// Sort comparator: score desc only. Used for ai/partial results.
function compareByScoreOnly(a, b) {
    if (b._score !== a._score)
        return b._score - a._score;
    return 0;
}

// Strip mode-specific prefix character from search text.
// Web mode is handled separately by the caller (parseWebQuery).
function stripSearchPrefix(mode, searchText) {
    if (mode === "run" && searchText.startsWith(">"))
        return searchText.substring(1).trim();
    if (mode === "emoji" && searchText.startsWith(":"))
        return searchText.substring(1).trim();
    if (mode === "ai" && searchText.startsWith("!"))
        return searchText.substring(1).trim();
    if (mode === "files" && searchText.startsWith("/"))
        return searchText.substring(1).trim();
    if (mode === "bookmarks" && searchText.startsWith("@"))
        return searchText.substring(1).trim();
    if (mode === "settings" && searchText.startsWith(","))
        return searchText.substring(1).trim();
    if (mode === "ssh" && searchText.startsWith(";"))
        return searchText.substring(1).trim();
    return searchText;
}

function compareLauncherItemsAlpha(a, b) {
    var aName = String(a && a.name ? a.name : "");
    var bName = String(b && b.name ? b.name : "");
    if (aName < bName) return -1;
    if (aName > bName) return 1;
    var aExec = String(a && a.exec ? a.exec : "");
    var bExec = String(b && b.exec ? b.exec : "");
    if (aExec < bExec) return -1;
    if (aExec > bExec) return 1;
    var aTitle = String(a && a.title ? a.title : "");
    var bTitle = String(b && b.title ? b.title : "");
    if (aTitle < bTitle) return -1;
    if (aTitle > bTitle) return 1;
    return 0;
}

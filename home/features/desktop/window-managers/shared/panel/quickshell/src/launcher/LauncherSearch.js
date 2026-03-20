.pragma library

function highlightMatch(fullText, query, stripPrefixFn, multiToken) {
    if (!query || !fullText)
        return fullText;

    var cleanQuery = stripPrefixFn ? stripPrefixFn(query) : query;
    if (!cleanQuery || cleanQuery.trim() === "")
        return fullText;

    // Multi-token mode: highlight each space-separated token independently
    if (multiToken && cleanQuery.indexOf(" ") !== -1) {
        var tokens = cleanQuery.toLowerCase().split(/\s+/).filter(function(t) { return t !== ""; });
        if (tokens.length === 0) return fullText;
        // Build a set of character positions to highlight
        var highlights = {};
        var t = fullText.toLowerCase();
        for (var ti = 0; ti < tokens.length; ti++) {
            var rawTok = tokens[ti];
            // Skip negate tokens — excluded items won't appear anyway
            if (rawTok[0] === "!") continue;
            // Strip operator prefixes for highlighting
            var hlTok = rawTok;
            if (hlTok[0] === "'" || hlTok[0] === "^") hlTok = hlTok.substring(1);
            if (hlTok.length > 0 && hlTok[hlTok.length - 1] === "$") hlTok = hlTok.substring(0, hlTok.length - 1);
            if (hlTok === "") continue;
            _markTokenPositions(t, hlTok, highlights);
        }
        return _buildHighlightedString(fullText, highlights);
    }

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

// Mark character positions for a single token (substring or fuzzy)
function _markTokenPositions(textLower, token, positions) {
    // Try substring first
    var subIdx = textLower.indexOf(token);
    if (subIdx !== -1) {
        for (var i = subIdx; i < subIdx + token.length; i++)
            positions[i] = true;
        return;
    }
    // Fuzzy: mark matched characters
    var tIdx = 0;
    for (var sIdx = 0; sIdx < textLower.length && tIdx < token.length; sIdx++) {
        if (textLower[sIdx] === token[tIdx]) {
            positions[sIdx] = true;
            tIdx++;
        }
    }
}

// Build highlighted string from position set
function _buildHighlightedString(fullText, positions) {
    var result = "";
    var inBold = false;
    for (var i = 0; i < fullText.length; i++) {
        if (positions[i]) {
            if (!inBold) { result += "<b>"; inBold = true; }
            result += fullText[i];
        } else {
            if (inBold) { result += "</b>"; inBold = false; }
            result += fullText[i];
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
    item._nameOriginal = item.name ? String(item.name) : "";
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
    item._relativePathOriginal = item.relativePath ? String(item.relativePath) : "";
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

// fzf-style single-token scoring against a string.
// Returns 0 for no match, higher = better match quality.
// Rewards: consecutive runs, word boundary matches, start-of-string.
// Optional strOriginal (original case) enables camelCase boundary detection.
function fzfScoreToken(str, token, strOriginal) {
    if (!token) return 100;
    if (!str) return 0;
    var sLen = str.length;
    var tLen = token.length;
    if (tLen > sLen) return 0;

    // Exact match
    if (str === token) return 2000 + 100;

    // Substring match — score by position and length
    var subIdx = str.indexOf(token);
    if (subIdx !== -1) {
        var score = 800;
        // Bonus for match at start
        if (subIdx === 0) score += 200;
        // Bonus for match at word boundary (after / . _ - space or camelCase)
        else if (_isWordBoundary(str, subIdx, strOriginal)) score += 150;
        // Coverage bonus: longer match relative to string
        score += Math.round((tLen / sLen) * 100);
        return score;
    }

    // Fuzzy match — walk string matching chars, score consecutive runs and boundaries
    var tIdx = 0;
    var score = 0;
    var consecutive = 0;
    var firstMatchIdx = -1;
    var lastMatchIdx = -1;
    var boundaryMatches = 0;

    for (var sIdx = 0; sIdx < sLen && tIdx < tLen; sIdx++) {
        if (str[sIdx] === token[tIdx]) {
            if (firstMatchIdx === -1) firstMatchIdx = sIdx;
            lastMatchIdx = sIdx;
            consecutive++;
            // Consecutive run bonus: 1+2+3+4... = n*(n+1)/2 growth
            score += consecutive * 3;
            // Word boundary bonus (includes camelCase)
            if (_isWordBoundary(str, sIdx, strOriginal)) {
                boundaryMatches++;
                score += 20;
            }
            // Start-of-string bonus
            if (sIdx === 0) score += 30;
            tIdx++;
        } else {
            consecutive = 0;
        }
    }

    if (tIdx < tLen) return 0; // Not all chars matched

    // Base score for completing the match
    score += 50;
    // Coverage: how compact is the match span?
    var span = lastMatchIdx - firstMatchIdx + 1;
    score += Math.max(0, Math.round((tLen / span) * 60));
    // Penalize very sparse matches
    if (span > tLen * 4) score -= 20;
    return score;
}

// Check if position i in str is a word boundary start.
// Optional strOriginal (original case) enables camelCase boundary detection.
function _isWordBoundary(str, i, strOriginal) {
    if (i === 0) return true;
    var prev = str.charCodeAt(i - 1);
    // After / . _ - space
    if (prev === 47 || prev === 46 || prev === 95 || prev === 45 || prev === 32)
        return true;
    // camelCase: lowercase→uppercase transition in original-case string
    if (strOriginal && i < strOriginal.length) {
        var origPrev = strOriginal.charCodeAt(i - 1);
        var origCurr = strOriginal.charCodeAt(i);
        if (origPrev >= 97 && origPrev <= 122 && origCurr >= 65 && origCurr <= 90)
            return true;
    }
    return false;
}

// Parse a file-mode token into {text, mode} for operator dispatch.
// Operators: !term (negate), 'term (exact), ^term (prefix), term$ (suffix), plain (fuzzy).
function _parseFileToken(token) {
    if (!token) return { text: "", mode: "fuzzy" };
    if (token[0] === "!") return { text: token.substring(1), mode: "negate" };
    if (token[0] === "'") return { text: token.substring(1), mode: "exact" };
    if (token[0] === "^") return { text: token.substring(1), mode: "prefix" };
    if (token[token.length - 1] === "$") return { text: token.substring(0, token.length - 1), mode: "suffix" };
    return { text: token, mode: "fuzzy" };
}

// Score a single parsed file token against name/path strings.
// Returns: -1 if negate term found, 0 for no match, >0 for match quality.
function _scoreFileTokenOp(nameStr, pathStr, parsed, nameOrig, pathOrig) {
    var term = parsed.text;
    if (!term) return 1;
    if (parsed.mode === "negate") {
        return (nameStr.indexOf(term) !== -1 || pathStr.indexOf(term) !== -1) ? -1 : 1;
    }
    if (parsed.mode === "exact") {
        var nameIdx = nameStr.indexOf(term);
        if (nameIdx !== -1) return 800 + Math.round((term.length / nameStr.length) * 100);
        var pathIdx = pathStr.indexOf(term);
        if (pathIdx !== -1) return 600 + Math.round((term.length / pathStr.length) * 100);
        return 0;
    }
    if (parsed.mode === "prefix") {
        if (nameStr.indexOf(term) === 0) return 1000;
        if (pathStr.indexOf(term) === 0) return 800;
        return 0;
    }
    if (parsed.mode === "suffix") {
        var nameEnd = nameStr.length - term.length;
        if (nameEnd >= 0 && nameStr.indexOf(term, nameEnd) === nameEnd) return 1000;
        var pathEnd = pathStr.length - term.length;
        if (pathEnd >= 0 && pathStr.indexOf(term, pathEnd) === pathEnd) return 800;
        return 0;
    }
    // fuzzy: delegate to fzfScoreToken with name/path weights and camelCase originals
    var nameScore = fzfScoreToken(nameStr, term, nameOrig) * 2.5;
    var pathScore = fzfScoreToken(pathStr, term, pathOrig) * 1.2;
    return Math.max(nameScore, pathScore);
}

function rankFileItem(item, cleanLower) {
    ensureItemRankCache(item);
    if (cleanLower === "") return 1;

    // Multi-token: split on spaces, require ALL tokens match (fzf AND semantics)
    var tokens = cleanLower.indexOf(" ") === -1 ? [cleanLower] : cleanLower.split(/\s+/).filter(function(t) { return t !== ""; });
    if (tokens.length === 0) return 1;

    // Fast reject on first char of each non-operator token
    for (var r = 0; r < tokens.length; r++) {
        var rt = tokens[r];
        if (rt[0] === "!" || rt[0] === "'") continue;
        var fc = (rt[0] === "^") ? (rt.length > 1 ? rt[1] : null) : rt[0];
        if (!fc) continue;
        // Also strip trailing $ for suffix tokens
        if (fc === "$") continue;
        if (item._relativePathLower.indexOf(fc) === -1
            && item._nameLower.indexOf(fc) === -1)
            return 0;
    }

    var minScore = Infinity;
    for (var t = 0; t < tokens.length; t++) {
        var parsed = _parseFileToken(tokens[t]);
        if (parsed.text === "") continue;
        var tokScore = _scoreFileTokenOp(
            item._nameLower, item._relativePathLower, parsed,
            item._nameOriginal, item._relativePathOriginal
        );
        if (parsed.mode === "negate") {
            if (tokScore < 0) return 0; // found — exclude
            continue; // absent — passes, no score contribution
        }
        if (tokScore <= 0) return 0; // AND: all must match
        if (tokScore < minScore) minScore = tokScore;
    }

    if (minScore === Infinity) minScore = 1; // all tokens were negate-only

    var score = minScore;
    // Multi-token bonus: reward queries that use multiple tokens
    if (tokens.length > 1) score += 50;
    // Depth penalty: prefer shallower files
    score -= Math.min(20, item._pathDepth * 2);
    // Length penalty: prefer shorter paths
    score -= Math.min(16, Math.floor(item._relativePathLower.length / 24));
    // Frecency boost from UsageTrackerService
    score += Number(item._fileUsageBoost || 0);
    // Git-tracked boost — enough to move a tracked file above an untracked peer
    if (item._isGitTracked) score += 50;
    return score;
}

function compareFileBrowseItems(a, b) {
    var aIsDir = String(a && a.fileKind || "") === "dir";
    var bIsDir = String(b && b.fileKind || "") === "dir";
    if (aIsDir !== bIsDir)
        return aIsDir ? -1 : 1;
    var usageDiff = Number(b && b._fileUsageBoost || 0) - Number(a && a._fileUsageBoost || 0);
    if (Math.abs(usageDiff) > 0.01)
        return usageDiff > 0 ? 1 : -1;
    var aPath = String(a && (a.relativePath || a.fullPath || a.name) || "");
    var bPath = String(b && (b.relativePath || b.fullPath || b.name) || "");
    return aPath < bPath ? -1 : aPath > bPath ? 1 : 0;
}

function browseFileItems(items, limit) {
    var source = Array.isArray(items) ? items : [];
    var results = [];
    var numericLimit = Number(limit);
    var max = isNaN(numericLimit) ? source.length : Math.max(1, numericLimit);
    for (var i = 0; i < source.length; ++i) {
        var item = source[i];
        if (!item || Number(item.pathDepth || 0) !== 0)
            continue;
        item._score = Number(item._fileUsageBoost || 0);
        results.push(item);
    }
    results.sort(compareFileBrowseItems);
    if (results.length > max)
        results.length = max;
    return results;
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

// Sort comparator: score desc → usage desc → pathDepth asc → path alpha. Used for files mode.
function compareByScoreThenDepth(a, b) {
    if (b._score !== a._score)
        return b._score - a._score;
    var usageDiff = Number(b._fileUsageBoost || 0) - Number(a._fileUsageBoost || 0);
    if (Math.abs(usageDiff) > 0.01) return usageDiff > 0 ? 1 : -1;
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

// ── Selection / navigation pure helpers ─────────────────────────────────────
// Each returns the new selectedIndex. Callers assign the result.

function cycleSelection(count, selectedIndex, step) {
    if (count <= 0) return selectedIndex;
    return (selectedIndex + step + count) % count;
}

function moveSelectionRelative(count, selectedIndex, step) {
    if (count <= 0) return selectedIndex;
    return Math.max(0, Math.min(count - 1, selectedIndex + step));
}

function jumpSelectionBoundary(count, toEnd) {
    if (count <= 0) return 0;
    return toEnd ? (count - 1) : 0;
}

// hudHeight is the pixel height of the results list, used to compute page size.
function pageSelection(count, selectedIndex, step, hudHeight) {
    if (count <= 0) return selectedIndex;
    var pageSize = Math.max(5, Math.min(12, Math.round(hudHeight / 72)));
    return Math.max(0, Math.min(count - 1, selectedIndex + (step * pageSize)));
}

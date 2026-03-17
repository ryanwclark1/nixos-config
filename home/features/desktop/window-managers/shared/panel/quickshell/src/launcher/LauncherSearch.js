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

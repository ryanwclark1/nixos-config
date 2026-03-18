.pragma library

// Pure file-path parsing utilities extracted from Launcher.qml.
// No QML property access — all state passed via arguments.

function _buildFileItem(path, homeDir, homePrefix) {
    var fullPath = path.charCodeAt(0) === 47 ? path : (homeDir + "/" + path);
    var relativePath = fullPath.indexOf(homePrefix) === 0 ? fullPath.substring(homePrefix.length) : fullPath;
    var slash = relativePath.lastIndexOf("/");
    var name = slash >= 0 ? relativePath.substring(slash + 1) : relativePath;
    if (name === "")
        name = path;
    var parentPath = slash >= 0 ? relativePath.substring(0, slash) : "";
    var displayPath = parentPath !== "" ? ("~/" + parentPath) : "~";
    var extension = "";
    var extIndex = name.lastIndexOf(".");
    if (extIndex > 0 && extIndex < (name.length - 1))
        extension = name.substring(extIndex + 1);
    var pathDepth = parentPath === "" ? 0 : parentPath.split("/").length;
    return {
        name: name,
        title: fullPath,
        fullPath: fullPath,
        relativePath: relativePath,
        parentPath: parentPath,
        displayPath: displayPath,
        extension: extension,
        pathDepth: pathDepth
    };
}

function buildFileItemsFromRaw(raw, homeDir) {
    var lines = raw ? raw.split("\n") : [];
    var items = new Array(lines.length);
    var count = 0;
    var homePrefix = homeDir.endsWith("/") ? homeDir : (homeDir + "/");
    for (var i = 0; i < lines.length; ++i) {
        var path = String(lines[i] || "");
        if (path === "")
            continue;
        items[count] = _buildFileItem(path, homeDir, homePrefix);
        count += 1;
    }
    if (count < items.length)
        items.length = count;
    return items;
}

// Process a chunk of lines from a chunked parse state.
// Returns { done: bool, state: state }.
// The caller (QML) handles timer restart and callback invocation.
function processParseChunk(state, chunkSize) {
    var end = Math.min(state.idx + chunkSize, state.lines.length);
    for (var i = state.idx; i < end; ++i) {
        var path = String(state.lines[i] || "");
        if (path === "")
            continue;
        state.items[state.count] = _buildFileItem(path, state.homeDir, state.homePrefix);
        state.count += 1;
    }
    state.idx = end;
    if (state.idx >= state.lines.length) {
        if (state.count < state.items.length)
            state.items.length = state.count;
        return { done: true, items: state.items };
    }
    return { done: false, items: null };
}

function fileQueryLooksLikePath(clean) {
    var normalized = String(clean || "").trim();
    return normalized.startsWith("/") || normalized.startsWith("~") || normalized.indexOf("/") !== -1;
}

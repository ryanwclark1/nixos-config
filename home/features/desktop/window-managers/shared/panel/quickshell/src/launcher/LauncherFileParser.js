.pragma library

// Pure file-path parsing utilities extracted from Launcher.qml.
// No QML property access — all state passed via arguments.

function iconForFile(name, extension, kind) {
    var loweredName = String(name || "").toLowerCase();
    var ext = String(extension || "").toLowerCase();
    var type = String(kind || "file").toLowerCase();
    if (type === "dir")
        return "󰉋";
    if (["png", "jpg", "jpeg", "gif", "webp", "svg", "avif", "bmp", "ico"].indexOf(ext) !== -1)
        return "󰈟";
    if (["pdf", "epub"].indexOf(ext) !== -1)
        return "󰈦";
    if (["doc", "docx", "odt", "rtf", "txt", "md"].indexOf(ext) !== -1)
        return ext === "md" ? "󰍔" : "󰈙";
    if (["xls", "xlsx", "ods", "csv", "tsv"].indexOf(ext) !== -1)
        return "󰈛";
    if (["ppt", "pptx", "odp", "key"].indexOf(ext) !== -1)
        return "󰈧";
    if (["zip", "tar", "gz", "xz", "bz2", "7z", "rar", "zst"].indexOf(ext) !== -1)
        return "󰗄";
    if (["mp3", "ogg", "flac", "wav", "m4a", "opus", "aac"].indexOf(ext) !== -1)
        return "󰎆";
    if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(ext) !== -1)
        return "󰈫";
    if (["nix", "js", "jsx", "ts", "tsx", "py", "rs", "go", "c", "cpp", "h", "hpp", "java", "lua", "qml", "sh", "bash", "zsh", "json", "yaml", "yml", "toml", "ini", "conf", "service", "desktop", "lock"].indexOf(ext) !== -1)
        return "󰅩";
    if (loweredName === "makefile" || loweredName === "dockerfile")
        return "󰅩";
    if (loweredName.startsWith(".env"))
        return "󰒓";
    return "󰈔";
}

function _buildFileItem(path, rootDir, rootPrefix, rootLabel) {
    var raw = String(path || "");
    var kind = "file";
    if (raw.length > 2 && raw.charAt(1) === "\t") {
        kind = raw.charAt(0) === "d" ? "dir" : "file";
        raw = raw.substring(2);
    }
    var fullPath = raw.charCodeAt(0) === 47 ? raw : (rootDir + "/" + raw);
    var relativePath = fullPath.indexOf(rootPrefix) === 0 ? fullPath.substring(rootPrefix.length) : fullPath;
    var slash = relativePath.lastIndexOf("/");
    var name = slash >= 0 ? relativePath.substring(slash + 1) : relativePath;
    if (name === "")
        name = raw;
    var parentPath = slash >= 0 ? relativePath.substring(0, slash) : "";
    var displayPath = parentPath !== "" ? (rootLabel + "/" + parentPath) : rootLabel;
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
        pathDepth: pathDepth,
        fileKind: kind,
        icon: iconForFile(name, extension, kind)
    };
}

function buildFileItemsFromRaw(raw, rootDir, rootLabel) {
    var lines = raw ? raw.split("\n") : [];
    var items = new Array(lines.length);
    var count = 0;
    var rootPrefix = rootDir.endsWith("/") ? rootDir : (rootDir + "/");
    var label = String(rootLabel || "~");
    for (var i = 0; i < lines.length; ++i) {
        var path = String(lines[i] || "");
        if (path === "")
            continue;
        items[count] = _buildFileItem(path, rootDir, rootPrefix, label);
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
        state.items[state.count] = _buildFileItem(path, state.rootDir, state.rootPrefix, state.rootLabel);
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

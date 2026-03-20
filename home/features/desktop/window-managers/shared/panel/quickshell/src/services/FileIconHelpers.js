.pragma library

function _has(ext, values) {
    return values.indexOf(ext) !== -1;
}

function iconForFile(name, extension, kind) {
    var loweredName = String(name || "").toLowerCase();
    var ext = String(extension || "").toLowerCase();
    var type = String(kind || "file").toLowerCase();
    if (type === "dir")
        return "folder.svg";
    if (_has(ext, ["png", "jpg", "jpeg", "gif", "webp", "svg", "avif", "bmp", "ico", "tiff"]))
        return "image.svg";
    if (_has(ext, ["pdf", "epub"]))
        return "document.svg";
    if (_has(ext, ["doc", "docx", "odt", "rtf"]))
        return "document-filled.svg";
    if (_has(ext, ["txt", "md", "rst", "log"]))
        return ext === "md" ? "scan-text.svg" : "text-t.svg";
    if (_has(ext, ["xls", "xlsx", "ods", "csv", "tsv"]))
        return "data-pie.svg";
    if (_has(ext, ["ppt", "pptx", "odp", "key"]))
        return "board.svg";
    if (_has(ext, ["zip", "tar", "gz", "xz", "bz2", "7z", "rar", "zst"]))
        return "archive.svg";
    if (_has(ext, ["mp3", "ogg", "flac", "wav", "m4a", "opus", "aac"]))
        return "music-note-2.svg";
    if (_has(ext, ["mp4", "mkv", "webm", "mov", "avi", "flv"]))
        return "video.svg";
    if (_has(ext, ["nix"]))
        return "brands/nixos-symbolic.svg";
    if (_has(ext, ["sh", "bash", "zsh", "fish", "js", "jsx", "ts", "tsx", "py", "rs", "go", "c", "cpp", "h", "hpp", "java", "lua", "qml", "json", "yaml", "yml", "toml", "ini", "conf", "service", "desktop", "lock", "xml", "html", "css", "scss"]))
        return "code.svg";
    if (loweredName === "makefile" || loweredName === "dockerfile")
        return "code.svg";
    if (loweredName.startsWith(".env"))
        return "shield-lock.svg";
    return "document.svg";
}

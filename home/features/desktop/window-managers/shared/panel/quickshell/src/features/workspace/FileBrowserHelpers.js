.pragma library

// ── Parsing ────────────────────────────────────────────────────────────────────

function parseStatOutput(raw) {
    var lines = raw.trim().split("\n");
    var entries = [];
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (!line.trim()) continue;
        var parts = line.split("\t");
        if (parts.length < 4) continue;
        var fullPath = parts[0];
        var typStr   = parts[1];
        var size     = parseInt(parts[2]) || 0;
        var mtime    = parseInt(parts[3]) || 0;

        var name = fullPath.replace(/\/$/, "").split("/").pop();
        if (!name || name === "." || name === "..") continue;

        var isDir = (typStr === "directory");
        var ext = isDir ? "" : (name.lastIndexOf(".") > 0 ? name.slice(name.lastIndexOf(".") + 1).toLowerCase() : "");
        var isImage = ["jpg","jpeg","png","webp","gif","bmp","svg","tiff","avif"].indexOf(ext) >= 0;

        entries.push({
            name: name,
            path: fullPath,
            isDir: isDir,
            size: size,
            mtime: mtime,
            extension: ext,
            isImage: isImage
        });
    }
    return entries;
}

// ── Sorting ────────────────────────────────────────────────────────────────────

function sortEntries(entries, sortBy, sortAsc) {
    var dirs  = entries.filter(function(e) { return e.isDir; });
    var files = entries.filter(function(e) { return !e.isDir; });

    function cmp(a, b) {
        var av, bv;
        if (sortBy === "name") {
            av = a.name.toLowerCase(); bv = b.name.toLowerCase();
        } else if (sortBy === "size") {
            av = a.size; bv = b.size;
        } else if (sortBy === "date") {
            av = a.mtime; bv = b.mtime;
        } else if (sortBy === "type") {
            av = a.extension.toLowerCase(); bv = b.extension.toLowerCase();
        } else {
            av = a.name.toLowerCase(); bv = b.name.toLowerCase();
        }
        if (av < bv) return sortAsc ? -1 : 1;
        if (av > bv) return sortAsc ? 1 : -1;
        return 0;
    }

    dirs.sort(cmp);
    files.sort(cmp);
    return dirs.concat(files);
}

// ── Filtering ──────────────────────────────────────────────────────────────────

function applyFilters(entries, fileFilters, activeFilterIndex) {
    if (fileFilters.length === 0) return entries;
    var filter = fileFilters[activeFilterIndex];
    if (!filter || !filter.extensions || filter.extensions.length === 0) return entries;
    return entries.filter(function(e) {
        return e.isDir || filter.extensions.indexOf(e.extension) >= 0;
    });
}

// ── Breadcrumbs ────────────────────────────────────────────────────────────────

function buildBreadcrumbs(currentPath) {
    var parts = currentPath.replace(/\/+$/, "").split("/").filter(function(s) { return s.length > 0; });
    var crumbs = [{ label: "/", path: "/" }];
    var acc = "";
    for (var i = 0; i < parts.length; i++) {
        acc += "/" + parts[i];
        crumbs.push({ label: parts[i], path: acc });
    }
    return crumbs;
}

// ── Formatting ─────────────────────────────────────────────────────────────────

function formatSize(bytes) {
    if (bytes < 1024)       return bytes + " B";
    if (bytes < 1048576)    return (bytes / 1024).toFixed(1)       + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1)    + " MB";
    return                         (bytes / 1073741824).toFixed(1)  + " GB";
}

function formatDate(ts) {
    var d = new Date(ts * 1000);
    var y = d.getFullYear();
    var mo = ("0" + (d.getMonth() + 1)).slice(-2);
    var day = ("0" + d.getDate()).slice(-2);
    return y + "-" + mo + "-" + day;
}

// ── File icons ─────────────────────────────────────────────────────────────────

function fileIcon(entry) {
    if (entry.isDir) return "󰉋";
    var ext = entry.extension;
    if (["jpg","jpeg","png","webp","gif","bmp","svg","tiff","avif"].indexOf(ext) >= 0) return "󰋩";
    if (["mp4","mkv","mov","avi","webm","flv"].indexOf(ext) >= 0) return "󰈫";
    if (["mp3","flac","wav","ogg","aac","opus"].indexOf(ext) >= 0) return "󰝚";
    if (["pdf"].indexOf(ext) >= 0) return "󰈦";
    if (["zip","tar","gz","bz2","xz","7z","rar","zst"].indexOf(ext) >= 0) return "󰗄";
    if (["sh","bash","zsh","fish"].indexOf(ext) >= 0) return "󰆍";
    if (["js","ts","jsx","tsx","py","rs","go","c","cpp","h","java","rb","cs"].indexOf(ext) >= 0) return "󰴭";
    if (["txt","md","rst","log"].indexOf(ext) >= 0) return "󰈙";
    if (["json","yaml","yml","toml","xml","ini","conf"].indexOf(ext) >= 0) return "󰘦";
    if (["nix"].indexOf(ext) >= 0) return "󱄅";
    if (["html","css","scss"].indexOf(ext) >= 0) return "󰌒";
    return "󰈔";
}

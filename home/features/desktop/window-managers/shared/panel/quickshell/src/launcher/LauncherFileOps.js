.pragma library

// File operation helpers extracted from Launcher.qml.
//
// All functions take a `ctx` dependency object with:
//   ctx.fileOpenerCommand    — string, configured opener command
//   ctx.fileSearchRootResolved — string, resolved search root path
//   ctx.execDetached(args)   — fn, execute command detached
//   ctx.showTransientNotice(msg, durationMs) — fn
//   ctx.copyToClipboard(text) — fn
//   ctx.close()              — fn, close the launcher

function openWithConfiguredOpener(targetPath, ctx) {
    var target = String(targetPath || "");
    if (target === "")
        return;
    ctx.execDetached(["sh", "-c", "exec " + ctx.fileOpenerCommand + " \"$1\"", "sh", target]);
}

function openDirectoryPath(targetPath, ctx) {
    openWithConfiguredOpener(targetPath, ctx);
}

function openFileItem(item, ctx) {
    if (!item || !item.fullPath)
        return;
    openWithConfiguredOpener(item.fullPath, ctx);
}

function fileItemParentPath(item, fileSearchRootResolved) {
    if (!item || !item.fullPath)
        return fileSearchRootResolved;
    var fullPath = String(item.fullPath || "");
    var slash = fullPath.lastIndexOf("/");
    if (slash <= 0)
        return fileSearchRootResolved;
    return fullPath.substring(0, slash);
}

function openFileParent(item, ctx) {
    openDirectoryPath(fileItemParentPath(item, ctx.fileSearchRootResolved), ctx);
    if (item && item.fullPath)
        ctx.showTransientNotice("Opened parent folder for " + String(item.name || item.fullPath), 2200);
}

function revealFileInManager(item, ctx) {
    if (!item || !item.fullPath)
        return;
    var target = String(item.fullPath || "");
    var parent = fileItemParentPath(item, ctx.fileSearchRootResolved);
    ctx.execDetached(["sh", "-c",
        "target=\"$1\"; parent=\"$2\"; " +
        "if command -v dbus-send >/dev/null 2>&1; then " +
        "  uri=$(printf 'file://%s' \"$target\" | sed 's/ /%20/g'); " +
        "  if dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call --print-reply " +
        "    /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:\"$uri\" string:\"\" >/dev/null 2>&1; then exit 0; fi; " +
        "fi; " +
        "exec " + ctx.fileOpenerCommand + " \"$parent\"",
        "sh", target, parent
    ]);
    ctx.showTransientNotice("Revealed " + String(item.name || target), 2200);
}

function copyFilePath(item, ctx) {
    if (!item || !item.fullPath)
        return;
    ctx.copyToClipboard(String(item.fullPath || ""));
    ctx.showTransientNotice("Copied path for " + String(item.name || item.fullPath), 2200);
}

function fileContextMenuModel(item, ctx) {
    if (!item || !item.fullPath)
        return [];
    return [
        { label: "Open",                  icon: "󰈔", action: function() { openFileItem(item, ctx); ctx.close(); } },
        { label: "Open Parent Folder",    icon: "󰉋", action: function() { openFileParent(item, ctx); ctx.close(); } },
        { label: "Reveal in File Manager",icon: "󰙅", action: function() { revealFileInManager(item, ctx); ctx.close(); } },
        { separator: true },
        { label: "Copy Full Path",        icon: "󰅍", action: function() { copyFilePath(item, ctx); } }
    ];
}

// ── Git index helpers ────────────────────────────────────────────────────────

// Parse raw git ls-files output into a set object { relativePath: true }.
function parseGitIndex(raw) {
    var set = {};
    if (raw) {
        var lines = raw.split("\n");
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i];
            if (line !== "") set[line] = true;
        }
    }
    return set;
}

// Tag file items with _isGitTracked using the provided set.
function tagFileItemsGit(items, gitTrackedSet) {
    var set = gitTrackedSet;
    for (var i = 0; i < items.length; ++i) {
        var rel = items[i].relativePath || "";
        items[i]._isGitTracked = (rel !== "" && set[rel] === true);
    }
}

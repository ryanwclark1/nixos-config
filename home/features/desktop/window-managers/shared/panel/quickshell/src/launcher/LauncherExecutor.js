.pragma library

// Mode-dispatch execution and label lookups extracted from Launcher.qml.
// QML-side capabilities are passed via an `actions` object to avoid direct QML coupling.

var _actionLabels = {
    clip: "Copy", emoji: "Copy", calc: "Copy", ai: "Copy",
    window: "Focus",
    files: "Open", web: "Open", bookmarks: "Open", wallpapers: "Open",
    drun: "Run", run: "Run",
    system: "Action", nixos: "Action", keybinds: "Action", media: "Action", plugins: "Action", settings: "Jump",
    ssh: "Connect"
};

function itemActionLabel(mode, item) {
    if (!item || item.isHint)
        return "";
    if (String(item.entryKind || "") === "destination")
        return "Open";
    if (String(item.entryKind || "") === "settings")
        return "Jump";
    return _actionLabels[mode] || "";
}

function itemProviderLabel(mode, item) {
    if (!item || item.isHint)
        return "";
    if (mode === "web")
        return item.name || "";
    if (mode === "bookmarks") {
        var raw = String(item.exec || "");
        var match = raw.match(/^https?:\/\/([^\/?#]+)/i);
        return match && match.length > 1 ? match[1] : "";
    }
    return "";
}

function buildRecentEntry(mode, item) {
    if (mode === "run") {
        return {
            name: item.name || item.exec,
            title: item.exec || "",
            icon: "󰆍",
            exec: item.exec || ""
        };
    }
    if (mode === "window") {
        return {
            name: item.name || item.title || "Window",
            title: item.title || item.appId || "",
            icon: item.icon || item.appId || "󰖯",
            appId: item.appId || "",
            id: item.address || item.id || "",
            openMode: "window"
        };
    }
    if (mode === "web" || mode === "bookmarks") {
        return {
            name: item.name || "Link",
            title: item.title || item.exec || "",
            icon: item.icon || "󰖟",
            exec: item.exec || ""
        };
    }
    if (mode === "files") {
        if (!item.isHint && item.fullPath) {
            return {
                name: item.name || item.fullPath,
                title: item.fullPath,
                icon: item.icon || "󰈔",
                fullPath: item.fullPath
            };
        }
        return null;
    }
    if (mode === "system" || mode === "nixos") {
        return {
            name: item.name || "Action",
            title: item.category || item.title || "",
            icon: item.icon || "󰒓",
            exec: item.exec || ""
        };
    }
    if (mode === "settings") {
        return {
            name: item.name || "Settings",
            title: item.breadcrumb || item.title || "",
            icon: item.icon || "󰒓",
            openMode: "settings"
        };
    }
    return null;
}

// Execute a selected item. `actions` provides QML-side capabilities:
//   trackLaunch, launchExecString, close, rememberRecent, copyToClipboard,
//   restoreClipboardHistoryItem, execDetached, dispatchAction,
//   executeLauncherItem, showingConfirm, searchText, modifiers,
//   selectCharacter, shouldPasteCharacter
function executeSelection(mode, item, actions) {
    var recent = buildRecentEntry(mode, item);
    if (recent)
        actions.rememberRecent(recent);

    if (mode === "drun") {
        actions.trackLaunch(item);
        actions.launchExecString(item.exec, item.terminal === "true" || item.terminal === "True");
        actions.close();
    } else if (mode === "run") {
        if (item.exec)
            actions.execDetached(["bash", "-c", item.exec]);
        actions.close();
    } else if (mode === "window") {
        if ((item.id || item.address) && actions.focusWindow)
            actions.focusWindow(item.id || item.address);
        else if (item.toplevel && item.toplevel.activate)
            item.toplevel.activate();
        actions.close();
    } else if (mode === "dmenu") {
        var fifoPath = "/tmp/qs-dmenu-result";
        actions.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "sh", item.name, fifoPath]);
        actions.close();
    } else if (mode === "emoji") {
        actions.selectCharacter(item.name, actions.shouldPasteCharacter(actions.modifiers));
    } else if (mode === "calc") {
        actions.copyToClipboard(item.name);
        actions.close();
    } else if (mode === "clip") {
        if (item.id) {
            actions.restoreClipboardHistoryItem(item.id);
            actions.close();
        }
    } else if (mode === "web" || mode === "bookmarks") {
        if (item.exec) {
            actions.execDetached(["xdg-open", item.exec + (item.query ? encodeURIComponent(item.query) : "")]);
            actions.close();
        }
    } else if (mode === "ai") {
        if (item.body) {
            actions.copyToClipboard(item.body);
            actions.close();
        }
    } else if (mode === "files") {
        if (!item.isHint && item.fullPath) {
            actions.openFileItem(item);
            if (actions.trackFileOpen) actions.trackFileOpen(item);
            actions.close();
        }
    } else if (mode === "system" || mode === "nixos") {
        if (item.ipcTarget && item.ipcAction)
            actions.execDetached(["quickshell", "ipc", "call", item.ipcTarget, item.ipcAction]);
        else if (item.action)
            item.action();
        if (!actions.showingConfirm)
            actions.close();
    } else if (mode === "settings") {
        if (item.action)
            item.action();
        if (!actions.showingConfirm)
            actions.close();
    } else if (mode === "wallpapers") {
        if (actions.setWallpaper) {
            actions.setWallpaper(item.path, "");
        } else {
            actions.execDetached(["swww", "img", item.path, "--transition-type", "grow", "--transition-pos", "0.5,0.5", "--transition-duration", "1.5"]);
        }
        actions.execDetached(["wallust", "run", item.path]);
        actions.close();
    } else if (mode === "keybinds") {
        if (item.disp && actions.supportsDispatcherActions)
            actions.dispatchAction(item.disp, item.args || "", "Trigger keybind action");
        actions.close();
    } else if (mode === "ssh") {
        if (item._hostRef)
            actions.connectSshHost(item._hostRef);
        else if (item._adHoc)
            actions.connectAdHocSsh(item._adHoc.user, item._adHoc.host, item._adHoc.port);
        actions.close();
    } else if (mode === "plugins") {
        var executed = actions.executeLauncherItem(item, actions.searchText);
        if (executed)
            actions.close();
    }
}

// Execute primary action when no results are available.
// actions: { open, close, loadAi, launchExecString, execDetached,
//            parseWebQuery, configuredWebProviderByKey, primaryWebProvider }
function executeEmptyPrimary(mode, clean, searchText, actions) {
    if (mode === "files") {
        actions.openDirectoryPath(actions.fileSearchRootResolved);
        actions.close();
        return;
    }
    if (mode === "web") {
        var webCtx = actions.parseWebQuery(searchText);
        var primary = actions.configuredWebProviderByKey(webCtx.providerKey) || actions.primaryWebProvider();
        var url = primary ? String(primary.home || "") : "";
        if (url === "")
            url = "https://duckduckgo.com/";
        if (webCtx.query !== "" && primary && primary.exec)
            url = String(primary.exec) + encodeURIComponent(webCtx.query);
        actions.execDetached(["xdg-open", url]);
        actions.close();
        return;
    }
    if (mode === "ai" && clean.length >= 3) {
        actions.loadAi();
        return;
    }
    if (mode === "settings") {
        if (actions.openSettings)
            actions.openSettings();
        actions.close();
        return;
    }
    if (mode === "run" && clean !== "") {
        actions.launchExecString(clean, false);
        actions.close();
        return;
    }
    if (mode === "ssh") {
        if (clean !== "" && actions.connectAdHocSsh) {
            var parsed = actions.parseAdHocTarget ? actions.parseAdHocTarget(clean) : null;
            if (parsed) {
                actions.connectAdHocSsh(parsed.user, parsed.host, parsed.port);
                actions.close();
                return;
            }
        }
        if (actions.openSshSettings) {
            actions.openSshSettings();
            actions.close();
        }
        return;
    }
    if (mode === "window") {
        if (actions.toggleOverview)
            actions.toggleOverview();
        actions.close();
        return;
    }
    if (mode === "bookmarks") {
        actions.open("web", true);
        return;
    }
    if (mode === "plugins") {
        actions.open("drun");
        return;
    }
    actions.open("drun");
}

// Execute secondary action when no results are available.
// actions: { close, clearSearchQuery, launchInTerminal, launchExecString,
//            runShellEntryAction, execDetached, secondaryWebProvider }
function executeEmptySecondary(mode, clean, actions) {
    if (mode === "files") {
        if (!_fileQueryLooksLikePath(clean)) {
            actions.clearSearchQuery();
            return;
        }
        var target = actions.fileSearchRootResolved;
        if (clean.startsWith("~")) {
            var homeRoot = actions.homeDir || actions.fileSearchRootResolved;
            target = homeRoot + clean.substring(1);
        } else if (clean.startsWith("/")) {
            target = clean;
        }
        actions.openDirectoryPath(target);
        actions.close();
        return;
    }
    if (mode === "web") {
        var secondary = actions.secondaryWebProvider();
        var secondaryUrl = secondary ? String(secondary.home || "") : "";
        if (secondaryUrl === "")
            secondaryUrl = "https://www.google.com/";
        if (clean !== "" && secondary && secondary.exec)
            secondaryUrl = String(secondary.exec) + encodeURIComponent(clean);
        actions.execDetached(["xdg-open", secondaryUrl]);
        actions.close();
        return;
    }
    if (mode === "system") {
        actions.runShellEntryAction("commandCenter");
        actions.close();
        return;
    }
    if (mode === "run") {
        if (clean !== "") {
            actions.launchExecString(clean, true);
        } else {
            actions.launchInTerminal("");
        }
        actions.close();
        return;
    }
    if (mode === "ssh") {
        if (actions.refreshSshImport)
            actions.refreshSshImport();
        return;
    }
    actions.clearSearchQuery();
}

// Internal helper — mirrors FileParser.fileQueryLooksLikePath but avoids cross-import
function _fileQueryLooksLikePath(clean) {
    var normalized = String(clean || "").trim();
    return normalized.startsWith("/") || normalized.startsWith("~") || normalized.indexOf("/") !== -1;
}

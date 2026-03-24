import QtQuick
import Quickshell
import Quickshell.Io
import "../features/launcher"
import "../launcher/LauncherDiagnostics.js" as Diag
import "../launcher/LauncherModeData.js" as ModeData
import "../services"

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var _pendingOpenRequest: null
    property string _pendingSearchText: ""
    property string _pendingDrunCategoryFilter: ""
    property real diagnosticViewportWidth: 0
    property real diagnosticViewportHeight: 0
    property string diagnosticFileSearchRootOverride: ""
    property bool diagnosticFileSearchShowHiddenOverrideActive: false
    property bool diagnosticFileSearchShowHiddenOverride: false
    property string diagnosticFileOpenerOverride: ""

    readonly property var launcherItem: launcherLoader.item || null
    readonly property bool launcherLoaded: launcherItem !== null
    readonly property string _pendingMode: {
        var pending = root._pendingOpenRequest;
        if (pending && pending.kind === "open")
            return pending.mode;
        if (pending && pending.kind === "dmenu")
            return "dmenu";
        return effectiveDefaultMode();
    }
    readonly property string fileSearchRootSetting: {
        var raw = String((diagnosticFileSearchRootOverride !== "" ? diagnosticFileSearchRootOverride : Config.launcherFileSearchRoot) || "~").trim();
        return raw !== "" ? raw : "~";
    }
    readonly property string fileSearchRootResolved: resolveFileSearchRoot(fileSearchRootSetting)
    readonly property string fileSearchRootLabel: formatFileSearchRootLabel(fileSearchRootResolved)
    readonly property bool fileSearchShowHidden: diagnosticFileSearchShowHiddenOverrideActive
        ? (diagnosticFileSearchShowHiddenOverride === true)
        : (Config.launcherFileShowHidden === true)
    readonly property string fileOpenerCommand: {
        var raw = String((diagnosticFileOpenerOverride !== "" ? diagnosticFileOpenerOverride : Config.launcherFileOpener) || "xdg-open").trim();
        return raw !== "" ? raw : "xdg-open";
    }
    readonly property bool showLauncherHome: Config.launcherShowHomeSections && _pendingSearchText === ""
        && (_pendingMode === "drun" || _pendingMode === "files")

    function isModeAllowedByCompositor(modeKey) {
        if (modeKey === "window" && !CompositorAdapter.supportsWindowListing)
            return false;
        if (modeKey === "keybinds" && !CompositorAdapter.supportsHotkeysListing)
            return false;
        return true;
    }

    function computeModeOrder() {
        var order = ModeData.sanitizeModeList(Config.launcherModeOrder, ModeData.defaultModeOrder, ModeData.allKnownModes);
        var enabled = ModeData.sanitizeModeList(Config.launcherEnabledModes, ModeData.defaultModeOrder, ModeData.allKnownModes);
        var enabledSet = ({});
        var filtered = [];
        var i;
        for (i = 0; i < enabled.length; ++i)
            enabledSet[enabled[i]] = true;
        for (i = 0; i < order.length; ++i) {
            var modeKey = order[i];
            if (enabledSet[modeKey] && isModeAllowedByCompositor(modeKey))
                filtered.push(modeKey);
        }
        return filtered.length > 0 ? filtered : ["drun"];
    }

    function supportsMode(modeKey) {
        if (ModeData.transientModes.indexOf(modeKey) !== -1)
            return true;
        return computeModeOrder().indexOf(modeKey) !== -1;
    }

    function effectiveDefaultMode() {
        if (supportsMode(Config.launcherDefaultMode))
            return Config.launcherDefaultMode;
        var order = computeModeOrder();
        return order.length > 0 ? order[0] : "drun";
    }

    function resolveFileSearchRoot(rawValue) {
        var raw = String(rawValue || "~").trim();
        var home = String(Quickshell.env("HOME") || "/");
        var resolved = home;
        if (raw === "" || raw === "~") {
            resolved = home;
        } else if (raw.indexOf("~/") === 0) {
            resolved = home + raw.substring(1);
        } else if (raw.charAt(0) === "/") {
            resolved = raw;
        } else {
            resolved = home + "/" + raw;
        }
        if (resolved.length > 1 && resolved.charAt(resolved.length - 1) === "/")
            resolved = resolved.substring(0, resolved.length - 1);
        return resolved;
    }

    function formatFileSearchRootLabel(rootPath) {
        var path = String(rootPath || "");
        var home = String(Quickshell.env("HOME") || "");
        if (path === home)
            return "~";
        if (home !== "" && path.indexOf(home + "/") === 0)
            return "~/" + path.substring(home.length + 1);
        return path !== "" ? path : "~";
    }

    function _ensureLauncherLoaded() {
        if (!launcherLoader.active)
            launcherLoader.active = true;
    }

    function _buildDmenuItems(items) {
        return items.map(function(it) {
            return {
                name: it,
                title: it
            };
        });
    }

    function _applyPendingSearchState() {
        if (!launcherItem)
            return;
        if (_pendingSearchText !== "") {
            launcherItem.diagnosticSetSearchText(_pendingSearchText);
            _pendingSearchText = "";
        }
        if (_pendingDrunCategoryFilter !== "") {
            launcherItem.diagnosticSetDrunCategoryFilter(_pendingDrunCategoryFilter);
            _pendingDrunCategoryFilter = "";
        }
    }

    function _performPendingOpen() {
        if (!launcherItem)
            return;
        var pending = _pendingOpenRequest;
        _pendingOpenRequest = null;
        if (!pending) {
            _applyPendingSearchState();
            return;
        }
        if (pending.kind === "dmenu") {
            launcherItem.mode = "dmenu";
            launcherItem.allItems = pending.items;
            launcherItem.open("dmenu");
        } else {
            launcherItem.open(pending.mode, pending.keepSearch);
        }
        _applyPendingSearchState();
    }

    function open(newMode, keepSearch) {
        var mode = newMode || effectiveDefaultMode();
        if (!supportsMode(mode))
            mode = effectiveDefaultMode();
        if (launcherItem) {
            launcherItem.open(mode, keepSearch);
            return;
        }
        _pendingOpenRequest = {
            kind: "open",
            mode: mode,
            keepSearch: keepSearch === true
        };
        _ensureLauncherLoaded();
    }

    function openDmenuItems(items) {
        var mappedItems = _buildDmenuItems(Array.isArray(items) ? items : []);
        if (launcherItem) {
            launcherItem.mode = "dmenu";
            launcherItem.allItems = mappedItems;
            launcherItem.open("dmenu");
            return;
        }
        _pendingOpenRequest = {
            kind: "dmenu",
            items: mappedItems
        };
        _ensureLauncherLoaded();
    }

    function close() {
        if (launcherItem) {
            launcherItem.close();
            return;
        }
        _pendingOpenRequest = null;
        if (launcherLoader.status !== Loader.Ready)
            launcherLoader.active = false;
    }

    function toggle() {
        if (launcherItem) {
            if (launcherItem.launcherOpacity > 0)
                launcherItem.close();
            else
                launcherItem.open(launcherItem.effectiveDefaultMode());
            return;
        }
        if (_pendingOpenRequest) {
            _pendingOpenRequest = null;
            if (launcherLoader.status !== Loader.Ready)
                launcherLoader.active = false;
            return;
        }
        open(effectiveDefaultMode(), false);
    }

    function clearMetrics() {
        if (launcherItem && launcherItem.clearMetrics)
            launcherItem.clearMetrics();
    }

    function redetectFilesBackend() {
        if (launcherItem && launcherItem.redetectFilesBackend)
            launcherItem.redetectFilesBackend();
    }

    function diagnosticReset() {
        diagnosticViewportWidth = 0;
        diagnosticViewportHeight = 0;
        diagnosticFileSearchRootOverride = "";
        diagnosticFileSearchShowHiddenOverrideActive = false;
        diagnosticFileSearchShowHiddenOverride = false;
        diagnosticFileOpenerOverride = "";
        _pendingSearchText = "";
        _pendingDrunCategoryFilter = "";
        if (launcherItem) {
            launcherItem.diagnosticReset();
            return;
        }
        _pendingOpenRequest = null;
    }

    function filesBackendStatusObject() {
        if (launcherItem)
            return launcherItem.filesBackendStatusObject();
        return Diag.filesBackendStatusObject({
            filesBackendLabel: "auto",
            fileSearchBackend: "",
            fileSearchBackendResolvedAt: 0,
            fileIndexReady: false,
            fileIndexBuilding: false,
            fileIndexItemsLength: 0,
            launcherMetrics: ({}),
            filesCacheStatsLabel: "0/0 (0%)",
            modeMetricFn: function() { return ({}); }
        });
    }

    function drunCategoryStateObject() {
        if (launcherItem)
            return launcherItem.drunCategoryStateObject();
        return Diag.drunCategoryStateObject({
            drunCategoryOptions: [{ key: "", label: "All", count: 0, hotkey: "0" }],
            drunCategoryFilter: _pendingDrunCategoryFilter,
            drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled,
            mode: _pendingMode,
            showLauncherHome: showLauncherHome,
            formatLabelFn: function(value) { return String(value || "All"); }
        });
    }

    function escapeActionStateObject() {
        if (launcherItem)
            return launcherItem.escapeActionStateObject();
        return Diag.escapeActionStateObject({
            showingConfirm: false,
            sidebarOverflowExpanded: false,
            shortcutHelpExpanded: false,
            searchText: _pendingSearchText,
            drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled,
            mode: _pendingMode,
            drunCategoryFilter: _pendingDrunCategoryFilter,
            drunCategorySectionExpanded: _pendingDrunCategoryFilter !== ""
        });
    }

    function launcherStateObject() {
        if (launcherItem)
            return launcherItem.launcherStateObject();
        var pending = _pendingOpenRequest;
        var pendingItems = pending && pending.kind === "dmenu" && Array.isArray(pending.items) ? pending.items : [];
        return Diag.launcherStateObject({
            launcherOpacity: 0,
            mode: _pendingMode,
            searchText: _pendingSearchText,
            fileSearchRootResolved: fileSearchRootResolved,
            fileSearchRootLabel: fileSearchRootLabel,
            fileSearchShowHidden: fileSearchShowHidden,
            fileOpenerCommand: fileOpenerCommand,
            showLauncherHome: showLauncherHome,
            sidebarOverflowExpanded: false,
            shortcutHelpExpanded: false,
            drunCategoryFilter: _pendingDrunCategoryFilter,
            drunCategorySectionExpanded: _pendingDrunCategoryFilter !== "",
            filteredItemsLength: pendingItems.length,
            modeLoadState: pending ? "loading" : "idle",
            modeLoadMessage: pending ? "Creating launcher" : "",
            allItemsLength: pendingItems.length,
            recentItemsLength: 0,
            suggestionItemsLength: 0,
            fileIndexReady: false,
            fileIndexBuilding: false,
            fileIndexItemsLength: 0,
            selectedIndex: 0,
            width: 0,
            height: 0,
            screenWidth: 0,
            screenHeight: 0,
            actualViewportWidth: 0,
            actualViewportHeight: 0,
            viewportWidth: diagnosticViewportWidth,
            viewportHeight: diagnosticViewportHeight,
            usableWidth: 0,
            usableHeight: 0,
            actualUsableWidth: 0,
            actualUsableHeight: 0,
            diagnosticViewportOffsetX: 0,
            diagnosticViewportOffsetY: 0,
            hudX: 0,
            hudY: 0,
            hudWidth: 0,
            hudHeight: 0,
            hudScale: 1.0,
            windowChromeHeight: 0,
            searchDeckHeight: 0,
            utilityBandHeight: 0,
            metricsHeight: 0,
            homeHeight: 0,
            resultsHeight: 0
        });
    }

    function diagnosticSetSearchText(text) {
        if (launcherItem)
            return launcherItem.diagnosticSetSearchText(text);
        _pendingSearchText = String(text || "");
        return JSON.stringify(escapeActionStateObject());
    }

    function diagnosticSetDrunCategoryFilter(categoryKey) {
        if (launcherItem)
            return launcherItem.diagnosticSetDrunCategoryFilter(categoryKey);
        _pendingDrunCategoryFilter = String(categoryKey || "");
        return JSON.stringify({
            changed: true,
            state: escapeActionStateObject()
        });
    }

    function diagnosticSetViewport(widthValue, heightValue) {
        diagnosticViewportWidth = Math.max(0, Number(widthValue || 0));
        diagnosticViewportHeight = Math.max(0, Number(heightValue || 0));
        if (launcherItem)
            return launcherItem.diagnosticSetViewport(widthValue, heightValue);
        return JSON.stringify(launcherStateObject());
    }

    function invokeEscapeAction() {
        if (launcherItem)
            return launcherItem.invokeEscapeAction();
        var action = escapeActionStateObject().action;
        var handled = false;
        if (_pendingSearchText !== "") {
            _pendingSearchText = "";
            handled = true;
        } else if (_pendingDrunCategoryFilter !== "") {
            _pendingDrunCategoryFilter = "";
            handled = true;
        } else if (_pendingOpenRequest) {
            _pendingOpenRequest = null;
            handled = true;
        }
        return JSON.stringify({
            handled: handled,
            action: action,
            state: escapeActionStateObject()
        });
    }

    Loader {
        id: launcherLoader
        active: false
        sourceComponent: launcherComponent
        onLoaded: root._performPendingOpen()
    }

    Component {
        id: launcherComponent
        Launcher {
            diagnosticViewportWidth: root.diagnosticViewportWidth
            diagnosticViewportHeight: root.diagnosticViewportHeight
            diagnosticFileSearchRootOverride: root.diagnosticFileSearchRootOverride
            diagnosticFileSearchShowHiddenOverrideActive: root.diagnosticFileSearchShowHiddenOverrideActive
            diagnosticFileSearchShowHiddenOverride: root.diagnosticFileSearchShowHiddenOverride
            diagnosticFileOpenerOverride: root.diagnosticFileOpenerOverride
        }
    }

    IpcHandler {
        target: "Launcher"

        function openDrun() {
            root.open("drun");
        }
        function openWindow() {
            root.open("window");
        }
        function openRun() {
            root.open("run");
        }
        function openEmoji() {
            root.open("emoji");
        }
        function openCalc() {
            root.open("calc");
        }
        function openClip() {
            root.open("clip");
        }
        function openWeb() {
            root.open("web");
        }
        function openPlugins() {
            root.open("plugins");
        }
        function openSystem() {
            root.open("system");
        }
        function openNixos() {
            root.open("nixos");
        }
        function openMedia() {
            root.open("media");
        }
        function openWallpapers() {
            root.open("wallpapers");
        }
        function openKeybinds() {
            root.open("keybinds");
        }
        function openBookmarks() {
            root.open("bookmarks");
        }
        function openAi() {
            root.open("ai");
        }
        function openFiles() {
            root.open("files");
        }
        function openDmenu(itemsJson: string) {
            var items = [];
            try {
                items = JSON.parse(itemsJson);
            } catch (err) {
                Logger.w("LauncherHost", "invalid dmenu itemsJson", err);
            }
            root.openDmenuItems(items);
        }
        function clearMetrics() {
            root.clearMetrics();
        }
        function redetectFilesBackend() {
            root.redetectFilesBackend();
        }
        function diagnosticReset() {
            root.diagnosticReset();
        }
        function filesBackendStatus(): string {
            return JSON.stringify(root.filesBackendStatusObject());
        }
        function drunCategoryState(): string {
            return JSON.stringify(root.drunCategoryStateObject());
        }
        function escapeActionState(): string {
            return JSON.stringify(root.escapeActionStateObject());
        }
        function launcherState(): string {
            return JSON.stringify(root.launcherStateObject());
        }
        function diagnosticSetSearchText(text: string): string {
            return root.diagnosticSetSearchText(text);
        }
        function diagnosticSetFileSearchRoot(rootValue: string): string {
            root.diagnosticFileSearchRootOverride = String(rootValue || "");
            return JSON.stringify(root.launcherStateObject());
        }
        function diagnosticSetFileShowHidden(value: string): string {
            var normalized = String(value || "").trim().toLowerCase();
            if (normalized === "" || normalized === "inherit") {
                root.diagnosticFileSearchShowHiddenOverrideActive = false;
            } else {
                root.diagnosticFileSearchShowHiddenOverrideActive = true;
                root.diagnosticFileSearchShowHiddenOverride = ["1", "true", "yes", "on"].indexOf(normalized) !== -1;
            }
            return JSON.stringify(root.launcherStateObject());
        }
        function diagnosticSetFileOpener(command: string): string {
            root.diagnosticFileOpenerOverride = String(command || "").trim();
            return JSON.stringify(root.launcherStateObject());
        }
        function diagnosticClearFileOverrides(): string {
            root.diagnosticFileSearchRootOverride = "";
            root.diagnosticFileSearchShowHiddenOverrideActive = false;
            root.diagnosticFileSearchShowHiddenOverride = false;
            root.diagnosticFileOpenerOverride = "";
            return JSON.stringify(root.launcherStateObject());
        }
        function diagnosticSetDrunCategoryFilter(categoryKey: string): string {
            return root.diagnosticSetDrunCategoryFilter(categoryKey);
        }
        function diagnosticSetViewport(widthValue: real, heightValue: real): string {
            return root.diagnosticSetViewport(widthValue, heightValue);
        }
        function diagnosticExecuteEmptyPrimary(): string {
            if (root.launcherItem)
                return root.launcherItem.diagnosticExecuteEmptyPrimary();
            return JSON.stringify({
                executed: false,
                state: root.launcherStateObject()
            });
        }
        function diagnosticExecuteSelection(): string {
            if (root.launcherItem)
                return root.launcherItem.diagnosticExecuteSelection();
            return JSON.stringify({
                executed: false,
                target: "",
                state: root.launcherStateObject()
            });
        }
        function invokeEscapeAction(): string {
            return root.invokeEscapeAction();
        }
        function toggle() {
            root.toggle();
        }
    }
}

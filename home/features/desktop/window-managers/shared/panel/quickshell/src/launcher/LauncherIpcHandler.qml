import Quickshell

IpcHandler {
    required property var launcher

    target: "Launcher"

    function openDrun() {
        launcher.open("drun");
    }
    function openWindow() {
        launcher.open("window");
    }
    function openRun() {
        launcher.open("run");
    }
    function openEmoji() {
        launcher.open("emoji");
    }
    function openCalc() {
        launcher.open("calc");
    }
    function openClip() {
        launcher.open("clip");
    }
    function openWeb() {
        launcher.open("web");
    }
    function openPlugins() {
        launcher.open("plugins");
    }
    function openSystem() {
        launcher.open("system");
    }
    function openNixos() {
        launcher.open("nixos");
    }
    function openMedia() {
        launcher.open("media");
    }
    function openWallpapers() {
        launcher.open("wallpapers");
    }
    function openKeybinds() {
        launcher.open("keybinds");
    }
    function openBookmarks() {
        launcher.open("bookmarks");
    }
    function openAi() {
        launcher.open("ai");
    }
    function openFiles() {
        launcher.open("files");
    }
    function openDmenu(itemsJson: string) {
        var items = [];
        try {
            items = JSON.parse(itemsJson);
        } catch (err) {}
        launcher.mode = "dmenu";
        launcher.allItems = items.map(function (it) {
            return {
                name: it,
                title: it
            };
        });
        launcher.open("dmenu");
    }
    function clearMetrics() {
        launcher.clearLauncherMetrics();
    }
    function redetectFilesBackend() {
        launcher.forceRedetectFileSearchBackend(true, function (_) {});
    }
    function diagnosticReset() {
        launcher.diagnosticReset();
    }
    function filesBackendStatus(): string {
        return JSON.stringify(launcher.filesBackendStatusObject());
    }
    function drunCategoryState(): string {
        return JSON.stringify(launcher.drunCategoryStateObject());
    }
    function escapeActionState(): string {
        return JSON.stringify(launcher.escapeActionStateObject());
    }
    function launcherState(): string {
        return JSON.stringify(launcher.launcherStateObject());
    }
    function diagnosticSetSearchText(text: string): string {
        return launcher.diagnosticSetSearchText(text);
    }
    function diagnosticSetFileSearchRoot(rootValue: string): string {
        launcher.diagnosticFileSearchRootOverride = String(rootValue || "");
        return JSON.stringify(launcher.launcherStateObject());
    }
    function diagnosticSetFileShowHidden(value: string): string {
        var normalized = String(value || "").trim().toLowerCase();
        if (normalized === "" || normalized === "inherit") {
            launcher.diagnosticFileSearchShowHiddenOverrideActive = false;
        } else {
            launcher.diagnosticFileSearchShowHiddenOverrideActive = true;
            launcher.diagnosticFileSearchShowHiddenOverride = ["1", "true", "yes", "on"].indexOf(normalized) !== -1;
        }
        return JSON.stringify(launcher.launcherStateObject());
    }
    function diagnosticSetFileOpener(command: string): string {
        launcher.diagnosticFileOpenerOverride = String(command || "").trim();
        return JSON.stringify(launcher.launcherStateObject());
    }
    function diagnosticClearFileOverrides(): string {
        launcher.diagnosticFileSearchRootOverride = "";
        launcher.diagnosticFileSearchShowHiddenOverrideActive = false;
        launcher.diagnosticFileSearchShowHiddenOverride = false;
        launcher.diagnosticFileOpenerOverride = "";
        return JSON.stringify(launcher.launcherStateObject());
    }
    function diagnosticSetDrunCategoryFilter(categoryKey: string): string {
        return launcher.diagnosticSetDrunCategoryFilter(categoryKey);
    }
    function diagnosticSetViewport(widthValue: real, heightValue: real): string {
        return launcher.diagnosticSetViewport(widthValue, heightValue);
    }
    function diagnosticExecuteEmptyPrimary(): string {
        launcher.executeEmptyPrimary();
        return JSON.stringify({
            executed: true,
            state: launcher.launcherStateObject()
        });
    }
    function diagnosticExecuteSelection(): string {
        var item = launcher.selectedItem;
        var target = item ? String(item.fullPath || item.address || item.exec || item.name || "") : "";
        var executed = launcher.hasResults;
        if (executed)
            launcher.executeSelection();
        return JSON.stringify({
            executed: executed,
            target: target,
            state: launcher.launcherStateObject()
        });
    }
    function invokeEscapeAction(): string {
        var action = launcher.escapeActionStateObject().action;
        var handled = launcher.handleEscapeAction();
        return JSON.stringify({
            handled: handled === true,
            action: action,
            state: launcher.escapeActionStateObject()
        });
    }
    function toggle() {
        if (launcher.launcherOpacity > 0)
            launcher.close();
        else
            launcher.open(launcher.effectiveDefaultMode());
    }
}

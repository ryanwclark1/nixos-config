import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root
    required property QtObject launcher
    visible: false

    IpcHandler {
        target: "Launcher"

        function openDrun() {
            root.launcher.open("drun");
        }
        function openWindow() {
            root.launcher.open("window");
        }
        function openRun() {
            root.launcher.open("run");
        }
        function openEmoji() {
            root.launcher.open("emoji");
        }
        function openCalc() {
            root.launcher.open("calc");
        }
        function openClip() {
            root.launcher.open("clip");
        }
        function openWeb() {
            root.launcher.open("web");
        }
        function openPlugins() {
            root.launcher.open("plugins");
        }
        function openSystem() {
            root.launcher.open("system");
        }
        function openNixos() {
            root.launcher.open("nixos");
        }
        function openMedia() {
            root.launcher.open("media");
        }
        function openWallpapers() {
            root.launcher.open("wallpapers");
        }
        function openKeybinds() {
            root.launcher.open("keybinds");
        }
        function openBookmarks() {
            root.launcher.open("bookmarks");
        }
        function openAi() {
            root.launcher.open("ai");
        }
        function openFiles() {
            root.launcher.open("files");
        }
        function openDmenu(itemsJson: string) {
            var items = [];
            try {
                items = JSON.parse(itemsJson);
            } catch (err) {
                Logger.w("LauncherIpc", "invalid dmenu itemsJson", err);
            }
            root.launcher.mode = "dmenu";
            root.launcher.allItems = items.map(function (it) {
                return {
                    name: it,
                    title: it
                };
            });
            root.launcher.open("dmenu");
        }
        function clearMetrics() {
            root.launcher.clearLauncherMetrics();
        }
        function redetectFilesBackend() {
            root.launcher.forceRedetectFileSearchBackend(true, function (_) {});
        }
        function diagnosticReset() {
            root.launcher.diagnosticReset();
        }
        function filesBackendStatus(): string {
            return JSON.stringify(root.launcher.filesBackendStatusObject());
        }
        function drunCategoryState(): string {
            return JSON.stringify(root.launcher.drunCategoryStateObject());
        }
        function escapeActionState(): string {
            return JSON.stringify(root.launcher.escapeActionStateObject());
        }
        function launcherState(): string {
            return JSON.stringify(root.launcher.launcherStateObject());
        }
        function diagnosticSetSearchText(text: string): string {
            return root.launcher.diagnosticSetSearchText(text);
        }
        function diagnosticSetFileSearchRoot(rootValue: string): string {
            root.launcher.diagnosticFileSearchRootOverride = String(rootValue || "");
            return JSON.stringify(root.launcher.launcherStateObject());
        }
        function diagnosticSetFileShowHidden(value: string): string {
            var normalized = String(value || "").trim().toLowerCase();
            if (normalized === "" || normalized === "inherit") {
                root.launcher.diagnosticFileSearchShowHiddenOverrideActive = false;
            } else {
                root.launcher.diagnosticFileSearchShowHiddenOverrideActive = true;
                root.launcher.diagnosticFileSearchShowHiddenOverride = ["1", "true", "yes", "on"].indexOf(normalized) !== -1;
            }
            return JSON.stringify(root.launcher.launcherStateObject());
        }
        function diagnosticSetFileOpener(command: string): string {
            root.launcher.diagnosticFileOpenerOverride = String(command || "").trim();
            return JSON.stringify(root.launcher.launcherStateObject());
        }
        function diagnosticClearFileOverrides(): string {
            root.launcher.diagnosticFileSearchRootOverride = "";
            root.launcher.diagnosticFileSearchShowHiddenOverrideActive = false;
            root.launcher.diagnosticFileSearchShowHiddenOverride = false;
            root.launcher.diagnosticFileOpenerOverride = "";
            return JSON.stringify(root.launcher.launcherStateObject());
        }
        function diagnosticSetDrunCategoryFilter(categoryKey: string): string {
            return root.launcher.diagnosticSetDrunCategoryFilter(categoryKey);
        }
        function diagnosticSetViewport(widthValue: real, heightValue: real): string {
            return root.launcher.diagnosticSetViewport(widthValue, heightValue);
        }
        function diagnosticExecuteEmptyPrimary(): string {
            root.launcher.executeEmptyPrimary();
            return JSON.stringify({
                executed: true,
                state: root.launcher.launcherStateObject()
            });
        }
        function diagnosticExecuteSelection(): string {
            var item = root.launcher.selectedItem;
            var target = item ? String(item.fullPath || item.address || item.exec || item.name || "") : "";
            var executed = root.launcher.hasResults;
            if (executed)
                root.launcher.executeSelection();
            return JSON.stringify({
                executed: executed,
                target: target,
                state: root.launcher.launcherStateObject()
            });
        }
        function invokeEscapeAction(): string {
            var action = root.launcher.escapeActionStateObject().action;
            var handled = root.launcher.handleEscapeAction();
            return JSON.stringify({
                handled: handled === true,
                action: action,
                state: root.launcher.escapeActionStateObject()
            });
        }
        function toggle() {
            if (root.launcher.launcherOpacity > 0)
                root.launcher.close();
            else
                root.launcher.open(root.launcher.effectiveDefaultMode());
        }
    }
}

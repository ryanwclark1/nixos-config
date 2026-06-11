import QtQuick
import Quickshell
import "../services"

QtObject {
    id: root
    property bool _destroyed: false

    required property QtObject shellRoot
    required property QtObject fileBrowser
    required property QtObject settingsHub
    property var notepad: null
    required property int lazyLoaderSettleMs
    required property int settingsHubReopenMs

    property string fileBrowserCaller: ""
    property string pendingNotepadContent: ""
    property string wallpaperMonitor: ""
    property bool reopenSettingsHubAfterFileBrowser: false

    Component.onDestruction: _destroyed = true

    function openFileBrowserForNotepad(mode) {
        reopenSettingsHubTimer.stop();
        fileBrowserCaller = mode === "save" ? "notepad-save" : "notepad-open";
        shellRoot.openSurface("fileBrowser");
        fileBrowserOpenTimer.opMode = mode;
        fileBrowserOpenTimer.restart();
    }

    function browseWallpaper(monitorName) {
        reopenSettingsHubTimer.stop();
        fileBrowserCaller = "wallpaper";
        wallpaperMonitor = monitorName;
        reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
        if (settingsHub.isOpen)
            settingsHub.close();
        shellRoot.openSurface("fileBrowser");
        fileBrowserOpenTimer.opMode = "__wallpaper__";
        fileBrowserOpenTimer.restart();
    }

    function pickFolder(callerId) {
        reopenSettingsHubTimer.stop();
        fileBrowserCaller = callerId;
        reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
        if (settingsHub.isOpen)
            settingsHub.close();
        shellRoot.openSurface("fileBrowser");
        fileBrowserOpenTimer.opMode = "__folder__";
        fileBrowserOpenTimer.restart();
    }

    function pickWallpaperFolder() {
        root.pickFolder("wallpaper-folder");
    }

    function browseManifest() {
        reopenSettingsHubTimer.stop();
        fileBrowserCaller = "manifest";
        reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
        if (settingsHub.isOpen)
            settingsHub.close();
        shellRoot.openSurface("fileBrowser");
        fileBrowserOpenTimer.opMode = "__manifest__";
        fileBrowserOpenTimer.restart();
    }

    function handleFileBrowserOpenChanged(isOpen) {
        if (!isOpen) {
            shellRoot.closeSurface("fileBrowser");
            if (reopenSettingsHubAfterFileBrowser)
                reopenSettingsHubTimer.restart();
        }
    }

    function handleFileSelected(filePath) {
        shellRoot.closeSurface("fileBrowser");
        if (fileBrowserCaller === "notepad-open") {
            shellRoot.openSurface("notepad");
            Qt.callLater(function () {
                if (_destroyed) return;
                if (notepad)
                    notepad.loadFile(filePath);
            });
        } else if (fileBrowserCaller === "notepad-save") {
            shellRoot.openSurface("notepad");
            Qt.callLater(function () {
                if (_destroyed) return;
                if (notepad)
                    notepad.saveToFile(filePath, pendingNotepadContent);
            });
        } else if (fileBrowserCaller === "wallpaper") {
            WallpaperService.setWallpaper(filePath, wallpaperMonitor);
        } else if (fileBrowserCaller === "manifest") {
            Config.wallpaperDynamicManifest = filePath;
        }
        _resetState();
    }

    function handleFolderSelected(folderPath) {
        shellRoot.closeSurface("fileBrowser");
        if (fileBrowserCaller === "wallpaper-folder") {
            Config.wallpaperDefaultFolder = folderPath;
            WallpaperService.scanWallpapers("shell-file-flow-folder-change");
        } else if (fileBrowserCaller === "recording-folder") {
            Config.recordingOutputDir = folderPath;
        } else if (fileBrowserCaller === "launcher-search-folder") {
            Config.launcherFileSearchRoot = folderPath;
        }
        _resetState();
    }

    function _resetState() {
        fileBrowserCaller = "";
        pendingNotepadContent = "";
        wallpaperMonitor = "";
    }

    property Timer fileBrowserOpenTimer: Timer {
        id: fileBrowserOpenTimer
        interval: root.lazyLoaderSettleMs
        property string opMode: "open"
        onTriggered: {
            if (!root.fileBrowser)
                return;
            var home = Quickshell.env("HOME") || "/home";
            var wallpaperDir = WallpaperService.normalizedWallpaperDir(Config.wallpaperDefaultFolder);
            if (opMode === "__wallpaper__") {
                root.fileBrowser.open(wallpaperDir, [
                    {
                        label: "Images",
                        extensions: ["jpg", "jpeg", "png", "webp", "gif"]
                    }
                ], "open");
            } else if (opMode === "__wallpaper_folder__" || opMode === "__folder__") {
                var startDir = wallpaperDir;
                if (fileBrowserCaller === "recording-folder" && Config.recordingOutputDir)
                    startDir = Config.recordingOutputDir;
                else if (fileBrowserCaller === "launcher-search-folder" && Config.launcherFileSearchRoot)
                    startDir = Config.launcherFileSearchRoot;
                root.fileBrowser.open(startDir, [], "folder");
            } else if (opMode === "__manifest__") {
                root.fileBrowser.open(home, [
                    {
                        label: "JSON files",
                        extensions: ["json"]
                    }
                ], "open");
            } else if (opMode === "open") {
                root.fileBrowser.open(home, [
                    {
                        label: "Text Files",
                        extensions: ["txt", "md", "json", "qml", "conf", "log", "nix", "sh", "toml", "yaml", "yml"]
                    }
                ], "open");
            } else {
                root.fileBrowser.open(home, [
                    {
                        label: "Text Files",
                        extensions: ["txt", "md"]
                    }
                ], "save");
            }
        }
    }

    property Timer reopenSettingsHubTimer: Timer {
        id: reopenSettingsHubTimer
        interval: root.settingsHubReopenMs
        repeat: false
        onTriggered: {
            if (root.reopenSettingsHubAfterFileBrowser && !root.shellRoot.fileBrowserVisible) {
                root.settingsHub.open();
                root.reopenSettingsHubAfterFileBrowser = false;
            }
        }
    }
}

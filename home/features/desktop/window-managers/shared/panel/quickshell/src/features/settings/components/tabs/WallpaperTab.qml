import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../services"
import "../../../../services/ColorUtils.js" as ColorUtils
import "../../../../shared"
import "../../../../widgets" as SharedWidgets
import "WallpaperTabHelpers.js" as WTH
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property string wallpaperSelectedMonitor: ""
    property var wallpaperMonitorNames: []
    property string wallpaperFolderInput: Config.wallpaperDefaultFolder
    property string wallpaperFolderError: ""
    property string solidColorInput: "#000000"
    property string solidColorError: ""
    property bool solidPickerOpen: false
    property real pickerHue: 0
    property real pickerSaturation: 0
    property real pickerValue: 0
    property real pickerAlpha: 100
    property string _settingsExportText: ""
    property var _unsupportedImagePaths: ({})

    function applyWallpaperFolder() {
        var trimmed = (wallpaperFolderInput || "").trim();
        if (!WTH.isWallpaperFolderPathValid(trimmed)) {
            wallpaperFolderError = "Use an absolute path, ~, or ~/path.";
            return;
        }
        wallpaperFolderError = "";
        Config.wallpaperDefaultFolder = trimmed;
        WallpaperService.scanWallpapers();
    }

    function _markUnsupportedImage(path) {
        if (!path || _unsupportedImagePaths[path])
            return;
        _unsupportedImagePaths[path] = true;
        _unsupportedImagePaths = Object.assign({}, _unsupportedImagePaths);
    }

    function openSolidPicker() {
        var normalized = WTH.normalizeSolidColor(solidColorInput);
        if (!normalized)
            normalized = Config.wallpaperSolidColor || "000000ff";
        var r = parseInt(normalized.slice(0, 2), 16);
        var g = parseInt(normalized.slice(2, 4), 16);
        var b = parseInt(normalized.slice(4, 6), 16);
        var a = parseInt(normalized.slice(6, 8), 16);
        var hsv = ColorUtils.rgbToHsv(r, g, b);
        pickerHue = hsv.h;
        pickerSaturation = hsv.s * 100;
        pickerValue = hsv.v * 100;
        pickerAlpha = a / 2.55;
        solidPickerOpen = true;
    }

    function _pickerHex() {
        var rgb = ColorUtils.hsvToRgb(pickerHue, pickerSaturation / 100, pickerValue / 100);
        var a = Math.round(Math.max(0, Math.min(100, pickerAlpha)) * 2.55);
        return ColorUtils.hex2(rgb.r) + ColorUtils.hex2(rgb.g) + ColorUtils.hex2(rgb.b) + ColorUtils.hex2(a);
    }

    function applyPickerColor() {
        var hex = _pickerHex();
        solidColorInput = "#" + hex.slice(0, 6);
        solidColorError = "";
        Config.wallpaperRecentSolidColors = WTH.rememberRecentSolidColor(hex, Config.wallpaperRecentSolidColors);
        var mon = WTH.resolveMonitor(root.wallpaperSelectedMonitor);
        WallpaperService.setSolidColor(hex, mon);
        solidPickerOpen = false;
    }

    function applySolidColor() {
        var normalized = WTH.normalizeSolidColor(solidColorInput);
        if (!normalized) {
            solidColorError = "Use #RRGGBB or #RRGGBBAA.";
            return;
        }
        solidColorError = "";
        solidColorInput = "#" + normalized.slice(0, 6);
        Config.wallpaperRecentSolidColors = WTH.rememberRecentSolidColor(normalized, Config.wallpaperRecentSolidColors);
        var mon = WTH.resolveMonitor(root.wallpaperSelectedMonitor);
        WallpaperService.setSolidColor(normalized, mon);
    }

    function copySolidColor() {
        var normalized = WTH.normalizeSolidColor(solidColorInput);
        if (!normalized) {
            solidColorError = "Use #RRGGBB or #RRGGBBAA.";
            return;
        }
        solidColorError = "";
        var six = normalized.slice(0, 6);
        if (solidCopyProc.running)
            return;
        solidCopyProc.command = [
            "sh", "-c",
            "if command -v wl-copy >/dev/null 2>&1; then "
            + "printf '%s' " + JSON.stringify("#" + six) + " | wl-copy; "
            + "elif command -v xclip >/dev/null 2>&1; then "
            + "printf '%s' " + JSON.stringify("#" + six) + " | xclip -selection clipboard; "
            + "else exit 127; fi"
        ];
        solidCopyProc.running = true;
    }

    function pasteSolidColor() {
        if (!solidPasteProc.running)
            solidPasteProc.running = true;
    }

    function exportWallpaperSettings() {
        var payload = {
            schemaVersion: 1,
            exportedAt: (new Date()).toISOString(),
            defaultFolder: Config.wallpaperDefaultFolder,
            cycleInterval: Config.wallpaperCycleInterval,
            runPywal: Config.wallpaperRunPywal,
            solidColor: Config.wallpaperSolidColor,
            useSolidOnStartup: Config.wallpaperUseSolidOnStartup,
            solidColorsByMonitor: Config.wallpaperSolidColorsByMonitor,
            recentSolidColors: Config.wallpaperRecentSolidColors
        };
        _settingsExportText = JSON.stringify(payload, null, 2);
        if (settingsExportProc.running)
            return;
        settingsExportProc.command = [
            "sh", "-c",
            "if command -v wl-copy >/dev/null 2>&1; then "
            + "cat | wl-copy; "
            + "elif command -v xclip >/dev/null 2>&1; then "
            + "cat | xclip -selection clipboard; "
            + "else exit 127; fi"
        ];
        settingsExportProc.running = true;
    }

    function importWallpaperSettings() {
        if (!settingsImportProc.running)
            settingsImportProc.running = true;
    }

    function _loadFallbackMonitorNames() {
        var names = [];
        var screens = Quickshell.screens || [];
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i];
            var name = (s && s.name) ? String(s.name) : "";
            if (!name.length)
                name = "Monitor " + (i + 1);
            names.push(name);
        }
        root.wallpaperMonitorNames = names;
        if (root.wallpaperSelectedMonitor === "" && names.length > 0)
            root.wallpaperSelectedMonitor = names[0];
    }

    // ── Processes ────────────────────────────────────────────────────────────────

    Process {
        id: wallpaperMonProc
        command: CompositorAdapter.monitorListCommand()
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var mons = JSON.parse(this.text || "[]");
                    var names = [];
                    for (var i = 0; i < mons.length; i++) {
                        if (mons[i].name)
                            names.push(mons[i].name);
                    }
                    root.wallpaperMonitorNames = names;
                    if (root.wallpaperSelectedMonitor === "" && names.length > 0)
                        root.wallpaperSelectedMonitor = names[0];
                    if (names.length === 0)
                        root._loadFallbackMonitorNames();
                } catch (e) {
                    Logger.e("WallpaperTab", "Failed to parse monitor list:", e);
                    root._loadFallbackMonitorNames();
                }
            }
        }
    }

    Process {
        id: solidCopyProc
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                ToastService.showSuccess("Copied", "Solid color copied to clipboard.");
            else
                ToastService.showError("Copy failed", "No clipboard utility found (wl-copy/xclip).");
        }
    }

    Process {
        id: solidPasteProc
        command: ["sh", "-c", "if command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline; elif command -v xclip >/dev/null 2>&1; then xclip -o -selection clipboard; else exit 127; fi"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 127)
                ToastService.showError("Paste failed", "No clipboard utility found (wl-paste/xclip).");
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var pasted = (this.text || "").trim();
                if (!pasted.length)
                    return;
                var normalized = WTH.normalizeSolidColor(pasted);
                if (!normalized) {
                    root.solidColorError = "Clipboard must contain #RRGGBB or #RRGGBBAA.";
                    return;
                }
                root.solidColorError = "";
                root.solidColorInput = "#" + normalized.slice(0, 6);
            }
        }
    }

    Process {
        id: settingsExportProc
        running: false
        stdinEnabled: true
        onStarted: {
            settingsExportProc.write(_settingsExportText);
            settingsExportProc.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                ToastService.showSuccess("Exported", "Wallpaper settings copied to clipboard.");
            else
                ToastService.showError("Export failed", "No clipboard utility found (wl-copy/xclip).");
        }
    }

    Process {
        id: settingsImportProc
        command: ["sh", "-c", "if command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline; elif command -v xclip >/dev/null 2>&1; then xclip -o -selection clipboard; else exit 127; fi"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 127)
                ToastService.showError("Import failed", "No clipboard utility found (wl-paste/xclip).");
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = (this.text || "").trim();
                if (!raw.length) {
                    ToastService.showError("Import failed", "Clipboard is empty.");
                    return;
                }
                try {
                    var data = JSON.parse(raw);
                    if (!data || typeof data !== "object" || Array.isArray(data)) {
                        ToastService.showError("Import failed", "Clipboard JSON root must be an object.");
                        return;
                    }
                    var skipped = [];

                    if (data.defaultFolder !== undefined) {
                        var folder = String(data.defaultFolder || "").trim();
                        if (WTH.isWallpaperFolderPathValid(folder))
                            Config.wallpaperDefaultFolder = folder;
                        else
                            skipped.push("defaultFolder");
                    }
                    if (data.cycleInterval !== undefined)
                        Config.wallpaperCycleInterval = Math.max(0, parseInt(data.cycleInterval, 10) || 0);
                    if (data.runPywal !== undefined)
                        Config.wallpaperRunPywal = !!data.runPywal;
                    if (data.solidColor !== undefined) {
                        var solid = WTH.normalizeSolidColor(data.solidColor);
                        if (solid)
                            Config.wallpaperSolidColor = solid;
                        else
                            skipped.push("solidColor");
                    }
                    if (data.useSolidOnStartup !== undefined)
                        Config.wallpaperUseSolidOnStartup = !!data.useSolidOnStartup;
                    if (data.solidColorsByMonitor !== undefined) {
                        var solidMap = WTH.sanitizeSolidColorMap(data.solidColorsByMonitor);
                        Config.wallpaperSolidColorsByMonitor = Object.assign({}, solidMap);
                    }
                    if (data.recentSolidColors !== undefined) {
                        var recents = WTH.sanitizeRecentSolidColors(data.recentSolidColors);
                        Config.wallpaperRecentSolidColors = recents;
                    }

                    root.wallpaperFolderInput = Config.wallpaperDefaultFolder;
                    root.solidColorInput = "#" + (Config.wallpaperSolidColor || "000000ff").slice(0, 6);
                    WallpaperService.solidColorsByMonitor = Object.assign({}, Config.wallpaperSolidColorsByMonitor || {});
                    WallpaperService.solidColorActive = Object.keys(WallpaperService.solidColorsByMonitor).length > 0;
                    WallpaperService.scanWallpapers();
                    if (skipped.length > 0)
                        ToastService.showNotice("Imported with skips", "Ignored invalid fields: " + skipped.join(", "));
                    else
                        ToastService.showSuccess("Imported", "Wallpaper settings imported from clipboard.");
                } catch (e) {
                    ToastService.showError("Import failed", "Clipboard does not contain valid wallpaper JSON.");
                }
            }
        }
    }

    Component.onCompleted: {
        if (!wallpaperMonProc.running)
            wallpaperMonProc.running = true;
        if (WallpaperService.availableWallpapers.length === 0)
            WallpaperService.scanWallpapers();
        root.solidColorInput = "#" + (Config.wallpaperSolidColor || "000000ff").slice(0, 6);
    }

    Connections {
        target: Config
        function onWallpaperDefaultFolderChanged() {
            root.wallpaperFolderInput = Config.wallpaperDefaultFolder;
            root.wallpaperFolderError = "";
        }
        function onWallpaperSolidColorChanged() {
            var hex = Config.wallpaperSolidColor || "000000ff";
            root.solidColorInput = "#" + hex.slice(0, 6);
        }
    }

    // ── UI ───────────────────────────────────────────────────────────────────────

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Wallpaper"
        iconName: "image.svg"

        // Monitor selector (shown only when >1 monitor)
        ColumnLayout {
            visible: root.wallpaperMonitorNames.length > 1
            spacing: Appearance.spacingS
            Layout.fillWidth: true

            SettingsSectionLabel { text: "MONITOR" }

            SettingsSelectRow {
                label: "Monitor"
                icon: "desktop.svg"
                description: "Use a single target selector when you have multiple displays configured."
                currentValue: root.wallpaperSelectedMonitor
                options: [{ value: "__all__", label: "All Monitors" }].concat(root.wallpaperMonitorNames.map(function (monitorName) {
                    return { value: String(monitorName), label: String(monitorName) };
                }))
                onOptionSelected: value => root.wallpaperSelectedMonitor = value
            }
        }

        // Current wallpaper preview
        SettingsSectionLabel { text: "CURRENT WALLPAPER" }

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Rectangle {
                radius: Appearance.radiusPill
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1
                implicitHeight: 24
                implicitWidth: sourceText.implicitWidth + 16

                Text {
                    id: sourceText
                    anchors.centerIn: parent
                    text: {
                        var mon = WTH.resolveMonitor(root.wallpaperSelectedMonitor);
                        var solidHex = WallpaperService.solidColorForMonitor(mon);
                        if (solidHex.length > 0) return "Source: Solid #" + solidHex.slice(0, 6).toUpperCase();
                        var key = root.wallpaperSelectedMonitor || "__all__";
                        var p = WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
                        if (p.length > 0) return "Source: Image";
                        return "Source: None";
                    }
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                }
            }

            Rectangle {
                radius: Appearance.radiusPill
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1
                implicitHeight: 24
                implicitWidth: targetText.implicitWidth + 16

                Text {
                    id: targetText
                    anchors.centerIn: parent
                    text: "Target: " + (root.wallpaperSelectedMonitor === "__all__" ? "All monitors" : root.wallpaperSelectedMonitor)
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                }
            }
        }

        WallpaperPreviewContainer {
            selectedMonitor: root.wallpaperSelectedMonitor
            unsupportedImagePaths: root._unsupportedImagePaths
            onImageUnsupported: path => root._markUnsupportedImage(path)
        }

        // Quick action buttons
        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingM

            Repeater {
                model: [
                    { icon: "next.svg", label: "Next", action: "next" },
                    { icon: "shuffle.svg", label: "Random", action: "random" },
                    { icon: "color-palette.svg", label: "Solid", action: "solid" },
                    { icon: "folder.svg", label: "Browse...", action: "browse" }
                ]

                delegate: SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: modelData.label
                    iconName: modelData.icon
                    onClicked: {
                        var mon = WTH.resolveMonitor(root.wallpaperSelectedMonitor);
                        if (modelData.action === "next")
                            WallpaperService.nextWallpaper(mon);
                        else if (modelData.action === "random")
                            WallpaperService.randomWallpaper(mon);
                        else if (modelData.action === "solid") {
                            var quickHex = WTH.normalizeSolidColor(root.solidColorInput);
                            Config.wallpaperRecentSolidColors = WTH.rememberRecentSolidColor(quickHex || "000000ff", Config.wallpaperRecentSolidColors);
                            WallpaperService.setSolidColor(quickHex || "000000ff", mon);
                        }
                        else if (modelData.action === "browse" && root.settingsRoot)
                            root.settingsRoot.browseWallpaper(mon);
                    }
                }
            }
        }

        // Settings
        SettingsSectionLabel { text: "SETTINGS" }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SettingsTextInputRow {
                Layout.fillWidth: true
                label: "Default wallpaper folder"
                placeholderText: "~/.config/wallpapers"
                leadingIcon: "folder.svg"
                text: root.wallpaperFolderInput
                errorText: root.wallpaperFolderError
                onTextEdited: value => root.wallpaperFolderInput = value
                onSubmitted: root.applyWallpaperFolder()

                SettingsActionButton {
                    label: "Apply"
                    compact: true
                    emphasized: true
                    onClicked: root.applyWallpaperFolder()
                }

                SettingsActionButton {
                    label: "Pick Folder"
                    compact: true
                    onClicked: if (root.settingsRoot) root.settingsRoot.pickWallpaperFolder()
                }
            }

            SettingsTextInputRow {
                Layout.fillWidth: true
                label: "Solid color"
                placeholderText: "#000000"
                leadingIcon: "color-palette.svg"
                text: root.solidColorInput
                errorText: root.solidColorError
                onTextEdited: value => root.solidColorInput = value
                onSubmitted: root.applySolidColor()

                SettingsActionButton {
                    label: "Apply Solid"
                    compact: true
                    emphasized: true
                    onClicked: root.applySolidColor()
                }
                SettingsActionButton {
                    label: "Pick"
                    compact: true
                    onClicked: root.openSolidPicker()
                }
                SettingsActionButton {
                    label: "Reset Solid"
                    compact: true
                    onClicked: {
                        var mon = WTH.resolveMonitor(root.wallpaperSelectedMonitor);
                        WallpaperService.clearSolidForMonitor(mon, true, true);
                    }
                }
                SettingsActionButton {
                    label: "Copy"
                    compact: true
                    onClicked: root.copySolidColor()
                }
                SettingsActionButton {
                    label: "Paste"
                    compact: true
                    onClicked: root.pasteSolidColor()
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Repeater {
                    model: [
                        "000000", "111827", "1f2937", "374151",
                        "ef4444", "f59e0b", "22c55e", "3b82f6", "8b5cf6"
                    ]

                    delegate: Rectangle {
                        required property string modelData
                        width: 24
                        height: 24
                        radius: Appearance.radiusXXS
                        color: "#" + modelData
                        border.color: Colors.border
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.solidColorInput = "#" + modelData;
                                root.applySolidColor();
                            }
                        }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.spacingS
                visible: (Config.wallpaperRecentSolidColors || []).length > 0

                Text {
                    text: "Recent:"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Medium
                }

                SettingsActionButton {
                    label: "Clear"
                    compact: true
                    onClicked: Config.wallpaperRecentSolidColors = []
                }

                Repeater {
                    model: Config.wallpaperRecentSolidColors || []

                    delegate: Rectangle {
                        required property string modelData
                        width: 20
                        height: 20
                        radius: Appearance.radiusXXS
                        color: "#" + modelData.slice(0, 6)
                        border.color: Colors.border
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.solidColorInput = "#" + modelData.slice(0, 6);
                                root.applySolidColor();
                            }
                        }
                    }
                }
            }
        }

        SettingsFieldGrid {
            SettingsToggleRow {
                label: "Use solid color on startup"
                icon: "color-palette.svg"
                configKey: "wallpaperUseSolidOnStartup"
            }

            SettingsToggleRow {
                visible: !Config.themeName
                label: "Run pywal on change"
                icon: "color-palette.svg"
                configKey: "wallpaperRunPywal"
            }

            SettingsToggleRow {
                label: "Shell-rendered wallpaper"
                icon: "image.svg"
                configKey: "wallpaperUseShellRenderer"
            }

            SettingsSelectRow {
                visible: Config.wallpaperUseShellRenderer
                label: "Transition effect"
                icon: "image-edit.svg"
                currentValue: Config.wallpaperTransitionType
                onOptionSelected: value => { Config.wallpaperTransitionType = value; }
                options: [
                    { label: "Fade", value: "fade" },
                    { label: "Pixelate", value: "pixelate" },
                    { label: "Wipe", value: "wipe" },
                    { label: "Dissolve", value: "dissolve" },
                    { label: "Zoom", value: "zoom" },
                    { label: "Radial", value: "radial" },
                    { label: "Random", value: "random" },
                    { label: "None", value: "none" }
                ]
            }

            SettingsSliderRow {
                visible: Config.wallpaperUseShellRenderer && Config.wallpaperTransitionType !== "none"
                label: "Transition duration"
                icon: "timer.svg"
                value: Config.wallpaperTransitionDuration
                min: 300
                max: 4000
                step: 100
                unit: "ms"
                onMoved: v => Config.wallpaperTransitionDuration = v
            }

            SettingsToggleRow {
                label: "Dynamic wallpaper"
                icon: "timer.svg"
                configKey: "wallpaperDynamicEnabled"
            }
        }

        // Dynamic wallpaper manifest
        SettingsSectionLabel {
            visible: Config.wallpaperDynamicEnabled
            text: "DYNAMIC MANIFEST"
        }

        SettingsTextInputRow {
            visible: Config.wallpaperDynamicEnabled
            Layout.fillWidth: true
            label: "Manifest path"
            placeholderText: "/path/to/manifest.json"
            leadingIcon: "document.svg"
            text: Config.wallpaperDynamicManifest || ""
            onTextEdited: value => Config.wallpaperDynamicManifest = value.trim()
            onSubmitted: value => Config.wallpaperDynamicManifest = value.trim()

            SettingsActionButton {
                label: "Browse…"
                compact: true
                emphasized: true
                onClicked: if (root.settingsRoot) root.settingsRoot.browseManifest()
            }

            SettingsActionButton {
                label: "Clear"
                compact: true
                enabled: (Config.wallpaperDynamicManifest || "") !== ""
                onClicked: Config.wallpaperDynamicManifest = ""
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SettingsActionButton {
                width: root.compactMode ? implicitWidth : 0
                Layout.fillWidth: !root.compactMode
                label: "Export Wallpaper JSON"
                compact: true
                onClicked: root.exportWallpaperSettings()
            }

            SettingsActionButton {
                width: root.compactMode ? implicitWidth : 0
                Layout.fillWidth: !root.compactMode
                label: "Import Wallpaper JSON"
                compact: true
                onClicked: root.importWallpaperSettings()
            }
        }

        // Auto-cycle interval slider
        WallpaperCycleSlider {
            compactMode: root.compactMode
        }

        // Video wallpaper
        SettingsSectionLabel {
            text: "VIDEO WALLPAPER"
        }

        SettingsToggleRow {
            label: "Video wallpaper"
            icon: "video.svg"
            configKey: "wallpaperVideoEnabled"
        }

        SettingsTextInputRow {
            visible: Config.wallpaperVideoEnabled
            Layout.fillWidth: true
            label: "Video file path"
            placeholderText: "/path/to/video.mp4"
            leadingIcon: "video.svg"
            text: Config.wallpaperVideoPath || ""
            onTextEdited: value => Config.wallpaperVideoPath = value.trim()
            onSubmitted: value => Config.wallpaperVideoPath = value.trim()
        }

        SettingsInfoCallout {
            visible: Config.wallpaperVideoEnabled
            iconName: "info.svg"
            title: "Video wallpapers"
            body: "Requires shell renderer mode. Video loops silently behind all windows. Supported: mp4, webm, mkv."
        }

        // Wallhaven browser
        SettingsSectionLabel {
            text: "WALLHAVEN"
        }

        SettingsActionButton {
            label: "Browse Wallhaven"
            iconName: "globe-search.svg"
            description: "Search and download wallpapers from wallhaven.cc"
            emphasized: true
            onClicked: {
                if (root.settingsRoot && root.settingsRoot.parent)
                    root.settingsRoot.parent.toggleSurface("wallhavenBrowser");
            }
        }

        SettingsTextInputRow {
            Layout.fillWidth: true
            label: "Wallhaven API Key (optional)"
            placeholderText: "For NSFW and favorites access"
            leadingIcon: "key.svg"
            text: Config.wallhavenApiKey || ""
            onTextEdited: value => Config.wallhavenApiKey = value.trim()
        }

        // Wallpaper grid
        SettingsSectionLabel {
            text: WallpaperService.scanning ? "SCANNING…" : ("WALLPAPERS  (" + WallpaperService.availableWallpapers.length + ")")
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingM
            visible: !WallpaperService.scanning

            SharedWidgets.EmptyState {
                visible: WallpaperService.availableWallpapers.length === 0
                icon: "image.svg"
                message: "No wallpapers found in search directories"
                width: parent.width
            }

            SettingsActionButton {
                label: "Rescan"
                iconName: "arrow-clockwise.svg"
                compact: true
                onClicked: WallpaperService.scanWallpapers()
            }
        }

        ColumnLayout {
            visible: WallpaperService.scanning
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.LoadingSpinner { Layout.alignment: Qt.AlignHCenter }
            Text {
                text: "Scanning directories…"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeMedium
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Flow {
            visible: !WallpaperService.scanning && WallpaperService.availableWallpapers.length > 0
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Repeater {
                model: WallpaperService.availableWallpapers

                delegate: WallpaperThumbnail {
                    selectedMonitor: root.wallpaperSelectedMonitor
                    unsupportedImagePaths: root._unsupportedImagePaths
                    compactMode: root.compactMode
                    onWallpaperSelected: path => {
                        var mon = WTH.resolveMonitor(root.wallpaperSelectedMonitor);
                        WallpaperService.setWallpaper(path, mon);
                    }
                    onImageUnsupported: path => root._markUnsupportedImage(path)
                }
            }
        }

        // Info callout
        SettingsInfoCallout {
            iconName: "info.svg"
            title: "Wallpaper search directories"
            body: "Requires swww, hyprpaper, or swaybg to apply wallpapers."

            Repeater {
                model: WallpaperService.wallpaperSearchDirs
                delegate: Text {
                    required property string modelData
                    text: "  " + modelData
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                    Layout.fillWidth: true
                    elide: Text.ElideLeft
                }
            }
        }
    }

    WallpaperSolidPicker {
        visible: root.solidPickerOpen
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing
        pickerHue: root.pickerHue
        pickerSaturation: root.pickerSaturation
        pickerValue: root.pickerValue
        pickerAlpha: root.pickerAlpha
        onPickerHueEdited: v => root.pickerHue = v
        onPickerSaturationEdited: v => root.pickerSaturation = v
        onPickerValueEdited: v => root.pickerValue = v
        onPickerAlphaEdited: v => root.pickerAlpha = v
        onApplyRequested: root.applyPickerColor()
        onCancelRequested: root.solidPickerOpen = false
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets
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

    function isWallpaperFolderPathValid(path) {
        var p = (path || "").trim();
        return p.length > 0 && (p.indexOf("/") === 0 || p === "~" || p.indexOf("~/") === 0);
    }

    function applyWallpaperFolder() {
        var trimmed = (wallpaperFolderInput || "").trim();
        if (!isWallpaperFolderPathValid(trimmed)) {
            wallpaperFolderError = "Use an absolute path, ~, or ~/path.";
            return;
        }
        wallpaperFolderError = "";
        Config.wallpaperDefaultFolder = trimmed;
        WallpaperService.scanWallpapers();
    }

    function _imageSource(path) {
        if (!path || _unsupportedImagePaths[path])
            return "";
        return "file://" + path;
    }

    function _markUnsupportedImage(path) {
        if (!path || _unsupportedImagePaths[path])
            return;
        _unsupportedImagePaths[path] = true;
        _unsupportedImagePaths = Object.assign({}, _unsupportedImagePaths);
    }

    function _normalizeSolidColor(value) {
        var v = (value || "").trim();
        if (v.indexOf("#") === 0)
            v = v.slice(1);
        v = v.toLowerCase();
        if (/^[0-9a-f]{6}$/.test(v))
            return v + "ff";
        if (/^[0-9a-f]{8}$/.test(v))
            return v;
        return "";
    }

    function _hex2(v) {
        var n = Math.max(0, Math.min(255, Math.round(v)));
        var s = n.toString(16);
        return s.length < 2 ? "0" + s : s;
    }

    function _hsvToRgb(h, s, v) {
        var hh = ((h % 360) + 360) % 360;
        var ss = Math.max(0, Math.min(1, s));
        var vv = Math.max(0, Math.min(1, v));
        var c = vv * ss;
        var x = c * (1 - Math.abs((hh / 60) % 2 - 1));
        var m = vv - c;
        var rp = 0, gp = 0, bp = 0;
        if (hh < 60) { rp = c; gp = x; bp = 0; }
        else if (hh < 120) { rp = x; gp = c; bp = 0; }
        else if (hh < 180) { rp = 0; gp = c; bp = x; }
        else if (hh < 240) { rp = 0; gp = x; bp = c; }
        else if (hh < 300) { rp = x; gp = 0; bp = c; }
        else { rp = c; gp = 0; bp = x; }
        return {
            r: Math.round((rp + m) * 255),
            g: Math.round((gp + m) * 255),
            b: Math.round((bp + m) * 255)
        };
    }

    function _rgbToHsv(r, g, b) {
        var rr = Math.max(0, Math.min(255, r)) / 255;
        var gg = Math.max(0, Math.min(255, g)) / 255;
        var bb = Math.max(0, Math.min(255, b)) / 255;
        var maxv = Math.max(rr, gg, bb);
        var minv = Math.min(rr, gg, bb);
        var d = maxv - minv;
        var h = 0;
        if (d !== 0) {
            if (maxv === rr) h = 60 * (((gg - bb) / d) % 6);
            else if (maxv === gg) h = 60 * (((bb - rr) / d) + 2);
            else h = 60 * (((rr - gg) / d) + 4);
        }
        if (h < 0) h += 360;
        var s = maxv === 0 ? 0 : d / maxv;
        var v = maxv;
        return { h: h, s: s, v: v };
    }

    function _pickerHex() {
        var rgb = _hsvToRgb(pickerHue, pickerSaturation / 100, pickerValue / 100);
        var a = Math.round(Math.max(0, Math.min(100, pickerAlpha)) * 2.55);
        return _hex2(rgb.r) + _hex2(rgb.g) + _hex2(rgb.b) + _hex2(a);
    }

    function openSolidPicker() {
        var normalized = _normalizeSolidColor(solidColorInput);
        if (!normalized)
            normalized = Config.wallpaperSolidColor || "000000ff";
        var r = parseInt(normalized.slice(0, 2), 16);
        var g = parseInt(normalized.slice(2, 4), 16);
        var b = parseInt(normalized.slice(4, 6), 16);
        var a = parseInt(normalized.slice(6, 8), 16);
        var hsv = _rgbToHsv(r, g, b);
        pickerHue = hsv.h;
        pickerSaturation = hsv.s * 100;
        pickerValue = hsv.v * 100;
        pickerAlpha = a / 2.55;
        solidPickerOpen = true;
    }

    function applyPickerColor() {
        var hex = _pickerHex();
        solidColorInput = "#" + hex.slice(0, 6);
        solidColorError = "";
        _rememberRecentSolidColor(hex);
        var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
        WallpaperService.setSolidColor(hex, mon);
        solidPickerOpen = false;
    }

    function applySolidColor() {
        var normalized = _normalizeSolidColor(solidColorInput);
        if (!normalized) {
            solidColorError = "Use #RRGGBB or #RRGGBBAA.";
            return;
        }
        solidColorError = "";
        solidColorInput = "#" + normalized.slice(0, 6);
        _rememberRecentSolidColor(normalized);
        var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
        WallpaperService.setSolidColor(normalized, mon);
    }

    function _rememberRecentSolidColor(hex8) {
        var normalized = _normalizeSolidColor(hex8);
        if (!normalized)
            return;
        var list = (Config.wallpaperRecentSolidColors || []).slice();
        var next = [normalized];
        for (var i = 0; i < list.length; i++) {
            if ((list[i] || "").toLowerCase() !== normalized)
                next.push((list[i] || "").toLowerCase());
        }
        if (next.length > 12)
            next = next.slice(0, 12);
        Config.wallpaperRecentSolidColors = next;
    }

    function copySolidColor() {
        var normalized = _normalizeSolidColor(solidColorInput);
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

    function clearRecentSolidColors() {
        Config.wallpaperRecentSolidColors = [];
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

    function _sanitizeSolidColorMap(value) {
        var out = {};
        if (!value || typeof value !== "object")
            return out;
        var keys = Object.keys(value);
        for (var i = 0; i < keys.length; i++) {
            var key = String(keys[i] || "");
            if (!key.length)
                continue;
            var color = _normalizeSolidColor(value[key]);
            if (!color)
                continue;
            out[key] = color;
        }
        return out;
    }

    function _sanitizeRecentSolidColors(value) {
        var out = [];
        if (!Array.isArray(value))
            return out;
        for (var i = 0; i < value.length; i++) {
            var color = _normalizeSolidColor(value[i]);
            if (!color || out.indexOf(color) >= 0)
                continue;
            out.push(color);
            if (out.length >= 12)
                break;
        }
        return out;
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
                    console.error("Failed to parse monitor list: " + e);
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
                var normalized = root._normalizeSolidColor(pasted);
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
                        if (root.isWallpaperFolderPathValid(folder))
                            Config.wallpaperDefaultFolder = folder;
                        else
                            skipped.push("defaultFolder");
                    }
                    if (data.cycleInterval !== undefined)
                        Config.wallpaperCycleInterval = Math.max(0, parseInt(data.cycleInterval, 10) || 0);
                    if (data.runPywal !== undefined)
                        Config.wallpaperRunPywal = !!data.runPywal;
                    if (data.solidColor !== undefined) {
                        var solid = root._normalizeSolidColor(data.solidColor);
                        if (solid)
                            Config.wallpaperSolidColor = solid;
                        else
                            skipped.push("solidColor");
                    }
                    if (data.useSolidOnStartup !== undefined)
                        Config.wallpaperUseSolidOnStartup = !!data.useSolidOnStartup;
                    if (data.solidColorsByMonitor !== undefined) {
                        var solidMap = root._sanitizeSolidColorMap(data.solidColorsByMonitor);
                        Config.wallpaperSolidColorsByMonitor = Object.assign({}, solidMap);
                    }
                    if (data.recentSolidColors !== undefined) {
                        var recents = root._sanitizeRecentSolidColors(data.recentSolidColors);
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

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Wallpaper"
        iconName: "󰸉"

        // Monitor selector (shown only when >1 monitor)
        ColumnLayout {
            visible: root.wallpaperMonitorNames.length > 1
            spacing: Colors.spacingS
            Layout.fillWidth: true

            SettingsSectionLabel {
                text: "MONITOR"
            }

            SettingsSelectRow {
                label: "Monitor"
                icon: "󰍹"
                description: "Use a single target selector when you have multiple displays configured."
                currentValue: root.wallpaperSelectedMonitor
                options: [{ value: "__all__", label: "All Monitors" }].concat(root.wallpaperMonitorNames.map(function (monitorName) {
                    return {
                        value: String(monitorName),
                        label: String(monitorName)
                    };
                }))
                onOptionSelected: value => root.wallpaperSelectedMonitor = value
            }
        }

        // Current wallpaper preview
        SettingsSectionLabel {
            text: "CURRENT WALLPAPER"
        }

        Flow {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Rectangle {
                radius: Colors.radiusPill
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1
                implicitHeight: 24
                implicitWidth: sourceText.implicitWidth + 16

                Text {
                    id: sourceText
                    anchors.centerIn: parent
                    text: {
                        var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
                        var solidHex = WallpaperService.solidColorForMonitor(mon);
                        if (solidHex.length > 0) return "Source: Solid #" + solidHex.slice(0, 6).toUpperCase();
                        var key = root.wallpaperSelectedMonitor || "__all__";
                        var p = WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
                        if (p.length > 0) return "Source: Image";
                        return "Source: None";
                    }
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                }
            }

            Rectangle {
                radius: Colors.radiusPill
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
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                }
            }
        }

        Rectangle {
            id: previewContainer
            Layout.fillWidth: true
            height: 160
            radius: Colors.radiusMedium
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            clip: true

            readonly property string previewPath: {
                var key = root.wallpaperSelectedMonitor || "__all__";
                return WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
            }
            readonly property string _previewMonitor: root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor
            readonly property string solidHex: WallpaperService.solidColorForMonitor(_previewMonitor)
            readonly property bool solidPreview: solidHex.length > 0

            property bool _previewFlip: false

            onPreviewPathChanged: {
                if (!previewPath || root._unsupportedImagePaths[previewPath]) {
                    previewA.source = "";
                    previewB.source = "";
                    return;
                }
                var src = root._imageSource(previewPath);
                if (_previewFlip) {
                    previewA.previewPath = previewPath;
                    previewA.source = src;
                } else {
                    previewB.previewPath = previewPath;
                    previewB.source = src;
                }
            }

            Image {
                id: previewA
                property string previewPath: ""
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(previewContainer.width * 2, previewContainer.height * 2)
                opacity: previewContainer._previewFlip ? 0.0 : 1.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Colors.durationEmphasis
                        easing.type: Easing.InOutQuad
                    }
                }
                onStatusChanged: {
                    if (status === Image.Ready && previewContainer._previewFlip) {
                        previewContainer._previewFlip = false;
                    } else if (status === Image.Error && previewPath.length > 0) {
                        root._markUnsupportedImage(previewPath);
                        source = "";
                    }
                }
            }

            Image {
                id: previewB
                property string previewPath: ""
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(previewContainer.width * 2, previewContainer.height * 2)
                opacity: previewContainer._previewFlip ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Colors.durationEmphasis
                        easing.type: Easing.InOutQuad
                    }
                }
                onStatusChanged: {
                    if (status === Image.Ready && !previewContainer._previewFlip) {
                        previewContainer._previewFlip = true;
                    } else if (status === Image.Error && previewPath.length > 0) {
                        root._markUnsupportedImage(previewPath);
                        source = "";
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS
                visible: !previewContainer.solidPreview
                    && (previewContainer.previewPath === "" || (previewA.status !== Image.Ready && previewB.status !== Image.Ready))

                Text {
                    text: "󰸉"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: previewContainer.previewPath !== "" ? "Loading preview…" : "No wallpaper set"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeMedium
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                anchors.centerIn: parent
                visible: previewContainer.solidPreview
                width: Math.min(previewContainer.width - Colors.spacingM * 4, 220)
                height: 96
                radius: Colors.radiusMedium
                color: "#" + previewContainer.solidHex.slice(0, 6)
                border.color: Colors.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Solid #" + previewContainer.solidHex.slice(0, 6).toUpperCase()
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    margins: Colors.spacingM
                }
                visible: previewContainer.previewPath !== "" || previewContainer.solidPreview
                width: Math.min(previewContainer.width - Colors.spacingM * 2, previewName.implicitWidth + 16)
                height: 22
                radius: Colors.radiusPill
                color: Qt.rgba(0, 0, 0, 0.55)

                Text {
                    id: previewName
                    anchors.centerIn: parent
                    text: {
                        var p = previewContainer.previewPath;
                        if (previewContainer.solidPreview)
                            return "Solid #" + previewContainer.solidHex.slice(0, 6).toUpperCase();
                        if (!p)
                            return "";
                        var parts = p.split("/");
                        return parts[parts.length - 1];
                    }
                    color: "#ffffff"
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    elide: Text.ElideLeft
                    maximumLineCount: 1
                }
            }
        }

        // Quick action buttons
        Flow {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            Repeater {
                model: [
                    {
                        icon: "󰒭",
                        label: "Next",
                        action: "next"
                    },
                    {
                        icon: "󰒝",
                        label: "Random",
                        action: "random"
                    },
                    {
                        icon: "󰝤",
                        label: "Solid",
                        action: "solid"
                    },
                    {
                        icon: "󰉋",
                        label: "Browse...",
                        action: "browse"
                    }
                ]

                delegate: SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: modelData.label
                    iconName: modelData.icon
                    onClicked: {
                        var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
                        if (modelData.action === "next")
                            WallpaperService.nextWallpaper(mon);
                        else if (modelData.action === "random")
                            WallpaperService.randomWallpaper(mon);
                        else if (modelData.action === "solid") {
                            var quickHex = root._normalizeSolidColor(root.solidColorInput);
                            root._rememberRecentSolidColor(quickHex || "000000ff");
                            WallpaperService.setSolidColor(quickHex || "000000ff", mon);
                        }
                        else if (modelData.action === "browse" && root.settingsRoot)
                            root.settingsRoot.browseWallpaper(mon);
                    }
                }
            }
        }

        // Settings
        SettingsSectionLabel {
            text: "SETTINGS"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            SettingsTextInputRow {
                id: wallpaperFolderField
                Layout.fillWidth: true
                label: "Default wallpaper folder"
                placeholderText: "~/.config/wallpapers"
                leadingIcon: "󰉋"
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
                    onClicked: if (root.settingsRoot)
                        root.settingsRoot.pickWallpaperFolder()
                }
            }

            SettingsTextInputRow {
                Layout.fillWidth: true
                label: "Solid color"
                placeholderText: "#000000"
                leadingIcon: "󰝤"
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
                        var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
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
                spacing: Colors.spacingS

                Repeater {
                    model: [
                        "000000", "111827", "1f2937", "374151",
                        "ef4444", "f59e0b", "22c55e", "3b82f6", "8b5cf6"
                    ]

                    delegate: Rectangle {
                        required property string modelData
                        width: 24
                        height: 24
                        radius: Colors.radiusXXS
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
                spacing: Colors.spacingS
                visible: (Config.wallpaperRecentSolidColors || []).length > 0

                Text {
                    text: "Recent:"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                }

                SettingsActionButton {
                    label: "Clear"
                    compact: true
                    onClicked: root.clearRecentSolidColors()
                }

                Repeater {
                    model: Config.wallpaperRecentSolidColors || []

                    delegate: Rectangle {
                        required property string modelData
                        width: 20
                        height: 20
                        radius: Colors.radiusXXS
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
                icon: "󰝤"
                configKey: "wallpaperUseSolidOnStartup"
            }

            SettingsToggleRow {
                visible: !Config.themeName
                label: "Run pywal on change"
                icon: "󰏘"
                configKey: "wallpaperRunPywal"
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Colors.spacingS

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
        ColumnLayout {
            spacing: Colors.spacingM
            Layout.fillWidth: true

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                Text {
                    width: root.compactMode ? parent.width : undefined
                    text: "Auto-Cycle Interval"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: Config.wallpaperCycleInterval === 0 ? "Off" : Config.wallpaperCycleInterval + " min"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontMono
                }
            }

            Item {
                Layout.fillWidth: true
                height: 24

                Rectangle {
                    id: cycleTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    color: Colors.surface
                    radius: 3

                    Rectangle {
                        width: parent.width * (Config.wallpaperCycleInterval / 60)
                        height: parent.height
                        color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                        radius: 3
                        Behavior on width {
                            NumberAnimation {
                                duration: Colors.durationSnap
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: Colors.durationFast
                            }
                        }
                    }
                }

                Rectangle {
                    width: 14
                    height: 14
                    radius: width / 2
                    color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                    border.color: Colors.bgWidget
                    border.width: 2
                    x: Math.max(0, Math.min(parent.width - width, parent.width * (Config.wallpaperCycleInterval / 60) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on x {
                        NumberAnimation {
                            duration: Colors.durationSnap
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Colors.durationFast
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -4
                    anchors.bottomMargin: -4
                    cursorShape: Qt.PointingHandCursor
                    function updateCycle(mouse) {
                        var raw = (mouse.x / width) * 60;
                        if (raw < 2) {
                            Config.wallpaperCycleInterval = 0;
                            return;
                        }
                        var snapped = Math.round(raw / 5) * 5;
                        Config.wallpaperCycleInterval = Math.max(5, Math.min(60, snapped));
                    }
                    onPressed: mouse => updateCycle(mouse)
                    onPositionChanged: mouse => {
                        if (pressed)
                            updateCycle(mouse);
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                Text {
                    width: root.compactMode ? parent.width : undefined
                    text: "Off"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }

                Text {
                    text: "60 min"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }
            }
        }

        // Wallpaper grid
        SettingsSectionLabel {
            text: WallpaperService.scanning ? "SCANNING…" : ("WALLPAPERS  (" + WallpaperService.availableWallpapers.length + ")")
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingM
            visible: !WallpaperService.scanning

            SharedWidgets.EmptyState {
                visible: WallpaperService.availableWallpapers.length === 0
                icon: "󰸉"
                message: "No wallpapers found in search directories"
                width: parent.width
            }

            SettingsActionButton {
                label: "Rescan"
                iconName: "󰑐"
                compact: true
                onClicked: WallpaperService.scanWallpapers()
            }
        }

        ColumnLayout {
            visible: WallpaperService.scanning
            Layout.fillWidth: true
            spacing: Colors.spacingS

            SharedWidgets.LoadingSpinner {
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Scanning directories…"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeMedium
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Flow {
            visible: !WallpaperService.scanning && WallpaperService.availableWallpapers.length > 0
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Repeater {
                model: WallpaperService.availableWallpapers

                delegate: Item {
                    id: thumbDelegate
                    required property var modelData
                    required property int index

                    readonly property string activePath: {
                        var key = root.wallpaperSelectedMonitor || "__all__";
                        return WallpaperService.wallpapers[key] || WallpaperService.wallpapers["__all__"] || "";
                    }
                    readonly property bool isActive: modelData.path === activePath

                    width: root.compactMode ? 92 : 108
                    height: root.compactMode ? 72 : 80
                    scale: 1.0

                    SequentialAnimation {
                        id: thumbPulse
                        NumberAnimation {
                            target: thumbDelegate
                            property: "scale"
                            to: 0.92
                            duration: Colors.durationSnap
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: thumbDelegate
                            property: "scale"
                            to: 1.0
                            duration: Colors.durationSnap
                            easing.type: Easing.OutQuad
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Colors.radiusSmall
                        color: isActive ? Colors.highlight : Colors.bgWidget
                        border.color: isActive ? Colors.primary : Colors.border
                        border.width: isActive ? 2 : 1
                        clip: true

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Colors.durationFast
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: Colors.durationFast
                            }
                        }

                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            source: root._imageSource(modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            cache: false
                            sourceSize: Qt.size(216, 160)
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            onStatusChanged: {
                                if (status === Image.Error)
                                    root._markUnsupportedImage(modelData.path);
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Colors.durationNormal
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰸉"
                            color: Colors.textDisabled
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeHuge
                            visible: thumbImage.status !== Image.Ready
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                right: parent.right
                                margins: 5
                            }
                            visible: isActive
                            width: 18
                            height: 18
                            radius: height / 2
                            color: Colors.primary

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                color: Colors.text
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeXS
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: thumbMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: Colors.durationSnap
                                }
                            }
                        }

                        Text {
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                margins: Colors.spacingXS
                            }
                            text: modelData.filename
                            color: "#ffffff"
                            font.pixelSize: Colors.fontSizeXS
                            elide: Text.ElideLeft
                            visible: thumbMouse.containsMouse
                        }

                        MouseArea {
                            id: thumbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                thumbPulse.restart();
                                var mon = root.wallpaperSelectedMonitor === "__all__" ? "" : root.wallpaperSelectedMonitor;
                                WallpaperService.setWallpaper(modelData.path, mon);
                            }
                        }
                    }
                }
            }
        }

        // Info callout
        SettingsInfoCallout {
            iconName: "󰋗"
            title: "Wallpaper search directories"
            body: "Requires swww, hyprpaper, or swaybg to apply wallpapers."

            Repeater {
                model: WallpaperService.wallpaperSearchDirs
                delegate: Text {
                    required property string modelData
                    text: "  " + modelData
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    Layout.fillWidth: true
                    elide: Text.ElideLeft
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.solidPickerOpen
        color: Qt.rgba(0, 0, 0, 0.45)
        z: 2000

        MouseArea {
            anchors.fill: parent
            onClicked: root.solidPickerOpen = false
        }

        Rectangle {
            width: Math.min(parent.width - (root.tightSpacing ? 32 : 60), 560)
            color: Colors.bgGlass
            border.color: Colors.border
            border.width: 1
            radius: Colors.radiusLarge
            anchors.centerIn: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingL
                spacing: Colors.spacingM

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Text {
                        width: root.compactMode ? parent.width : Math.max(0, parent.width - solidPickerCloseButton.implicitWidth - Colors.spacingS)
                        text: "Solid Color Picker"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeLarge
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }

                    SettingsActionButton {
                        id: solidPickerCloseButton
                        label: "Close"
                        compact: true
                        onClicked: root.solidPickerOpen = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Colors.radiusMedium
                    color: "#" + root._pickerHex().slice(0, 6)
                    border.color: Colors.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "#" + root._pickerHex().toUpperCase()
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.family: Colors.fontMono
                        font.weight: Font.Medium
                    }
                }

                SettingsSliderRow {
                    label: "Hue"
                    min: 0
                    max: 360
                    step: 1
                    unit: ""
                    value: root.pickerHue
                    onMoved: v => root.pickerHue = v
                }

                SettingsSliderRow {
                    label: "Saturation"
                    min: 0
                    max: 100
                    step: 1
                    unit: "%"
                    value: root.pickerSaturation
                    onMoved: v => root.pickerSaturation = v
                }

                SettingsSliderRow {
                    label: "Brightness"
                    min: 0
                    max: 100
                    step: 1
                    unit: "%"
                    value: root.pickerValue
                    onMoved: v => root.pickerValue = v
                }

                SettingsSliderRow {
                    label: "Alpha"
                    min: 0
                    max: 100
                    step: 1
                    unit: "%"
                    value: root.pickerAlpha
                    onMoved: v => root.pickerAlpha = v
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SettingsActionButton {
                        label: "Cancel"
                        compact: true
                        onClicked: root.solidPickerOpen = false
                    }

                    SettingsActionButton {
                        label: "Apply Color"
                        compact: true
                        emphasized: true
                        onClicked: root.applyPickerColor()
                    }
                }
            }
        }
    }
}

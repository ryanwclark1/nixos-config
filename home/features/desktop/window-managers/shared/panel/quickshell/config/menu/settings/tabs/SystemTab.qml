import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    readonly property var launcherModes: [
        { key: "drun", label: "Apps", icon: "󰀻" },
        { key: "window", label: "Windows", icon: "󱗼" },
        { key: "files", label: "Files", icon: "󰈔" },
        { key: "ai", label: "AI", icon: "󰚩" },
        { key: "clip", label: "Clipboard", icon: "󰅍" },
        { key: "emoji", label: "Emoji", icon: "󰞅" },
        { key: "calc", label: "Calc", icon: "󰪚" },
        { key: "web", label: "Web", icon: "󰖟" },
        { key: "run", label: "Run", icon: "󰆍" },
        { key: "system", label: "System", icon: "󰒓" },
        { key: "keybinds", label: "Keybinds", icon: "󰌌" },
        { key: "media", label: "Media", icon: "󰝚" },
        { key: "nixos", label: "NixOS", icon: "" },
        { key: "wallpapers", label: "Wallpapers", icon: "󰸉" },
        { key: "bookmarks", label: "Bookmarks", icon: "󰃀" }
    ]
    readonly property var launcherDefaultModes: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"]
    readonly property var webProviders: [
        { key: "duckduckgo", label: "DuckDuckGo", icon: "󰇥" },
        { key: "google", label: "Google", icon: "󰊯" },
        { key: "youtube", label: "YouTube", icon: "󰗃" },
        { key: "nixos", label: "NixOS Packages", icon: "" },
        { key: "github", label: "GitHub", icon: "󰊤" }
    ]
    readonly property var webProviderDefaultOrder: ["duckduckgo", "google", "youtube", "nixos", "github"]
    readonly property var webAliasDefaults: ({
        "duckduckgo": ["d", "ddg"],
        "google": ["g"],
        "youtube": ["yt"],
        "nixos": ["nix", "np"],
        "github": ["gh"]
    })

    function defaultWebAliasesCopy() {
        return JSON.parse(JSON.stringify(webAliasDefaults));
    }

    function webProviderMeta(providerKey) {
        for (var i = 0; i < webProviders.length; ++i) {
            if (webProviders[i].key === providerKey)
                return webProviders[i];
        }
        return { key: providerKey, label: providerKey, icon: "󰖟" };
    }

    function parseAliasTokens(text, providerKey) {
        var value = String(text || "").toLowerCase();
        var raw = value.split(/[\s,]+/);
        var out = [];
        var seen = {};
        for (var i = 0; i < raw.length; ++i) {
            var token = String(raw[i] || "").trim();
            if (token === "" || token === providerKey || seen[token])
                continue;
            if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(token))
                continue;
            out.push(token);
            seen[token] = true;
        }
        return out;
    }

    function webAliasString(providerKey) {
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        var list = aliases[providerKey];
        if (!Array.isArray(list))
            list = [];
        return list.join(", ");
    }

    function setWebAliasString(providerKey, textValue) {
        var next = Object.assign({}, (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({}));
        next[providerKey] = parseAliasTokens(textValue, providerKey);
        Config.launcherWebAliases = next;
    }

    function setEnabledModes(nextModes) {
        var allowed = {};
        var i;
        for (i = 0; i < launcherModes.length; i++)
            allowed[launcherModes[i].key] = true;

        var next = [];
        var seen = {};
        for (i = 0; i < nextModes.length; i++) {
            var key = String(nextModes[i] || "");
            if (!allowed[key] || seen[key])
                continue;
            next.push(key);
            seen[key] = true;
        }

        if (next.length === 0)
            next = ["drun"];

        Config.launcherEnabledModes = next;

        var currentOrder = Array.isArray(Config.launcherModeOrder) ? Config.launcherModeOrder : [];
        var newOrder = [];
        var included = {};
        for (i = 0; i < currentOrder.length; i++) {
            var orderedKey = String(currentOrder[i] || "");
            if (next.indexOf(orderedKey) !== -1 && !included[orderedKey]) {
                newOrder.push(orderedKey);
                included[orderedKey] = true;
            }
        }
        for (i = 0; i < next.length; i++) {
            var extra = next[i];
            if (!included[extra]) {
                newOrder.push(extra);
                included[extra] = true;
            }
        }
        Config.launcherModeOrder = newOrder;

        if (next.indexOf(Config.launcherDefaultMode) === -1)
            Config.launcherDefaultMode = next[0];
    }

    function toggleLauncherMode(modeKey) {
        var current = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : [];
        var idx = current.indexOf(modeKey);
        if (idx >= 0)
            current.splice(idx, 1);
        else
            current.push(modeKey);
        setEnabledModes(current);
    }

    function applyModePreset(preset) {
        var presetModes = [];
        if (preset === "minimal")
            presetModes = ["drun", "window", "files", "run", "system", "media"];
        else if (preset === "full")
            presetModes = launcherModes.map(function(modeMeta) { return modeMeta.key; });
        else
            presetModes = ["drun", "window", "files", "ai", "clip", "system", "media"];

        setEnabledModes(presetModes);
        Config.launcherModeOrder = presetModes.slice();
    }

    function launcherModeMeta(modeKey) {
        for (var i = 0; i < launcherModes.length; i++) {
            if (launcherModes[i].key === modeKey)
                return launcherModes[i];
        }
        return { key: modeKey, label: modeKey, icon: "•" };
    }

    function orderedEnabledModes() {
        var enabled = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes : [];
        var order = Array.isArray(Config.launcherModeOrder) ? Config.launcherModeOrder : [];
        var out = [];
        var seen = {};
        var i;
        for (i = 0; i < order.length; i++) {
            var modeKey = String(order[i] || "");
            if (enabled.indexOf(modeKey) !== -1 && !seen[modeKey]) {
                out.push(modeKey);
                seen[modeKey] = true;
            }
        }
        for (i = 0; i < enabled.length; i++) {
            var extra = String(enabled[i] || "");
            if (!seen[extra]) {
                out.push(extra);
                seen[extra] = true;
            }
        }
        return out;
    }

    function moveMode(modeKey, delta) {
        var current = orderedEnabledModes();
        var from = current.indexOf(modeKey);
        if (from < 0)
            return;
        var to = Math.max(0, Math.min(current.length - 1, from + delta));
        if (to === from)
            return;
        var moved = current[from];
        current.splice(from, 1);
        current.splice(to, 0, moved);
        Config.launcherModeOrder = current.slice();
    }

    function setWebProviderOrder(nextOrder) {
        var allowed = {};
        var i;
        for (i = 0; i < webProviders.length; i++)
            allowed[webProviders[i].key] = true;

        var out = [];
        var seen = {};
        for (i = 0; i < nextOrder.length; i++) {
            var key = String(nextOrder[i] || "");
            if (!allowed[key] || seen[key])
                continue;
            out.push(key);
            seen[key] = true;
        }
        if (out.length === 0)
            out = webProviderDefaultOrder.slice();
        Config.launcherWebProviderOrder = out;
    }

    function orderedWebProviders() {
        var order = Array.isArray(Config.launcherWebProviderOrder) ? Config.launcherWebProviderOrder : [];
        var out = [];
        var seen = {};
        var i;
        for (i = 0; i < order.length; i++) {
            var key = String(order[i] || "");
            if (seen[key])
                continue;
            for (var j = 0; j < webProviders.length; j++) {
                if (webProviders[j].key === key) {
                    out.push(key);
                    seen[key] = true;
                    break;
                }
            }
        }
        for (i = 0; i < webProviderDefaultOrder.length; i++) {
            var fallbackKey = webProviderDefaultOrder[i];
            if (!seen[fallbackKey]) {
                out.push(fallbackKey);
                seen[fallbackKey] = true;
            }
        }
        return out;
    }

    function toggleWebProvider(providerKey) {
        var current = orderedWebProviders();
        var idx = current.indexOf(providerKey);
        if (idx >= 0) {
            if (current.length <= 1)
                return;
            current.splice(idx, 1);
        } else {
            current.push(providerKey);
        }
        setWebProviderOrder(current);
    }

    function moveWebProvider(providerKey, delta) {
        var current = orderedWebProviders();
        var from = current.indexOf(providerKey);
        if (from < 0)
            return;
        var to = Math.max(0, Math.min(current.length - 1, from + delta));
        if (to === from)
            return;
        var moved = current[from];
        current.splice(from, 1);
        current.splice(to, 0, moved);
        setWebProviderOrder(current);
    }

    function resetLauncherDefaults() {
        Config.launcherDefaultMode = "drun";
        Config.launcherShowModeHints = true;
        Config.launcherShowHomeSections = true;
        Config.launcherEnablePreload = true;
        Config.launcherKeepSearchOnModeSwitch = true;
        Config.launcherEnableDebugTimings = false;
        Config.launcherShowRuntimeMetrics = false;
        Config.launcherPreloadFailureThreshold = 3;
        Config.launcherPreloadFailureBackoffSec = 120;
        Config.launcherMaxResults = 80;
        Config.launcherFileMinQueryLength = 2;
        Config.launcherFileMaxResults = 100;
        Config.launcherRecentsLimit = 12;
        Config.launcherRecentAppsLimit = 6;
        Config.launcherSuggestionsLimit = 4;
        Config.launcherCacheTtlSec = 300;
        Config.launcherSearchDebounceMs = 35;
        Config.launcherFileSearchDebounceMs = 140;
        Config.launcherTabBehavior = "contextual";
        Config.launcherWebEnterUsesPrimary = true;
        Config.launcherWebNumberHotkeysEnabled = true;
        Config.launcherWebAliases = defaultWebAliasesCopy();
        Config.launcherRememberWebProvider = true;
        Config.launcherWebLastProviderKey = "duckduckgo";
        Config.launcherWebProviderOrder = webProviderDefaultOrder.slice();
        Config.launcherEnabledModes = launcherDefaultModes.slice();
        Config.launcherModeOrder = launcherDefaultModes.slice();
        Config.launcherScoreNameWeight = 1.0;
        Config.launcherScoreTitleWeight = 0.92;
        Config.launcherScoreExecWeight = 0.88;
        Config.launcherScoreBodyWeight = 0.75;
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Shell Behavior"
        iconName: "󰒓"

        SettingsCard {
            title: "Shell"
            iconName: "󰒓"
            description: "Core shell visuals and transient notification behavior."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Floating Bar"
                    icon: "󰖲"
                    configKey: "barFloating"
                }
                SettingsToggleRow {
                    label: "Blur Effects"
                    icon: "󰃠"
                    configKey: "blurEnabled"
                }
            }

            SettingsSliderRow {
                label: "Notification Width"
                min: 280
                max: 520
                value: Config.notifWidth
                onMoved: v => Config.notifWidth = v
            }

            SettingsSliderRow {
                label: "Popup Duration"
                min: 2000
                max: 10000
                step: 500
                value: Config.popupTimer
                unit: "ms"
                onMoved: v => Config.popupTimer = v
            }
        }

        SettingsCard {
            title: "Launcher"
            iconName: "󰍉"
            description: "Default launcher mode and home screen hinting."

            SettingsModeRow {
                label: "Default Mode"
                currentValue: Config.launcherDefaultMode
                options: [
                    {
                        value: "drun",
                        label: "Apps"
                    },
                    {
                        value: "window",
                        label: "Windows"
                    },
                    {
                        value: "files",
                        label: "Files"
                    },
                    {
                        value: "ai",
                        label: "AI"
                    },
                    {
                        value: "clip",
                        label: "Clipboard"
                    },
                    {
                        value: "system",
                        label: "System"
                    },
                    {
                        value: "media",
                        label: "Media"
                    },
                    {
                        value: "run",
                        label: "Run"
                    },
                    {
                        value: "web",
                        label: "Web"
                    },
                    {
                        value: "emoji",
                        label: "Emoji"
                    },
                    {
                        value: "calc",
                        label: "Calc"
                    },
                    {
                        value: "bookmarks",
                        label: "Bookmarks"
                    },
                    {
                        value: "keybinds",
                        label: "Keybinds"
                    },
                    {
                        value: "nixos",
                        label: "NixOS"
                    },
                    {
                        value: "wallpapers",
                        label: "Wallpapers"
                    }
                ]
                onModeSelected: modeValue => Config.launcherDefaultMode = modeValue
            }

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Show Mode Hints"
                    icon: "󰌌"
                    configKey: "launcherShowModeHints"
                }
                SettingsToggleRow {
                    label: "Show Home Sections"
                    icon: "󰆍"
                    configKey: "launcherShowHomeSections"
                }
                SettingsToggleRow {
                    label: "Background Preload"
                    icon: "󰔟"
                    configKey: "launcherEnablePreload"
                }
                SettingsToggleRow {
                    label: "Keep Query on Mode Switch"
                    icon: "󰍉"
                    configKey: "launcherKeepSearchOnModeSwitch"
                }
                SettingsToggleRow {
                    label: "Debug Launcher Timings"
                    icon: "󰔛"
                    configKey: "launcherEnableDebugTimings"
                }
                SettingsToggleRow {
                    label: "Show Runtime Metrics"
                    icon: "󰓅"
                    configKey: "launcherShowRuntimeMetrics"
                }
                SettingsModeRow {
                    label: "Tab Behavior"
                    currentValue: Config.launcherTabBehavior
                    options: [
                        {
                            value: "contextual",
                            label: "Contextual"
                        },
                        {
                            value: "results",
                            label: "Results Only"
                        },
                        {
                            value: "mode",
                            label: "Mode Switch"
                        }
                    ]
                    onModeSelected: modeValue => Config.launcherTabBehavior = modeValue
                }
                SettingsToggleRow {
                    label: "Web Enter Uses Primary"
                    icon: "󰖟"
                    configKey: "launcherWebEnterUsesPrimary"
                }
                SettingsToggleRow {
                    label: "Web Number Hotkeys"
                    icon: "󰌌"
                    configKey: "launcherWebNumberHotkeysEnabled"
                }
                SettingsToggleRow {
                    label: "Remember Web Provider"
                    icon: "󰖟"
                    configKey: "launcherRememberWebProvider"
                }
            }

            SettingsSliderRow {
                label: "Max Results"
                min: 20
                max: 200
                step: 5
                value: Config.launcherMaxResults
                onMoved: v => Config.launcherMaxResults = v
            }

            SettingsSliderRow {
                label: "File Query Min Length"
                min: 1
                max: 6
                value: Config.launcherFileMinQueryLength
                onMoved: v => Config.launcherFileMinQueryLength = v
            }

            SettingsSliderRow {
                label: "File Search Max Results"
                min: 20
                max: 300
                step: 10
                value: Config.launcherFileMaxResults
                onMoved: v => Config.launcherFileMaxResults = v
            }

            SettingsSliderRow {
                label: "Cache TTL"
                min: 30
                max: 1800
                step: 30
                value: Config.launcherCacheTtlSec
                unit: "s"
                onMoved: v => Config.launcherCacheTtlSec = v
            }

            SettingsSliderRow {
                label: "Search Debounce"
                min: 0
                max: 250
                step: 5
                value: Config.launcherSearchDebounceMs
                unit: "ms"
                onMoved: v => Config.launcherSearchDebounceMs = v
            }

            SettingsSliderRow {
                label: "File Search Debounce"
                min: 50
                max: 1200
                step: 10
                value: Config.launcherFileSearchDebounceMs
                unit: "ms"
                onMoved: v => Config.launcherFileSearchDebounceMs = v
            }

            SettingsSectionLabel {
                text: "WEB PROVIDERS"
            }

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: root.webProviders
                    delegate: SharedWidgets.FilterChip {
                        required property var modelData
                        label: modelData.label
                        icon: modelData.icon
                        selected: root.orderedWebProviders().indexOf(modelData.key) !== -1
                        onClicked: root.toggleWebProvider(modelData.key)
                    }
                }
            }

            Repeater {
                model: root.orderedWebProviders()

                delegate: SettingsListRow {
                    minimumHeight: root.compactMode ? 76 : 44

                    Rectangle {
                        Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                        border.color: Colors.border
                        border.width: 1
                        color: Colors.surface
                        implicitHeight: 24
                        implicitWidth: 24
                        radius: 12

                        Text {
                            anchors.centerIn: parent
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeSmall
                            text: {
                                for (var i = 0; i < root.webProviders.length; ++i) {
                                    if (root.webProviders[i].key === modelData)
                                        return root.webProviders[i].icon;
                                }
                                return "󰖟";
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXS

                        Text {
                            Layout.fillWidth: true
                            color: Colors.text
                            elide: Text.ElideRight
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            text: {
                                for (var i = 0; i < root.webProviders.length; ++i) {
                                    if (root.webProviders[i].key === modelData)
                                        return root.webProviders[i].label;
                                }
                                return modelData;
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Colors.spacingS

                            SettingsActionButton {
                                compact: true
                                enabled: index > 0
                                label: "↑"
                                onClicked: root.moveWebProvider(modelData, -1)
                            }

                            SettingsActionButton {
                                compact: true
                                enabled: index < (root.orderedWebProviders().length - 1)
                                label: "↓"
                                onClicked: root.moveWebProvider(modelData, 1)
                            }
                        }
                    }
                }
            }

            SettingsSectionLabel {
                text: "WEB ALIASES"
            }

            SettingsInfoCallout {
                iconName: "󰛢"
                title: "Alias format"
                body: "Enter aliases separated by commas. Example: g, gg"
            }

            Repeater {
                model: root.orderedWebProviders()

                delegate: SettingsTextInputRow {
                    id: aliasRow
                    required property var modelData
                    property bool syncingText: false
                    label: root.webProviderMeta(modelData).label + " Aliases"
                    leadingIcon: root.webProviderMeta(modelData).icon
                    placeholderText: "comma-separated aliases"
                    function syncFromConfig() {
                        var next = root.webAliasString(modelData);
                        if (text === next)
                            return;
                        syncingText = true;
                        text = next;
                        syncingText = false;
                    }
                    Component.onCompleted: syncFromConfig()
                    onSubmitted: value => root.setWebAliasString(modelData, value)
                    onTextEdited: value => {
                        if (!syncingText)
                            root.setWebAliasString(modelData, value);
                    }

                    Connections {
                        target: Config
                        function onLauncherWebAliasesChanged() {
                            if (!aliasRow.inputActiveFocus)
                                aliasRow.syncFromConfig();
                        }
                    }
                }
            }

            SettingsSliderRow {
                label: "Preload Failure Threshold"
                min: 1
                max: 10
                step: 1
                value: Config.launcherPreloadFailureThreshold
                unit: ""
                onMoved: v => Config.launcherPreloadFailureThreshold = v
            }

            SettingsSliderRow {
                label: "Preload Backoff"
                min: 10
                max: 900
                step: 10
                value: Config.launcherPreloadFailureBackoffSec
                unit: "s"
                onMoved: v => Config.launcherPreloadFailureBackoffSec = v
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Reset Runtime Metrics"
                iconName: "󰑐"
                compact: true
                onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "clearMetrics"])
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Re-detect Files Backend"
                iconName: "󰑓"
                compact: true
                onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "redetectFilesBackend"])
            }

            SettingsSliderRow {
                label: "Recents History Limit"
                min: 4
                max: 40
                step: 1
                value: Config.launcherRecentsLimit
                unit: ""
                onMoved: v => Config.launcherRecentsLimit = v
            }

            SettingsSliderRow {
                label: "Recent Apps on Home"
                min: 1
                max: 20
                step: 1
                value: Config.launcherRecentAppsLimit
                unit: ""
                onMoved: v => Config.launcherRecentAppsLimit = v
            }

            SettingsSliderRow {
                label: "Suggestions on Home"
                min: 1
                max: 20
                step: 1
                value: Config.launcherSuggestionsLimit
                unit: ""
                onMoved: v => Config.launcherSuggestionsLimit = v
            }

            SettingsSectionLabel {
                text: "MODE AVAILABILITY"
            }

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: root.launcherModes
                    delegate: SharedWidgets.FilterChip {
                        required property var modelData
                        label: modelData.label
                        icon: modelData.icon
                        selected: (Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes : []).indexOf(modelData.key) !== -1
                        onClicked: root.toggleLauncherMode(modelData.key)
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Core Preset"
                    compact: true
                    onClicked: root.applyModePreset("core")
                }

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Minimal Preset"
                    compact: true
                    onClicked: root.applyModePreset("minimal")
                }

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Full Preset"
                    compact: true
                    onClicked: root.applyModePreset("full")
                }
            }

            SettingsSectionLabel {
                text: "MODE ORDER"
            }

            Repeater {
                model: root.orderedEnabledModes()
                delegate: SettingsListRow {
                    minimumHeight: root.compactMode ? 76 : 46

                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: Colors.surface
                        border.color: Colors.border
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.launcherModeMeta(modelData).icon
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeSmall
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXS

                        Text {
                            text: root.launcherModeMeta(modelData).label
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Colors.spacingS

                            SettingsActionButton {
                                label: "↑"
                                compact: true
                                enabled: index > 0
                                onClicked: root.moveMode(modelData, -1)
                            }

                            SettingsActionButton {
                                label: "↓"
                                compact: true
                                enabled: index < (root.orderedEnabledModes().length - 1)
                                onClicked: root.moveMode(modelData, 1)
                            }
                        }
                    }
                }
            }

            SettingsSectionLabel {
                text: "RESULT SCORING WEIGHTS"
            }

            SettingsSliderRow {
                label: "Name Weight"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreNameWeight
                unit: ""
                onMoved: v => Config.launcherScoreNameWeight = v
            }

            SettingsSliderRow {
                label: "Title Weight"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreTitleWeight
                unit: ""
                onMoved: v => Config.launcherScoreTitleWeight = v
            }

            SettingsSliderRow {
                label: "Exec/Class Weight"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreExecWeight
                unit: ""
                onMoved: v => Config.launcherScoreExecWeight = v
            }

            SettingsSliderRow {
                label: "Body Weight"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreBodyWeight
                unit: ""
                onMoved: v => Config.launcherScoreBodyWeight = v
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Reset Launcher Defaults"
                iconName: "󰑐"
                onClicked: root.resetLauncherDefaults()
            }
        }

        SettingsCard {
            title: "Control Center"
            iconName: "󰖲"
            description: "Visibility and width of control center modules."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Quick Links"
                    icon: "󰖩"
                    configKey: "controlCenterShowQuickLinks"
                }
                SettingsToggleRow {
                    label: "Media Widget"
                    icon: "󰝚"
                    configKey: "controlCenterShowMediaWidget"
                }
            }

            SettingsSliderRow {
                label: "Control Center Width"
                min: 320
                max: 460
                value: Config.controlCenterWidth
                onMoved: v => Config.controlCenterWidth = v
            }
        }
    }
}

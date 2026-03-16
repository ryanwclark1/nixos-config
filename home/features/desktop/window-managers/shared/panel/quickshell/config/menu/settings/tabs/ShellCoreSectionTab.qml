import QtQuick
import QtQuick.Layouts
import Quickshell
import "../SettingsReorder.js" as SettingsReorder
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property string sectionMode: "system"
    property string dragModeKey: ""
    property int dragModeTargetIndex: -1
    property string dragWebProviderKey: ""
    property int dragWebProviderTargetIndex: -1
    readonly property bool isSystemSection: sectionMode === "system"
    readonly property bool isLauncherSection: sectionMode === "launcher"
    readonly property bool isLauncherGeneralSection: sectionMode === "launcher-general" || isLauncherSection
    readonly property bool isLauncherSearchSection: sectionMode === "launcher-search"
    readonly property bool isLauncherWebSection: sectionMode === "launcher-web"
    readonly property bool isLauncherModesSection: sectionMode === "launcher-modes"
    readonly property bool isLauncherRuntimeSection: sectionMode === "launcher-runtime"
    readonly property bool isControlCenterSection: sectionMode === "control-center"
    readonly property string pageTitle: {
        if (isLauncherSearchSection)
            return "Launcher Search";
        if (isLauncherWebSection)
            return "Launcher Web";
        if (isLauncherModesSection)
            return "Launcher Modes";
        if (isLauncherRuntimeSection)
            return "Launcher Runtime";
        if (isLauncherGeneralSection)
            return "Launcher";
        if (isControlCenterSection)
            return "Control Center";
        return "Shell";
    }
    readonly property string pageIcon: {
        if (isLauncherSearchSection)
            return "󰍉";
        if (isLauncherWebSection)
            return "󰖟";
        if (isLauncherModesSection)
            return "󰌌";
        if (isLauncherRuntimeSection)
            return "󰔟";
        if (isLauncherGeneralSection)
            return "󰍉";
        if (isControlCenterSection)
            return "󰖲";
        return "󰒓";
    }
    readonly property var launcherModes: [
        {
            key: "drun",
            label: "Apps",
            icon: "󰀻"
        },
        {
            key: "window",
            label: "Windows",
            icon: "󱗼"
        },
        {
            key: "files",
            label: "Files",
            icon: "󰈔"
        },
        {
            key: "ai",
            label: "AI",
            icon: "󰚩"
        },
        {
            key: "clip",
            label: "Clipboard",
            icon: "󰅍"
        },
        {
            key: "emoji",
            label: "Emoji",
            icon: "󰞅"
        },
        {
            key: "calc",
            label: "Calc",
            icon: "󰪚"
        },
        {
            key: "web",
            label: "Web",
            icon: "󰖟"
        },
        {
            key: "run",
            label: "Run",
            icon: "󰆍"
        },
        {
            key: "system",
            label: "System",
            icon: "󰒓"
        },
        {
            key: "keybinds",
            label: "Keybinds",
            icon: "󰌌"
        },
        {
            key: "media",
            label: "Media",
            icon: "󰝚"
        },
        {
            key: "nixos",
            label: "NixOS",
            icon: ""
        },
        {
            key: "wallpapers",
            label: "Wallpapers",
            icon: "󰸉"
        },
        {
            key: "bookmarks",
            label: "Bookmarks",
            icon: "󰃀"
        }
    ]
    readonly property var launcherDefaultModes: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"]
    readonly property var webProviders: [
        {
            key: "duckduckgo",
            label: "DuckDuckGo",
            icon: "󰇥"
        },
        {
            key: "google",
            label: "Google",
            icon: "󰊯"
        },
        {
            key: "youtube",
            label: "YouTube",
            icon: "󰗃"
        },
        {
            key: "nixos",
            label: "NixOS Packages",
            icon: ""
        },
        {
            key: "github",
            label: "GitHub",
            icon: "󰊤"
        }
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
        return {
            key: providerKey,
            label: providerKey,
            icon: "󰖟"
        };
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

    function isLauncherModeSupported(modeKey) {
        if (modeKey === "window" && !CompositorAdapter.supportsWindowListing)
            return false;
        if (modeKey === "keybinds" && !CompositorAdapter.supportsHotkeysListing)
            return false;
        return true;
    }

    function supportedLauncherModes() {
        var out = [];
        for (var i = 0; i < launcherModes.length; i++) {
            var modeMeta = launcherModes[i];
            if (isLauncherModeSupported(modeMeta.key))
                out.push(modeMeta);
        }
        return out;
    }

    function supportedLauncherModeKeys() {
        return supportedLauncherModes().map(function (modeMeta) {
            return modeMeta.key;
        });
    }

    function defaultModeOptions() {
        return supportedLauncherModes().map(function (modeMeta) {
            return {
                value: modeMeta.key,
                label: modeMeta.label
            };
        });
    }

    function setEnabledModes(nextModes) {
        var allowed = {};
        var i;
        var availableModes = supportedLauncherModeKeys();
        for (i = 0; i < availableModes.length; i++)
            allowed[availableModes[i]] = true;

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
            presetModes = supportedLauncherModeKeys();
        else
            presetModes = ["drun", "window", "files", "ai", "clip", "system", "media"];

        setEnabledModes(presetModes);
        Config.launcherModeOrder = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : ["drun"];
    }

    function launcherModeMeta(modeKey) {
        for (var i = 0; i < launcherModes.length; i++) {
            if (launcherModes[i].key === modeKey)
                return launcherModes[i];
        }
        return {
            key: modeKey,
            label: modeKey,
            icon: "•"
        };
    }

    function orderedEnabledModes() {
        var enabled = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes : [];
        var order = Array.isArray(Config.launcherModeOrder) ? Config.launcherModeOrder : [];
        var out = [];
        var seen = {};
        var i;
        for (i = 0; i < order.length; i++) {
            var modeKey = String(order[i] || "");
            if (!isLauncherModeSupported(modeKey))
                continue;
            if (enabled.indexOf(modeKey) !== -1 && !seen[modeKey]) {
                out.push(modeKey);
                seen[modeKey] = true;
            }
        }
        for (i = 0; i < enabled.length; i++) {
            var extra = String(enabled[i] || "");
            if (!isLauncherModeSupported(extra))
                continue;
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

    function clearModeDragState() {
        dragModeKey = "";
        dragModeTargetIndex = -1;
    }

    function currentModeDropIndex(cardItem, rowIndex, listItem) {
        if (!cardItem || !listItem)
            return rowIndex;
        return SettingsReorder.targetIndexFromMappedY(cardItem.mapToItem(listItem, 0, cardItem.y).y, cardItem.height, listItem.spacing, orderedEnabledModes().length);
    }

    function moveDraggedMode(targetIndex) {
        var current = orderedEnabledModes();
        var from = current.indexOf(dragModeKey);
        if (from < 0)
            return false;

        var boundedTarget = Math.max(0, Math.min(current.length, targetIndex));
        if (from < boundedTarget)
            boundedTarget -= 1;
        if (boundedTarget === from) {
            clearModeDragState();
            return false;
        }

        var moved = current[from];
        current.splice(from, 1);
        current.splice(boundedTarget, 0, moved);
        Config.launcherModeOrder = current.slice();
        clearModeDragState();
        return true;
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

    function clearWebProviderDragState() {
        dragWebProviderKey = "";
        dragWebProviderTargetIndex = -1;
    }

    function currentWebProviderDropIndex(cardItem, rowIndex, listItem) {
        if (!cardItem || !listItem)
            return rowIndex;
        return SettingsReorder.targetIndexFromMappedY(cardItem.mapToItem(listItem, 0, cardItem.y).y, cardItem.height, listItem.spacing, orderedWebProviders().length);
    }

    function moveDraggedWebProvider(targetIndex) {
        var current = orderedWebProviders();
        var from = current.indexOf(dragWebProviderKey);
        if (from < 0)
            return false;

        var boundedTarget = Math.max(0, Math.min(current.length, targetIndex));
        if (from < boundedTarget)
            boundedTarget -= 1;
        if (boundedTarget === from) {
            clearWebProviderDragState();
            return false;
        }

        var moved = current[from];
        current.splice(from, 1);
        current.splice(boundedTarget, 0, moved);
        setWebProviderOrder(current);
        clearWebProviderDragState();
        return true;
    }

    function orderedControlCenterToggles() {
        return ControlCenterRegistry.orderedQuickToggleItems();
    }

    function orderedControlCenterPlugins() {
        return PluginService.visibleControlCenterPlugins.slice();
    }

    function moveOrderedValue(configKey, value, delta) {
        var current = [];
        if (configKey === "controlCenterToggleOrder")
            current = orderedControlCenterToggles().map(function (item) {
                return item.id;
            });
        else if (configKey === "controlCenterPluginOrder")
            current = orderedControlCenterPlugins().map(function (item) {
                return item.id;
            });

        var from = current.indexOf(value);
        if (from < 0)
            return;
        var to = Math.max(0, Math.min(current.length - 1, from + delta));
        if (to === from)
            return;

        current.splice(from, 1);
        current.splice(to, 0, value);
        Config[configKey] = current.slice();
    }

    function toggleHiddenListValue(configKey, value) {
        var next = Array.isArray(Config[configKey]) ? Config[configKey].slice() : [];
        var idx = next.indexOf(value);
        if (idx >= 0)
            next.splice(idx, 1);
        else
            next.push(value);
        Config[configKey] = next;
    }

    function resetLauncherDefaults() {
        Config.launcherDefaultMode = "drun";
        Config.launcherShowModeHints = true;
        Config.launcherShowHomeSections = true;
        Config.launcherDrunCategoryFiltersEnabled = true;
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
        var supportedDefaults = launcherDefaultModes.filter(function (modeKey) {
            return isLauncherModeSupported(modeKey);
        });
        if (supportedDefaults.length === 0)
            supportedDefaults = ["drun"];
        Config.launcherEnabledModes = supportedDefaults.slice();
        Config.launcherModeOrder = supportedDefaults.slice();
        Config.launcherScoreNameWeight = 1.0;
        Config.launcherScoreTitleWeight = 0.92;
        Config.launcherScoreExecWeight = 0.88;
        Config.launcherScoreBodyWeight = 0.75;
        Config.launcherScoreCategoryWeight = 0.7;
    }

    Component.onCompleted: {
        var currentModes = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : launcherDefaultModes.slice();
        setEnabledModes(currentModes);
        if (!isLauncherModeSupported(Config.launcherDefaultMode)) {
            var ordered = orderedEnabledModes();
            Config.launcherDefaultMode = ordered.length > 0 ? ordered[0] : "drun";
        }
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: root.pageTitle
        iconName: root.pageIcon

        SettingsCard {
            visible: root.isSystemSection
            title: "Shell"
            iconName: "󰒓"
            description: "Core shell visuals and transient notification behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

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
                icon: "󰂚"
                min: 280
                max: 520
                value: Config.notifWidth
                onMoved: v => Config.notifWidth = v
            }

            SettingsSliderRow {
                label: "Popup Duration"
                icon: "󰔛"
                min: 2000
                max: 10000
                step: 500
                value: Config.popupTimer
                unit: "ms"
                onMoved: v => Config.popupTimer = v
            }
        }

        SettingsCard {
            visible: root.isLauncherGeneralSection
            title: "Launcher Behavior"
            iconName: "󰍉"
            description: "Choose the default launcher behavior and opening mode."

            SettingsInfoCallout {
                iconName: "󰍉"
                title: "Dedicated launcher settings"
                body: "Launcher controls now live under their own settings section so search, modes, home layout, and diagnostics are easier to tune without digging through Shell settings."
            }

            SettingsModeRow {
                label: "Default Mode"
                icon: "󰍉"
                currentValue: Config.launcherDefaultMode
                options: root.defaultModeOptions()
                onModeSelected: modeValue => Config.launcherDefaultMode = modeValue
            }

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Show Mode Hints"
                    icon: "󰌌"
                    configKey: "launcherShowModeHints"
                }
                SettingsToggleRow {
                    label: "Keep Query on Mode Switch"
                    icon: "󰍉"
                    configKey: "launcherKeepSearchOnModeSwitch"
                }
                SettingsModeRow {
                    label: "Tab Behavior"
                    icon: "󰌌"
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
            }
        }

        SettingsCard {
            visible: root.isLauncherGeneralSection
            title: "Home Layout"
            iconName: "󰆍"
            description: "Control what the launcher home view shows before a search is entered."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Show Home Sections"
                    icon: "󰆍"
                    configKey: "launcherShowHomeSections"
                }
                SettingsToggleRow {
                    label: "App Category Filters"
                    icon: "󰍉"
                    configKey: "launcherDrunCategoryFiltersEnabled"
                }
            }

            SettingsSliderRow {
                label: "Recents History Limit"
                icon: "󰑓"
                min: 4
                max: 40
                step: 1
                value: Config.launcherRecentsLimit
                unit: ""
                onMoved: v => Config.launcherRecentsLimit = v
            }

            SettingsSliderRow {
                label: "Recent Apps on Home"
                icon: "󰍉"
                min: 1
                max: 20
                step: 1
                value: Config.launcherRecentAppsLimit
                unit: ""
                onMoved: v => Config.launcherRecentAppsLimit = v
            }

            SettingsSliderRow {
                label: "Suggestions on Home"
                icon: "󰆒"
                min: 0
                max: 12
                step: 1
                value: Config.launcherSuggestionsLimit
                unit: ""
                onMoved: v => Config.launcherSuggestionsLimit = v
            }
        }

        SettingsCard {
            visible: root.isLauncherSearchSection
            title: "Search Limits"
            iconName: "󰍉"
            description: "Tune search breadth, file query thresholds, and response timing."

            SettingsSliderRow {
                label: "Max Results"
                icon: "󰍉"
                min: 20
                max: 200
                step: 5
                value: Config.launcherMaxResults
                onMoved: v => Config.launcherMaxResults = v
            }

            SettingsSliderRow {
                label: "File Query Min Length"
                icon: "󰈔"
                min: 1
                max: 6
                value: Config.launcherFileMinQueryLength
                onMoved: v => Config.launcherFileMinQueryLength = v
            }

            SettingsSliderRow {
                label: "File Search Max Results"
                icon: "󰈔"
                min: 20
                max: 300
                step: 10
                value: Config.launcherFileMaxResults
                onMoved: v => Config.launcherFileMaxResults = v
            }

            SettingsSliderRow {
                label: "Cache TTL"
                icon: "󰔟"
                min: 30
                max: 1800
                step: 30
                value: Config.launcherCacheTtlSec
                unit: "s"
                onMoved: v => Config.launcherCacheTtlSec = v
            }

            SettingsSliderRow {
                label: "Search Debounce"
                icon: "󰔛"
                min: 0
                max: 250
                step: 5
                value: Config.launcherSearchDebounceMs
                unit: "ms"
                onMoved: v => Config.launcherSearchDebounceMs = v
            }

            SettingsSliderRow {
                label: "File Search Debounce"
                icon: "󰔛"
                min: 50
                max: 1200
                step: 10
                value: Config.launcherFileSearchDebounceMs
                unit: "ms"
                onMoved: v => Config.launcherFileSearchDebounceMs = v
            }
        }

        SettingsCard {
            visible: root.isLauncherSearchSection
            title: "Result Scoring"
            iconName: "󰀻"
            description: "Adjust how launcher results are ranked across labels, commands, and metadata."

            SettingsSectionLabel {
                text: "RESULT SCORING WEIGHTS"
            }

            SettingsSliderRow {
                label: "Name Weight"
                icon: "󰌌"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreNameWeight
                unit: ""
                onMoved: v => Config.launcherScoreNameWeight = v
            }

            SettingsSliderRow {
                label: "Title Weight"
                icon: "󰍉"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreTitleWeight
                unit: ""
                onMoved: v => Config.launcherScoreTitleWeight = v
            }

            SettingsSliderRow {
                label: "Exec/Class Weight"
                icon: "󰆍"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreExecWeight
                unit: ""
                onMoved: v => Config.launcherScoreExecWeight = v
            }

            SettingsSliderRow {
                label: "Body Weight"
                icon: "󰈔"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreBodyWeight
                unit: ""
                onMoved: v => Config.launcherScoreBodyWeight = v
            }

            SettingsSliderRow {
                label: "Category/Keywords Weight"
                icon: "󰀻"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreCategoryWeight
                unit: ""
                onMoved: v => Config.launcherScoreCategoryWeight = v
            }
        }

        SettingsCard {
            visible: root.isLauncherWebSection
            title: "Web Search Behavior"
            iconName: "󰖟"
            description: "Web-mode defaults and keyboard behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

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
        }

        SettingsCard {
            visible: root.isLauncherWebSection
            title: "Web Providers"
            iconName: "󰛢"
            description: "Enable providers and control the order shown in web mode."

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

            Column {
                id: webProviderOrderList
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root.orderedWebProviders()
                    delegate: Item {
                        id: webProviderRow
                        width: parent ? parent.width : 0
                        implicitHeight: webProviderCard.implicitHeight + (webDropBeforeIndicator.visible ? webDropBeforeIndicator.height + Colors.spacingXS : 0)
                        height: implicitHeight
                        required property int index
                        required property var modelData
                        readonly property bool dropBeforeActive: root.dragWebProviderKey !== "" && root.dragWebProviderTargetIndex === index

                        Rectangle {
                            id: webDropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            visible: webProviderRow.dropBeforeActive
                            height: 10
                            radius: Colors.radiusXXS
                            color: Colors.withAlpha(Colors.primary, 0.22)
                            border.color: Colors.primary
                            border.width: 1
                        }

                        SettingsListRow {
                            id: webProviderCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: webDropBeforeIndicator.bottom
                                topMargin: webDropBeforeIndicator.visible ? Colors.spacingXS : 0
                            }
                            minimumHeight: root.compactMode ? 76 : 44
                            active: webDragHandle.dragActive
                            opacity: webDragHandle.dragActive ? 0.74 : 1.0
                            onYChanged: {
                                if (webDragHandle.dragActive)
                                    root.dragWebProviderTargetIndex = root.currentWebProviderDropIndex(webProviderCard, webProviderRow.index, webProviderOrderList);
                            }

                            Behavior on y {
                                enabled: !webDragHandle.dragActive

                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SettingsDragHandle {
                                id: webDragHandle
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                                dragTarget: webProviderCard
                                onPressedChanged: {
                                    root.dragWebProviderKey = webProviderRow.modelData;
                                    root.dragWebProviderTargetIndex = webProviderRow.index;
                                }
                                onReleased: function (wasDragging) {
                                    var targetIndex = root.dragWebProviderTargetIndex;
                                    if (wasDragging)
                                        targetIndex = root.currentWebProviderDropIndex(webProviderCard, webProviderRow.index, webProviderOrderList);
                                    webProviderCard.x = 0;
                                    webProviderCard.y = 0;
                                    if (wasDragging) {
                                        if (!root.moveDraggedWebProvider(targetIndex))
                                            root.clearWebProviderDragState();
                                    } else {
                                        root.clearWebProviderDragState();
                                    }
                                }
                            }

                            Rectangle {
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                                border.color: Colors.border
                                border.width: 1
                                color: Colors.surface
                                implicitHeight: 24
                                implicitWidth: 24
                                radius: Colors.radiusCard

                                Text {
                                    anchors.centerIn: parent
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                    text: {
                                        for (var i = 0; i < root.webProviders.length; ++i) {
                                            if (root.webProviders[i].key === webProviderRow.modelData)
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
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
                                    elide: root.compactMode ? Text.ElideNone : Text.ElideRight
                                    text: {
                                        for (var i = 0; i < root.webProviders.length; ++i) {
                                            if (root.webProviders[i].key === webProviderRow.modelData)
                                                return root.webProviders[i].label;
                                        }
                                        return webProviderRow.modelData;
                                    }
                                }

                                Text {
                                    text: "Drag to reorder, or use the arrow buttons."
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: parent.width
                                    spacing: Colors.spacingS

                                    SettingsActionButton {
                                        compact: true
                                        enabled: webProviderRow.index > 0
                                        label: "↑"
                                        onClicked: root.moveWebProvider(webProviderRow.modelData, -1)
                                    }

                                    SettingsActionButton {
                                        compact: true
                                        enabled: webProviderRow.index < (root.orderedWebProviders().length - 1)
                                        label: "↓"
                                        onClicked: root.moveWebProvider(webProviderRow.modelData, 1)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent ? parent.width : 0
                    height: 12
                    radius: Colors.radiusXXS
                    visible: root.dragWebProviderKey !== "" && root.dragWebProviderTargetIndex === root.orderedWebProviders().length
                    color: Colors.withAlpha(Colors.primary, 0.22)
                    border.color: Colors.primary
                    border.width: 1
                }

                Text {
                    width: parent ? parent.width : 0
                    visible: root.dragWebProviderKey !== "" && root.dragWebProviderTargetIndex === root.orderedWebProviders().length
                    text: "Drop at end of provider order"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }
            }
        }

        SettingsCard {
            visible: root.isLauncherWebSection
            title: "Web Aliases"
            iconName: "󰖟"
            description: "Customize short prefixes for each provider."

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
        }

        SettingsCard {
            visible: root.isLauncherModesSection
            title: "Launcher Modes"
            iconName: "󰌌"
            description: "Enable or disable launcher modes and apply preset sets."

            SettingsSectionLabel {
                text: "ENABLED MODES"
            }

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: root.supportedLauncherModes()
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
        }

        SettingsCard {
            visible: root.isLauncherModesSection
            title: "Mode Order"
            iconName: "󰑖"
            description: "Control the order the enabled modes appear in."

            SettingsSectionLabel {
                text: "MODE ORDER"
            }

            Column {
                id: modeOrderList
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root.orderedEnabledModes()
                    delegate: Item {
                        id: modeRow
                        width: parent ? parent.width : 0
                        implicitHeight: modeCard.implicitHeight + (dropBeforeIndicator.visible ? dropBeforeIndicator.height + Colors.spacingXS : 0)
                        height: implicitHeight
                        required property int index
                        required property var modelData
                        readonly property bool dropBeforeActive: root.dragModeKey !== "" && root.dragModeTargetIndex === index

                        Rectangle {
                            id: dropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            visible: modeRow.dropBeforeActive
                            height: 10
                            radius: Colors.radiusXXS
                            color: Colors.withAlpha(Colors.primary, 0.22)
                            border.color: Colors.primary
                            border.width: 1
                        }

                        SettingsListRow {
                            id: modeCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: dropBeforeIndicator.bottom
                                topMargin: dropBeforeIndicator.visible ? Colors.spacingXS : 0
                            }
                            minimumHeight: root.compactMode ? 76 : 46
                            active: dragHandle.dragActive
                            opacity: dragHandle.dragActive ? 0.74 : 1.0
                            onYChanged: {
                                if (dragHandle.dragActive)
                                    root.dragModeTargetIndex = root.currentModeDropIndex(modeCard, modeRow.index, modeOrderList);
                            }

                            Behavior on y {
                                enabled: !dragHandle.dragActive

                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SettingsDragHandle {
                                id: dragHandle
                                Layout.alignment: Qt.AlignTop
                                dragTarget: modeCard
                                onPressedChanged: {
                                    root.dragModeKey = modeRow.modelData;
                                    root.dragModeTargetIndex = modeRow.index;
                                }
                                onReleased: function (wasDragging) {
                                    var targetIndex = root.dragModeTargetIndex;
                                    if (wasDragging)
                                        targetIndex = root.currentModeDropIndex(modeCard, modeRow.index, modeOrderList);
                                    modeCard.x = 0;
                                    modeCard.y = 0;
                                    if (wasDragging) {
                                        if (!root.moveDraggedMode(targetIndex))
                                            root.clearModeDragState();
                                    } else {
                                        root.clearModeDragState();
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: Colors.radiusCard
                                color: Colors.surface
                                border.color: Colors.border
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.launcherModeMeta(modeRow.modelData).icon
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXS

                                Text {
                                    text: root.launcherModeMeta(modeRow.modelData).label
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
                                    elide: root.compactMode ? Text.ElideNone : Text.ElideRight
                                }

                                Text {
                                    text: "Drag to reorder, or use the arrow buttons."
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: parent.width
                                    spacing: Colors.spacingS

                                    SettingsActionButton {
                                        label: "↑"
                                        compact: true
                                        enabled: modeRow.index > 0
                                        onClicked: root.moveMode(modeRow.modelData, -1)
                                    }

                                    SettingsActionButton {
                                        label: "↓"
                                        compact: true
                                        enabled: modeRow.index < (root.orderedEnabledModes().length - 1)
                                        onClicked: root.moveMode(modeRow.modelData, 1)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent ? parent.width : 0
                    height: 12
                    radius: Colors.radiusXXS
                    visible: root.dragModeKey !== "" && root.dragModeTargetIndex === root.orderedEnabledModes().length
                    color: Colors.withAlpha(Colors.primary, 0.22)
                    border.color: Colors.primary
                    border.width: 1
                }

                Text {
                    width: parent ? parent.width : 0
                    visible: root.dragModeKey !== "" && root.dragModeTargetIndex === root.orderedEnabledModes().length
                    text: "Drop at end of mode order"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }
            }
        }

        SettingsCard {
            visible: root.isLauncherRuntimeSection
            title: "Runtime Behavior"
            iconName: "󰔟"
            description: "Preload policy and runtime metric visibility."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Background Preload"
                    icon: "󰔟"
                    configKey: "launcherEnablePreload"
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
            }

            SettingsSliderRow {
                label: "Preload Failure Threshold"
                icon: "󰔟"
                min: 1
                max: 10
                step: 1
                value: Config.launcherPreloadFailureThreshold
                unit: ""
                onMoved: v => Config.launcherPreloadFailureThreshold = v
            }

            SettingsSliderRow {
                label: "Preload Backoff"
                icon: "󰔛"
                min: 10
                max: 900
                step: 10
                value: Config.launcherPreloadFailureBackoffSec
                unit: "s"
                onMoved: v => Config.launcherPreloadFailureBackoffSec = v
            }
        }

        SettingsCard {
            visible: root.isLauncherRuntimeSection
            title: "Diagnostics & Recovery"
            iconName: "󰑐"
            description: "Runtime reset actions and launcher maintenance controls."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Reset Runtime Metrics"
                    iconName: "󰑐"
                    compact: true
                    onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "clearMetrics"])
                }

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Re-detect Files Backend"
                    iconName: "󰑓"
                    compact: true
                    onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "redetectFilesBackend"])
                }
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Launcher Diagnostic Reset"
                iconName: "󰔟"
                compact: true
                onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "diagnosticReset"])
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Reset Launcher Defaults"
                iconName: "󰑐"
                onClicked: root.resetLauncherDefaults()
            }
        }

        SettingsCard {
            visible: root.isControlCenterSection
            title: "Control Center"
            iconName: "󰖲"
            description: "Visibility and width of control center modules."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

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
                icon: "󰖲"
                min: Config.controlCenterWidthMin
                max: Config.controlCenterWidthMax
                value: Config.controlCenterWidth
                onMoved: v => Config.controlCenterWidth = v
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: "Quick Toggles"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Control toggle visibility and order in the Control Center grid."
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.orderedControlCenterToggles()

                    delegate: SettingsListRow {
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenToggles) && Config.controlCenterHiddenToggles.indexOf(modelData.id) !== -1
                        readonly property int rowIndex: root.orderedControlCenterToggles().findIndex(function (item) {
                            return item.id === modelData.id;
                        })
                        minimumHeight: root.compactMode ? 72 : 60
                        active: !hidden

                        Text {
                            text: modelData.icon || "󰖲"
                            color: hidden ? Colors.textDisabled : Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXXS

                            Text {
                                text: modelData.label || modelData.id
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: hidden ? "Hidden" : "Visible"
                                color: hidden ? Colors.textDisabled : Colors.success
                                font.pixelSize: Colors.fontSizeXS
                            }
                        }

                        RowLayout {
                            spacing: Colors.spacingS

                            SettingsActionButton {
                                compact: true
                                iconName: "󰁍"
                                label: "Up"
                                enabled: rowIndex > 0
                                onClicked: root.moveOrderedValue("controlCenterToggleOrder", modelData.id, -1)
                            }

                            SettingsActionButton {
                                compact: true
                                iconName: "󰁔"
                                label: "Down"
                                enabled: rowIndex >= 0 && rowIndex < root.orderedControlCenterToggles().length - 1
                                onClicked: root.moveOrderedValue("controlCenterToggleOrder", modelData.id, 1)
                            }

                            SharedWidgets.ToggleSwitch {
                                checked: !hidden
                                onToggled: root.toggleHiddenListValue("controlCenterHiddenToggles", modelData.id)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS
                visible: PluginService.controlCenterPlugins.length > 0

                Text {
                    text: "Plugin Widgets"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Manage third-party widgets exposed inside the Control Center."
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.orderedControlCenterPlugins()

                    delegate: SettingsListRow {
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenPlugins) && Config.controlCenterHiddenPlugins.indexOf(modelData.id) !== -1
                        readonly property int rowIndex: root.orderedControlCenterPlugins().findIndex(function (item) {
                            return item.id === modelData.id;
                        })
                        minimumHeight: root.compactMode ? 80 : 64
                        active: !hidden

                        Rectangle {
                            width: root.compactMode ? 30 : 34
                            height: width
                            radius: Colors.radiusSmall
                            color: hidden ? Colors.withAlpha(Colors.text, 0.06) : Colors.withAlpha(Colors.primary, 0.12)

                            Text {
                                anchors.centerIn: parent
                                text: "󰏗"
                                color: hidden ? Colors.textDisabled : Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeMedium
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXXS

                            Text {
                                text: modelData.name || modelData.id
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: hidden ? "Hidden" : "Visible"
                                color: hidden ? Colors.textDisabled : Colors.success
                                font.pixelSize: Colors.fontSizeXS
                            }
                        }

                        RowLayout {
                            spacing: Colors.spacingS

                            SettingsActionButton {
                                compact: true
                                iconName: "󰁍"
                                label: "Up"
                                enabled: rowIndex > 0
                                onClicked: root.moveOrderedValue("controlCenterPluginOrder", modelData.id, -1)
                            }

                            SettingsActionButton {
                                compact: true
                                iconName: "󰁔"
                                label: "Down"
                                enabled: rowIndex >= 0 && rowIndex < root.orderedControlCenterPlugins().length - 1
                                onClicked: root.moveOrderedValue("controlCenterPluginOrder", modelData.id, 1)
                            }

                            SharedWidgets.ToggleSwitch {
                                checked: !hidden
                                onToggled: root.toggleHiddenListValue("controlCenterHiddenPlugins", modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

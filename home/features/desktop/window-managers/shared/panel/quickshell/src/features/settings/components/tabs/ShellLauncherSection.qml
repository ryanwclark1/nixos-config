import QtQuick
import QtQuick.Layouts
import Quickshell
import "ShellCoreHelpers.js" as Helpers
import "../../../../launcher/LauncherModeData.js" as ModeData
import "../../../../services"
import ".."

Item {
    id: root
    required property bool compactMode
    required property var settingsRoot
    required property string sectionMode

    property string newEngineKey: ""
    property string newEngineName: ""
    property string newEngineUrl: ""
    property string newEngineIcon: ""
    readonly property string dragWebProviderKey: webProviderReorderState.sourceItemId
    readonly property int dragWebProviderTargetIndex: webProviderReorderState.targetIndex

    // Section visibility
    readonly property bool isLauncherSection: sectionMode === "launcher"
    readonly property bool isLauncherGeneralSection: sectionMode === "launcher-general" || isLauncherSection
    readonly property bool isLauncherSearchSection: sectionMode === "launcher-search"
    readonly property bool isLauncherWebSection: sectionMode === "launcher-web"
    readonly property bool isLauncherModesSection: sectionMode === "launcher-modes"
    readonly property bool isLauncherRuntimeSection: sectionMode === "launcher-runtime"
    readonly property bool launcherFilePreviewToggleAvailable: Quickshell.env("QS_ENABLE_UNSTABLE_LAUNCHER_FILE_PREVIEW") === "1"
    readonly property int launcherWideFieldMinimumWidth: 420
    readonly property string currentLauncherTabId: isLauncherSearchSection ? "launcher-search"
        : (isLauncherWebSection ? "launcher-web"
        : (isLauncherModesSection ? "launcher-modes"
        : (isLauncherRuntimeSection ? "launcher-runtime" : "launcher")))
    readonly property var launcherHeroMeta: ({
            "launcher": {
                label: "General",
                icon: "search-visual.svg",
                description: "Tune the launcher shell, default entry mode, and home-stage behavior.",
                chips: ["Default mode", "Home stage", "Hints"]
            },
            "launcher-search": {
                label: "Search",
                icon: "search-visual.svg",
                description: "Adjust result breadth, debounce timing, and ranking signals for faster search.",
                chips: ["Result mix", "Debounce", "Ranking"]
            },
            "launcher-web": {
                label: "Web",
                icon: "globe-search.svg",
                description: "Manage providers, aliases, custom engines, and web-specific shortcuts.",
                chips: ["Providers", "Aliases", "Custom engines"]
            },
            "launcher-modes": {
                label: "Modes",
                icon: "keyboard.svg",
                description: "Control pinned and advanced mode layout, presets, and drag ordering.",
                chips: ["Primary", "Advanced", "Presets"]
            },
            "launcher-runtime": {
                label: "Runtime",
                icon: "timer.svg",
                description: "Configure preload, diagnostics, metrics, and recovery behavior.",
                chips: ["Preload", "Metrics", "Recovery"]
            }
        })[currentLauncherTabId] || ({
            label: "General",
            icon: "search-visual.svg",
            description: "Tune the launcher runtime, search flow, and mode surfaces from one place.",
            chips: ["Launcher"]
        })
    readonly property var launcherHeroTabs: [
        { id: "launcher", label: "General", icon: "search-visual.svg" },
        { id: "launcher-search", label: "Search", icon: "search-visual.svg" },
        { id: "launcher-web", label: "Web", icon: "globe-search.svg" },
        { id: "launcher-modes", label: "Modes", icon: "keyboard.svg" },
        { id: "launcher-runtime", label: "Runtime", icon: "timer.svg" }
    ]

    // Static data arrays
    readonly property var launcherModes: ModeData.allKnownModes.map(function(modeKey) {
        var info = ModeData.modeInfo(modeKey);
        return {
            key: modeKey,
            label: info.label,
            icon: ModeData.modeIcons[modeKey] || "•"
        };
    })
    readonly property var launcherDefaultModes: ModeData.allKnownModes.slice()
    readonly property var webProviders: {
        var builtIn = [
            { key: "duckduckgo", label: "DuckDuckGo", icon: "globe-search.svg" },
            { key: "google", label: "Google", icon: "globe-search.svg" },
            { key: "youtube", label: "YouTube", icon: "globe-search.svg" },
            { key: "nixos", label: "NixOS Packages", icon: "brands/nixos-symbolic.svg" },
            { key: "github", label: "GitHub", icon: "brands/github-symbolic.svg" },
            { key: "brave", label: "Brave Search", icon: "globe-search.svg" },
            { key: "bing", label: "Bing", icon: "globe-search.svg" },
            { key: "kagi", label: "Kagi", icon: "globe-search.svg" },
            { key: "stackoverflow", label: "Stack Overflow", icon: "globe-search.svg" },
            { key: "npm", label: "npm", icon: "globe-search.svg" },
            { key: "pypi", label: "PyPI", icon: "globe-search.svg" },
            { key: "crates", label: "crates.io", icon: "globe-search.svg" },
            { key: "mdn", label: "MDN Web Docs", icon: "globe-search.svg" },
            { key: "archwiki", label: "Arch Wiki", icon: "brands/arch-symbolic.svg" },
            { key: "aur", label: "AUR", icon: "brands/arch-symbolic.svg" },
            { key: "nixopts", label: "NixOS Options", icon: "brands/nixos-symbolic.svg" },
            { key: "reddit", label: "Reddit", icon: "globe-search.svg" },
            { key: "twitter", label: "Twitter/X", icon: "globe-search.svg" },
            { key: "linkedin", label: "LinkedIn", icon: "globe-search.svg" },
            { key: "wikipedia", label: "Wikipedia", icon: "globe-search.svg" },
            { key: "translate", label: "Google Translate", icon: "globe-search.svg" },
            { key: "imdb", label: "IMDb", icon: "globe-search.svg" },
            { key: "amazon", label: "Amazon", icon: "globe-search.svg" },
            { key: "ebay", label: "eBay", icon: "globe-search.svg" },
            { key: "maps", label: "Google Maps", icon: "compass.svg" },
            { key: "images", label: "Google Images", icon: "image.svg" }
        ];
        // Append custom engines
        var customs = Config.launcherWebCustomEngines;
        if (Array.isArray(customs)) {
            for (var i = 0; i < customs.length; ++i) {
                var c = customs[i];
                if (c && c.key && c.name)
                    builtIn.push({ key: c.key, label: c.name, icon: c.icon || "globe-search.svg", isCustom: true });
            }
        }
        return builtIn;
    }
    readonly property var webProviderDefaultOrder: ["duckduckgo", "google", "youtube", "nixos", "github"]
    readonly property var webAliasDefaults: ({
            "duckduckgo": ["d", "ddg"],
            "google": ["g"],
            "youtube": ["yt"],
            "nixos": ["nix", "np"],
            "github": ["gh"],
            "brave": ["br"],
            "bing": ["b"],
            "kagi": ["k"],
            "stackoverflow": ["so", "stack"],
            "npm": ["n"],
            "pypi": ["pip", "py"],
            "crates": ["cr", "cargo"],
            "mdn": ["md"],
            "archwiki": ["aw", "arch"],
            "aur": ["au"],
            "nixopts": ["no", "opts"],
            "reddit": ["r"],
            "twitter": ["tw", "x"],
            "linkedin": ["li"],
            "wikipedia": ["w", "wiki"],
            "translate": ["tr"],
            "imdb": ["im"],
            "amazon": ["az"],
            "ebay": ["eb"],
            "maps": ["map"],
            "images": ["img"]
        })

    SettingsReorderState {
        id: webProviderReorderState
    }

    SettingsReorderState {
        id: primaryModeReorderState
    }

    SettingsReorderState {
        id: advancedModeReorderState
    }

    // Thin wrappers so UI bindings stay readable
    function defaultModeOptions() {
        return Helpers.defaultModeOptions(launcherModes, CompositorAdapter);
    }
    function supportedLauncherModes() {
        return Helpers.supportedLauncherModes(launcherModes, CompositorAdapter);
    }
    function orderedEnabledModes() {
        return Helpers.orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    }
    function orderedPrimaryModes() {
        return Helpers.orderedPrimaryModes(Config, CompositorAdapter, launcherModes);
    }
    function orderedAdvancedModes() {
        return Helpers.orderedAdvancedModes(Config, CompositorAdapter, launcherModes);
    }
    function disabledLauncherModes() {
        return Helpers.disabledLauncherModes(Config, CompositorAdapter, launcherModes);
    }
    function orderedWebProviders() {
        return Helpers.orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    }
    function webProviderMeta(providerKey) {
        return Helpers.webProviderMeta(webProviders, providerKey);
    }
    function webAliasString(providerKey) {
        return Helpers.webAliasString(Config, providerKey);
    }
    function setWebAliasString(providerKey, textValue) {
        Helpers.setWebAliasString(Config, providerKey, textValue);
    }
    function toggleLauncherMode(modeKey) {
        Helpers.toggleLauncherMode(Config, CompositorAdapter, launcherModes, modeKey);
    }
    function applyModePreset(preset) {
        Helpers.applyModePreset(Config, CompositorAdapter, launcherModes, preset);
    }
    function launcherModeMeta(modeKey) {
        return Helpers.launcherModeMeta(launcherModes, modeKey);
    }
    function moveMode(modeKey, delta) {
        Helpers.moveMode(Config, CompositorAdapter, launcherModes, modeKey, delta);
    }
    function movePrimaryMode(modeKey, delta) {
        Helpers.movePrimaryMode(Config, CompositorAdapter, launcherModes, modeKey, delta);
    }
    function moveAdvancedMode(modeKey, delta) {
        Helpers.moveAdvancedMode(Config, CompositorAdapter, launcherModes, modeKey, delta);
    }
    function promoteLauncherMode(modeKey) {
        Helpers.promoteLauncherMode(Config, CompositorAdapter, launcherModes, modeKey);
    }
    function enableLauncherMode(modeKey, asPrimary) {
        Helpers.enableLauncherMode(Config, CompositorAdapter, launcherModes, modeKey, asPrimary);
    }
    function demoteLauncherMode(modeKey) {
        Helpers.demoteLauncherMode(Config, CompositorAdapter, launcherModes, modeKey);
    }
    function disableLauncherMode(modeKey) {
        Helpers.disableLauncherMode(Config, CompositorAdapter, launcherModes, modeKey);
    }
    function clearModeDragState() {
        Helpers.clearModeDragState(primaryModeReorderState);
        Helpers.clearModeDragState(advancedModeReorderState);
    }
    function currentModeDropIndex(cardItem, rowIndex, listItem, count) {
        return Helpers.currentModeDropIndex(cardItem, rowIndex, listItem, count);
    }
    function beginPrimaryModeDrag(modeKey, index) {
        primaryModeReorderState.begin("launcher-primary-mode", modeKey, index);
    }
    function beginAdvancedModeDrag(modeKey, index) {
        advancedModeReorderState.begin("launcher-advanced-mode", modeKey, index);
    }
    function moveDraggedPrimaryMode(targetIndex) {
        return Helpers.moveDraggedPrimaryMode(Config, CompositorAdapter, launcherModes, primaryModeReorderState, targetIndex);
    }
    function moveDraggedAdvancedMode(targetIndex) {
        return Helpers.moveDraggedAdvancedMode(Config, CompositorAdapter, launcherModes, advancedModeReorderState, targetIndex);
    }
    function beginWebProviderDrag(providerKey, index) {
        webProviderReorderState.begin("launcher-web-provider", providerKey, index);
    }
    function toggleWebProvider(providerKey) {
        Helpers.toggleWebProvider(Config, webProviders, webProviderDefaultOrder, providerKey);
    }
    function moveWebProvider(providerKey, delta) {
        Helpers.moveWebProvider(Config, webProviders, webProviderDefaultOrder, providerKey, delta);
    }
    function clearWebProviderDragState() {
        Helpers.clearWebProviderDragState(webProviderReorderState);
    }
    function currentWebProviderDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentWebProviderDropIndex(cardItem, rowIndex, listItem, Config, webProviders, webProviderDefaultOrder);
    }
    function moveDraggedWebProvider(targetIndex) {
        return Helpers.moveDraggedWebProvider(Config, webProviders, webProviderDefaultOrder, webProviderReorderState, targetIndex);
    }
    function resetLauncherDefaults() {
        Helpers.resetLauncherDefaults(Config, webAliasDefaults, webProviderDefaultOrder, launcherDefaultModes, CompositorAdapter, launcherModes);
    }
    function selectLauncherTab(tabId) {
        if (!root.settingsRoot)
            return;
        if (root.settingsRoot.clearSettingHighlight)
            root.settingsRoot.clearSettingHighlight();
        if (root.settingsRoot.setCurrentTab)
            root.settingsRoot.setCurrentTab(tabId);
    }

    Component.onCompleted: {
        var currentModes = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : launcherDefaultModes.slice();
        Helpers.setEnabledModes(Config, CompositorAdapter, launcherModes, currentModes);
        if (!Helpers.isLauncherModeSupported(CompositorAdapter, Config.launcherDefaultMode)) {
            var ordered = orderedEnabledModes();
            Config.launcherDefaultMode = ordered.length > 0 ? ordered[0] : "drun";
        }
    }

    readonly property bool showLauncherHero: root.isLauncherSection
        || root.isLauncherGeneralSection
        || root.isLauncherSearchSection
        || root.isLauncherWebSection
        || root.isLauncherModesSection
        || root.isLauncherRuntimeSection

    implicitHeight: launcherColumn.implicitHeight
    implicitWidth: launcherColumn.implicitWidth

    ColumnLayout {
        id: launcherColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacingL

        LauncherSettingsHero {
            visible: root.showLauncherHero
            Layout.fillWidth: true
            compactMode: root.compactMode
            currentLauncherTabId: root.currentLauncherTabId
            launcherHeroMeta: root.launcherHeroMeta
            launcherHeroTabs: root.launcherHeroTabs
            selectTabFn: root.selectLauncherTab
        }

        LauncherGeneralSection {
            visible: root.isLauncherGeneralSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            launcherWideFieldMinimumWidth: root.launcherWideFieldMinimumWidth
            defaultModeOptionsFn: root.defaultModeOptions
        }

        LauncherSearchSection {
            visible: root.isLauncherSearchSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            launcherFilePreviewToggleAvailable: root.launcherFilePreviewToggleAvailable
            launcherWideFieldMinimumWidth: root.launcherWideFieldMinimumWidth
        }

        LauncherWebSection {
            visible: root.isLauncherWebSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            webProviders: root.webProviders
            orderedWebProvidersFn: root.orderedWebProviders
            toggleWebProviderFn: root.toggleWebProvider
            webProviderReorderState: webProviderReorderState
            dragWebProviderKey: root.dragWebProviderKey
            dragWebProviderTargetIndex: root.dragWebProviderTargetIndex
            beginWebProviderDragFn: root.beginWebProviderDrag
            moveDraggedWebProviderFn: root.moveDraggedWebProvider
            clearWebProviderDragStateFn: root.clearWebProviderDragState
            currentWebProviderDropIndexFn: root.currentWebProviderDropIndex
            moveWebProviderFn: root.moveWebProvider
            webProviderMetaFn: root.webProviderMeta
            webAliasStringFn: root.webAliasString
            setWebAliasStringFn: root.setWebAliasString
            newEngineKey: root.newEngineKey
            newEngineName: root.newEngineName
            newEngineUrl: root.newEngineUrl
            newEngineIcon: root.newEngineIcon
            setNewEngineKeyFn: function(value) {
                root.newEngineKey = value;
            }
            setNewEngineNameFn: function(value) {
                root.newEngineName = value;
            }
            setNewEngineUrlFn: function(value) {
                root.newEngineUrl = value;
            }
            setNewEngineIconFn: function(value) {
                root.newEngineIcon = value;
            }
        }

        LauncherModesSection {
            visible: root.isLauncherModesSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            orderedPrimaryModesFn: root.orderedPrimaryModes
            orderedAdvancedModesFn: root.orderedAdvancedModes
            disabledLauncherModesFn: root.disabledLauncherModes
            applyModePresetFn: root.applyModePreset
            primaryModeReorderState: primaryModeReorderState
            advancedModeReorderState: advancedModeReorderState
            beginPrimaryModeDragFn: root.beginPrimaryModeDrag
            moveDraggedPrimaryModeFn: root.moveDraggedPrimaryMode
            beginAdvancedModeDragFn: root.beginAdvancedModeDrag
            moveDraggedAdvancedModeFn: root.moveDraggedAdvancedMode
            clearModeDragStateFn: root.clearModeDragState
            movePrimaryModeFn: root.movePrimaryMode
            moveAdvancedModeFn: root.moveAdvancedMode
            launcherModeMetaFn: root.launcherModeMeta
            currentModeDropIndexFn: root.currentModeDropIndex
            demoteLauncherModeFn: root.demoteLauncherMode
            promoteLauncherModeFn: root.promoteLauncherMode
            disableLauncherModeFn: root.disableLauncherMode
            enableLauncherModeFn: root.enableLauncherMode
        }

        LauncherRuntimeSection {
            visible: root.isLauncherRuntimeSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            resetLauncherDefaultsFn: root.resetLauncherDefaults
        }
    }
}

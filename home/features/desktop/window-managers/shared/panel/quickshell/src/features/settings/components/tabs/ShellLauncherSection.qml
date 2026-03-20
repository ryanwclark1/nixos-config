import QtQuick
import QtQuick.Layouts
import Quickshell
import "ShellCoreHelpers.js" as Helpers
import "../../../../launcher/LauncherModeData.js" as ModeData
import "../../../../services"
import "../../../../widgets" as SharedWidgets
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
            { key: "duckduckgo", label: "DuckDuckGo", icon: "󰇥" },
            { key: "google", label: "Google", icon: "󰊯" },
            { key: "youtube", label: "YouTube", icon: "󰗃" },
            { key: "nixos", label: "NixOS Packages", icon: "" },
            { key: "github", label: "GitHub", icon: "󰊤" },
            { key: "brave", label: "Brave Search", icon: "󰊯" },
            { key: "bing", label: "Bing", icon: "󰊯" },
            { key: "kagi", label: "Kagi", icon: "󰊯" },
            { key: "stackoverflow", label: "Stack Overflow", icon: "" },
            { key: "npm", label: "npm", icon: "󰎙" },
            { key: "pypi", label: "PyPI", icon: "󰌠" },
            { key: "crates", label: "crates.io", icon: "🦀" },
            { key: "mdn", label: "MDN Web Docs", icon: "globe-search.svg" },
            { key: "archwiki", label: "Arch Wiki", icon: "󰣇" },
            { key: "aur", label: "AUR", icon: "󰣇" },
            { key: "nixopts", label: "NixOS Options", icon: "" },
            { key: "reddit", label: "Reddit", icon: "󰑍" },
            { key: "twitter", label: "Twitter/X", icon: "󰕄" },
            { key: "linkedin", label: "LinkedIn", icon: "󰌻" },
            { key: "wikipedia", label: "Wikipedia", icon: "󰖬" },
            { key: "translate", label: "Google Translate", icon: "󰗊" },
            { key: "imdb", label: "IMDb", icon: "󰎁" },
            { key: "amazon", label: "Amazon", icon: "󰅐" },
            { key: "ebay", label: "eBay", icon: "󰮫" },
            { key: "maps", label: "Google Maps", icon: "󰍎" },
            { key: "images", label: "Google Images", icon: "image.svg" }
        ];
        // Append custom engines
        var customs = Config.launcherWebCustomEngines;
        if (Array.isArray(customs)) {
            for (var i = 0; i < customs.length; ++i) {
                var c = customs[i];
                if (c && c.key && c.name)
                    builtIn.push({ key: c.key, label: c.name, icon: c.icon || "󰖟", isCustom: true });
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

    implicitHeight: launcherColumn.implicitHeight

    ColumnLayout {
        id: launcherColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Colors.spacingL

        Rectangle {
            visible: root.isLauncherSection || root.isLauncherGeneralSection || root.isLauncherSearchSection || root.isLauncherWebSection || root.isLauncherModesSection || root.isLauncherRuntimeSection
            Layout.fillWidth: true
            radius: Colors.radiusLarge
            color: Colors.withAlpha(Colors.primary, 0.08)
            border.color: Colors.primaryMarked
            border.width: 1
            implicitHeight: launcherHeroColumn.implicitHeight + (root.compactMode ? Colors.spacingM * 2 : Colors.spacingL * 2)

            ColumnLayout {
                id: launcherHeroColumn
                anchors.fill: parent
                anchors.margins: root.compactMode ? Colors.spacingM : Colors.spacingL
                spacing: Colors.spacingM

                Text {
                    text: "LAUNCHER CONTROL DECK"
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    Rectangle {
                        width: root.compactMode ? 42 : 48
                        height: width
                        radius: Colors.radiusLarge
                        color: Colors.primarySubtle
                        border.color: Colors.primaryRing
                        border.width: 1

                        Loader {
                            anchors.centerIn: parent
                            sourceComponent: root.launcherHeroMeta.icon.endsWith(".svg") ? _launcherSvgIcon : _launcherNerdIcon
                        }
                        Component {
                            id: _launcherSvgIcon
                            SharedWidgets.SvgIcon { source: root.launcherHeroMeta.icon; color: Colors.primary; size: root.compactMode ? Colors.fontSizeXL : Colors.fontSizeXXL }
                        }
                        Component {
                            id: _launcherNerdIcon
                            Text {
                                text: root.launcherHeroMeta.icon
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: root.compactMode ? Colors.fontSizeXL : Colors.fontSizeXXL
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXXS

                        Text {
                            Layout.fillWidth: true
                            text: root.launcherHeroMeta.label
                            color: Colors.text
                            font.pixelSize: root.compactMode ? Colors.fontSizeXL : Colors.fontSizeHuge
                            font.weight: Font.Black
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.launcherHeroMeta.description
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: root.launcherHeroTabs

                        delegate: SharedWidgets.FilterChip {
                            required property var modelData
                            label: modelData.label
                            icon: modelData.icon
                            selected: modelData.id === root.currentLauncherTabId
                            onClicked: root.selectLauncherTab(modelData.id)
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: root.launcherHeroMeta.chips

                        delegate: SharedWidgets.Chip {
                            required property string modelData
                            text: modelData
                            icon: "󰋗"
                            iconColor: Colors.primary
                            textColor: Colors.text
                            bgColor: Colors.withAlpha(Colors.primary, 0.1)
                            borderColor: Colors.withAlpha(Colors.primary, 0.18)
                        }
                    }
                }
            }
        }

        // ----- Launcher Behavior (general) ----------------------------------
        SettingsCard {
            visible: root.isLauncherGeneralSection
            Layout.fillWidth: true
            title: "Launcher Behavior"
            iconName: "󰍉"
            description: "Choose the default launcher behavior and opening mode."

            SettingsInfoCallout {
                iconName: "󰛢"
                title: "Dedicated launcher settings"
                body: "Launcher controls now live under their own settings section so search, modes, home layout, and diagnostics are easier to tune without digging through Shell settings."
            }

            SettingsModeRow {
                label: "Default Mode"
                icon: "󰀻"
                currentValue: Config.launcherDefaultMode
                options: root.defaultModeOptions()
                onModeSelected: modeValue => Config.launcherDefaultMode = modeValue
            }

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Show Mode Hints"
                    icon: "keyboard.svg"
                    configKey: "launcherShowModeHints"
                }
                SettingsToggleRow {
                    label: "Keep Query on Mode Switch"
                    icon: "timer.svg"
                    configKey: "launcherKeepSearchOnModeSwitch"
                }
                SettingsToggleRow {
                    label: "Paste Characters on Select"
                    icon: "󰆏"
                    configKey: "launcherCharacterPasteOnSelect"
                }
                SettingsModeRow {
                    label: "Tab Behavior"
                    icon: "keyboard.svg"
                    currentValue: Config.launcherTabBehavior
                    options: [
                        {
                            value: "contextual",
                            label: "Contextual",
                            icon: "󰛢"
                        },
                        {
                            value: "results",
                            label: "Results Only",
                            icon: "search-visual.svg"
                        },
                        {
                            value: "mode",
                            label: "Mode Switch",
                            icon: "keyboard.svg"
                        }
                    ]
                    onModeSelected: modeValue => Config.launcherTabBehavior = modeValue
                }
                SettingsTextInputRow {
                    label: "Character Trigger"
                    leadingIcon: "󰞅"
                    placeholderText: ":"
                    text: Config.launcherCharacterTrigger
                    onSubmitted: value => Config.launcherCharacterTrigger = value.trim() === "" ? ":" : value.trim()
                    onTextEdited: value => Config.launcherCharacterTrigger = value.trim() === "" ? ":" : value.trim()
                }
            }
        }

        // ----- Home Layout (general) ----------------------------------------
        SettingsCard {
            visible: root.isLauncherGeneralSection
            Layout.fillWidth: true
            title: "Home Layout"
            iconName: "󰆍"
            description: "Control what the launcher home view shows before a search is entered."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Show Home Sections"
                    icon: "terminal.svg"
                    configKey: "launcherShowHomeSections"
                }
                SettingsToggleRow {
                    label: "App Category Filters"
                    icon: "󰀻"
                    configKey: "launcherDrunCategoryFiltersEnabled"
                }
            }

            SettingsSliderRow {
                label: "Recents History Limit"
                icon: "arrow-counterclockwise.svg"
                min: 4
                max: 40
                step: 1
                value: Config.launcherRecentsLimit
                unit: ""
                onMoved: v => Config.launcherRecentsLimit = v
            }

            SettingsSliderRow {
                label: "Recent Apps on Home"
                icon: "arrow-counterclockwise.svg"
                min: 1
                max: 20
                step: 1
                value: Config.launcherRecentAppsLimit
                unit: ""
                onMoved: v => Config.launcherRecentAppsLimit = v
            }

            SettingsSliderRow {
                label: "Suggestions on Home"
                icon: "copy.svg"
                min: 0
                max: 12
                step: 1
                value: Config.launcherSuggestionsLimit
                unit: ""
                onMoved: v => Config.launcherSuggestionsLimit = v
            }
        }

        // ----- Search Limits (search) ---------------------------------------
        SettingsCard {
            visible: root.isLauncherSearchSection
            Layout.fillWidth: true
            title: "Search Limits"
            iconName: "󰔛"
            description: "Tune search breadth, file query thresholds, and response timing."

            SettingsSliderRow {
                label: "Max Results"
                icon: "clock.svg"
                min: 20
                max: 200
                step: 5
                value: Config.launcherMaxResults
                onMoved: v => Config.launcherMaxResults = v
            }

            SettingsSliderRow {
                label: "File Query Min Length"
                icon: "document.svg"
                min: 1
                max: 6
                value: Config.launcherFileMinQueryLength
                onMoved: v => Config.launcherFileMinQueryLength = v
            }

            SettingsSliderRow {
                label: "File Search Max Results"
                icon: "document.svg"
                min: 20
                max: 300
                step: 10
                value: Config.launcherFileMaxResults
                onMoved: v => Config.launcherFileMaxResults = v
            }

            SettingsTextInputRow {
                label: "File Search Root"
                leadingIcon: "folder.svg"
                placeholderText: "~"
                text: Config.launcherFileSearchRoot
                onSubmitted: value => Config.launcherFileSearchRoot = value.trim() === "" ? "~" : value.trim()
                onTextEdited: value => Config.launcherFileSearchRoot = value.trim() === "" ? "~" : value.trim()
            }

            SettingsToggleRow {
                label: "Show Hidden Files"
                icon: "sort.svg"
                configKey: "launcherFileShowHidden"
                enabledText: "Include dotfiles and hidden directories in file mode."
                disabledText: "Hide dotfiles and hidden directories in file mode."
            }

            SettingsInfoCallout {
                visible: !root.launcherFilePreviewToggleAvailable
                iconName: "info.svg"
                title: "File Preview Temporarily Disabled"
                body: "The file preview pane is gated off by default while a QuickShell restart issue in files mode is being root-caused. Set QS_ENABLE_UNSTABLE_LAUNCHER_FILE_PREVIEW=1 only for debugging."
            }

            SettingsToggleRow {
                visible: root.launcherFilePreviewToggleAvailable
                label: "File Preview Pane"
                icon: "image.svg"
                configKey: "launcherFilePreviewEnabled"
                enabledText: "Show a content preview beside file search results (Alt+P)."
                disabledText: "Hide the file preview pane."
            }

            SettingsTextInputRow {
                label: "File Opener"
                leadingIcon: "document.svg"
                placeholderText: "xdg-open"
                text: Config.launcherFileOpener
                onSubmitted: value => Config.launcherFileOpener = value.trim() === "" ? "xdg-open" : value.trim()
                onTextEdited: value => Config.launcherFileOpener = value.trim() === "" ? "xdg-open" : value.trim()
            }

            SettingsSliderRow {
                label: "Cache TTL"
                icon: "timer.svg"
                min: 30
                max: 1800
                step: 30
                value: Config.launcherCacheTtlSec
                unit: "s"
                onMoved: v => Config.launcherCacheTtlSec = v
            }

            SettingsSliderRow {
                label: "Search Debounce"
                icon: "clock.svg"
                min: 0
                max: 250
                step: 5
                value: Config.launcherSearchDebounceMs
                unit: "ms"
                onMoved: v => Config.launcherSearchDebounceMs = v
            }

            SettingsSliderRow {
                label: "File Search Debounce"
                icon: "clock.svg"
                min: 50
                max: 1200
                step: 10
                value: Config.launcherFileSearchDebounceMs
                unit: "ms"
                onMoved: v => Config.launcherFileSearchDebounceMs = v
            }
        }

        // ----- Result Scoring (search) --------------------------------------
        SettingsCard {
            visible: root.isLauncherSearchSection
            Layout.fillWidth: true
            title: "Result Scoring"
            iconName: "󰀻"
            description: "Adjust how launcher results are ranked across labels, commands, and metadata."

            SettingsSectionLabel {
                text: "RESULT SCORING WEIGHTS"
            }

            SettingsSliderRow {
                label: "Name Weight"
                icon: "keyboard.svg"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreNameWeight
                unit: ""
                onMoved: v => Config.launcherScoreNameWeight = v
            }

            SettingsSliderRow {
                label: "Title Weight"
                icon: "keyboard.svg"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreTitleWeight
                unit: ""
                onMoved: v => Config.launcherScoreTitleWeight = v
            }

            SettingsSliderRow {
                label: "Exec/Class Weight"
                icon: "terminal.svg"
                min: 0.1
                max: 2.0
                step: 0.05
                value: Config.launcherScoreExecWeight
                unit: ""
                onMoved: v => Config.launcherScoreExecWeight = v
            }

            SettingsSliderRow {
                label: "Body Weight"
                icon: "document.svg"
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

        // ----- Web Search Behavior (web) ------------------------------------
        SettingsCard {
            visible: root.isLauncherWebSection
            Layout.fillWidth: true
            title: "Web Search Behavior"
            iconName: "󰖟"
            description: "Web-mode defaults and keyboard behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Web Enter Uses Primary"
                    icon: "globe-search.svg"
                    configKey: "launcherWebEnterUsesPrimary"
                }
                SettingsToggleRow {
                    label: "Web Number Hotkeys"
                    icon: "keyboard.svg"
                    configKey: "launcherWebNumberHotkeysEnabled"
                }
                SettingsToggleRow {
                    label: "Remember Web Provider"
                    icon: "globe-search.svg"
                    configKey: "launcherRememberWebProvider"
                }
            }
        }

        // ----- Web Providers (web) ------------------------------------------
        SettingsCard {
            visible: root.isLauncherWebSection
            Layout.fillWidth: true
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

                        SettingsDropIndicator {
                            id: webDropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            active: webProviderRow.dropBeforeActive
                            visible: webProviderRow.dropBeforeActive
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
                            dragging: webDragHandle.dragActive
                            dropTargeted: webProviderRow.dropBeforeActive
                            onYChanged: {
                                if (webDragHandle.dragActive)
                                    webProviderReorderState.updateTarget("launcher-web-provider", root.currentWebProviderDropIndex(webProviderCard, webProviderRow.index, webProviderOrderList));
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
                                    if (pressed)
                                        root.beginWebProviderDrag(webProviderRow.modelData, webProviderRow.index);
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
                                        iconName: "󰅃"
                                        label: "↑"
                                        onClicked: root.moveWebProvider(webProviderRow.modelData, -1)
                                    }

                                    SettingsActionButton {
                                        compact: true
                                        enabled: webProviderRow.index < (root.orderedWebProviders().length - 1)
                                        iconName: "󰅀"
                                        label: "↓"
                                        onClicked: root.moveWebProvider(webProviderRow.modelData, 1)
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: root.dragWebProviderKey !== "" && root.dragWebProviderTargetIndex === root.orderedWebProviders().length
                    visible: active
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

        // ----- Web Aliases (web) --------------------------------------------
        SettingsCard {
            visible: root.isLauncherWebSection
            Layout.fillWidth: true
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

        // ----- Custom Search Engines (web) -----------------------------------
        SettingsCard {
            visible: root.isLauncherWebSection
            Layout.fillWidth: true
            title: "Custom Search Engines"
            iconName: "󰖟"
            description: "Add your own search engines with URL templates. Use %s as the query placeholder."

            SettingsSectionLabel {
                text: "CUSTOM ENGINES"
            }

            Repeater {
                model: Array.isArray(Config.launcherWebCustomEngines) ? Config.launcherWebCustomEngines : []
                delegate: RowLayout {
                    id: customEngineRow
                    Layout.fillWidth: true
                    required property int index
                    required property var modelData
                    spacing: Colors.spacingS

                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: Colors.radiusCard
                        color: Colors.surface
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeSmall
                            text: customEngineRow.modelData.icon || "󰖟"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: customEngineRow.modelData.name + " (" + customEngineRow.modelData.key + ")"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: customEngineRow.modelData.exec
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    SettingsActionButton {
                        compact: true
                        iconName: "󰆴"
                        onClicked: {
                            var engines = Config.launcherWebCustomEngines.slice();
                            engines.splice(customEngineRow.index, 1);
                            Config.launcherWebCustomEngines = engines;
                        }
                    }
                }
            }

            SettingsInfoCallout {
                visible: !Array.isArray(Config.launcherWebCustomEngines) || Config.launcherWebCustomEngines.length === 0
                iconName: "󰛢"
                title: "No custom engines"
                body: "Add a custom search engine below. It will appear in the web provider list."
            }

            SettingsSectionLabel {
                text: "ADD NEW ENGINE"
            }

            SettingsTextInputRow {
                label: "Key (short ID)"
                placeholderText: "e.g. rustdoc"
                text: root.newEngineKey
                onSubmitted: value => root.newEngineKey = value
                onTextEdited: value => root.newEngineKey = value
            }

            SettingsTextInputRow {
                label: "Name"
                placeholderText: "e.g. Rust Docs"
                text: root.newEngineName
                onSubmitted: value => root.newEngineName = value
                onTextEdited: value => root.newEngineName = value
            }

            SettingsTextInputRow {
                label: "URL Template"
                placeholderText: "https://example.com/search?q=%s"
                text: root.newEngineUrl
                onSubmitted: value => root.newEngineUrl = value
                onTextEdited: value => root.newEngineUrl = value
            }

            SettingsTextInputRow {
                label: "Icon (optional)"
                placeholderText: "Nerd Font icon"
                text: root.newEngineIcon
                onSubmitted: value => root.newEngineIcon = value
                onTextEdited: value => root.newEngineIcon = value
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Add Custom Engine"
                iconName: "󰐕"
                enabled: root.newEngineKey.trim() !== "" && root.newEngineName.trim() !== "" && root.newEngineUrl.trim() !== ""
                onClicked: {
                    var engines = Array.isArray(Config.launcherWebCustomEngines) ? Config.launcherWebCustomEngines.slice() : [];
                    var key = root.newEngineKey.trim().toLowerCase().replace(/[^a-z0-9-]/g, "");
                    if (key === "")
                        return;
                    engines.push({
                        key: key,
                        name: root.newEngineName.trim(),
                        exec: root.newEngineUrl.trim(),
                        home: "",
                        icon: root.newEngineIcon.trim() || "󰖟"
                    });
                    Config.launcherWebCustomEngines = engines;
                    root.newEngineKey = "";
                    root.newEngineName = "";
                    root.newEngineUrl = "";
                    root.newEngineIcon = "";
                }
            }
        }

        // ----- DuckDuckGo Bangs (web) ----------------------------------------
        SettingsCard {
            visible: root.isLauncherWebSection
            Layout.fillWidth: true
            title: "DuckDuckGo Bangs"
            iconName: "󰇥"
            description: "Use DDG !bangs for quick site searches (e.g. !gh quickshell, !w quantum)."

            SettingsToggleRow {
                label: "Enable !Bangs"
                icon: "󰇥"
                configKey: "launcherWebBangsEnabled"
            }

            SettingsInfoCallout {
                iconName: "󰛢"
                title: "How bangs work"
                body: "Type ?!prefix query in web mode. The bang database must be synced first using the button below."
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsActionButton {
                    Layout.fillWidth: true
                    label: "Sync Bang Database"
                    iconName: "󰑓"
                    enabled: Config.launcherWebBangsEnabled
                    onClicked: {
                        Quickshell.execDetached(["qs-bang-sync"]);
                        Config.launcherWebBangsLastSync = new Date().toISOString();
                    }
                }
            }

            Text {
                visible: Config.launcherWebBangsLastSync !== ""
                text: "Last synced: " + Config.launcherWebBangsLastSync
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
            }

            Text {
                visible: Config.launcherWebBangsLastSync === "" && Config.launcherWebBangsEnabled
                text: "Bang database not yet synced. Click 'Sync' to download."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
            }
        }

        // ----- Launcher Modes (modes) ---------------------------------------
        SettingsCard {
            visible: root.isLauncherModesSection
            Layout.fillWidth: true
            title: "Launcher Presets"
            iconName: "󰌌"
            description: "Choose a focused default set, an extended power-user set, or everything."

            SettingsInfoCallout {
                iconName: "󰛢"
                title: "Sidebar vs advanced"
                body: "Primary sidebar modes stay visible in the launcher. Advanced modes stay enabled, but live behind More and their prefixes."
            }

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Focused"
                    compact: true
                    onClicked: root.applyModePreset("focused")
                }

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Extended"
                    compact: true
                    onClicked: root.applyModePreset("extended")
                }

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "All"
                    compact: true
                    onClicked: root.applyModePreset("all")
                }
            }
        }

        SettingsCard {
            visible: root.isLauncherModesSection
            Layout.fillWidth: true
            title: "Primary Sidebar"
            iconName: "󰍉"
            description: "These modes stay pinned in the launcher sidebar."

            LauncherModeList {
                id: primaryModeOrderList
                Layout.fillWidth: true
                modeModel: root.orderedPrimaryModes()
                reorderState: primaryModeReorderState
                listId: "launcher-primary-mode"
                compactMode: root.compactMode
                beginDragFn: root.beginPrimaryModeDrag
                moveDraggedFn: root.moveDraggedPrimaryMode
                clearDragStateFn: root.clearModeDragState
                moveModeFn: root.movePrimaryMode
                modeMetaFn: root.launcherModeMeta
                dropIndexFn: root.currentModeDropIndex
                promoteLabel: "Advanced"
                promoteFn: root.demoteLauncherMode
                disableFn: root.disableLauncherMode
                dropEndText: "Drop at end of primary sidebar"
                dragHintText: "Drag to reorder within the primary sidebar, or use the arrow buttons."
            }
        }

        SettingsCard {
            visible: root.isLauncherModesSection
            Layout.fillWidth: true
            title: "Advanced / Prefix"
            iconName: "󰑖"
            description: "These modes stay enabled behind More. Prefix-first modes remain one keystroke away."

            SettingsInfoCallout {
                iconName: "󰛢"
                title: "Prefix-first modes"
                body: "Settings, Run, SSH, and Web stay visible under the search field as prefix shortcuts even when they are not pinned in the sidebar."
            }

            LauncherModeList {
                id: advancedModeOrderList
                Layout.fillWidth: true
                modeModel: root.orderedAdvancedModes()
                reorderState: advancedModeReorderState
                listId: "launcher-advanced-mode"
                compactMode: root.compactMode
                beginDragFn: root.beginAdvancedModeDrag
                moveDraggedFn: root.moveDraggedAdvancedMode
                clearDragStateFn: root.clearModeDragState
                moveModeFn: root.moveAdvancedMode
                modeMetaFn: root.launcherModeMeta
                dropIndexFn: root.currentModeDropIndex
                promoteLabel: "Pin"
                promoteFn: root.promoteLauncherMode
                disableFn: root.disableLauncherMode
                dropEndText: "Drop at end of advanced modes"
                dragHintText: "Drag to reorder within advanced modes, or use the arrow buttons."
            }

            SettingsInfoCallout {
                visible: root.orderedAdvancedModes().length === 0
                iconName: "󰛢"
                title: "No advanced modes"
                body: "Enable another launcher mode to keep it available behind More."
            }
        }

        SettingsCard {
            visible: root.isLauncherModesSection
            Layout.fillWidth: true
            title: "Disabled Modes"
            iconName: "󰅚"
            description: "Disabled modes are hidden from the launcher until you re-enable them."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: root.disabledLauncherModes()

                    delegate: SharedWidgets.FilterChip {
                        required property var modelData
                        label: root.launcherModeMeta(modelData).label
                        icon: root.launcherModeMeta(modelData).icon
                        selected: false
                        onClicked: root.enableLauncherMode(modelData, false)
                    }
                }
            }

            SettingsInfoCallout {
                visible: root.disabledLauncherModes().length === 0
                iconName: "󰄬"
                title: "Everything is enabled"
                body: "Use disable on a primary or advanced mode if you want to remove it from launcher cycling entirely."
            }
        }

        // ----- Runtime Behavior (runtime) -----------------------------------
        SettingsCard {
            visible: root.isLauncherRuntimeSection
            Layout.fillWidth: true
            title: "Runtime Behavior"
            iconName: "󰔟"
            description: "Preload policy and runtime metric visibility."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2
                minimumColumnWidth: 280

                SettingsToggleRow {
                    label: "Background Preload"
                    icon: "timer.svg"
                    configKey: "launcherEnablePreload"
                }
                SettingsToggleRow {
                    label: "Debug Launcher Timings"
                    icon: "clock.svg"
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
                icon: "timer.svg"
                min: 1
                max: 10
                step: 1
                value: Config.launcherPreloadFailureThreshold
                unit: ""
                onMoved: v => Config.launcherPreloadFailureThreshold = v
            }

            SettingsSliderRow {
                label: "Preload Backoff"
                icon: "clock.svg"
                min: 10
                max: 900
                step: 10
                value: Config.launcherPreloadFailureBackoffSec
                unit: "s"
                onMoved: v => Config.launcherPreloadFailureBackoffSec = v
            }
        }

        // ----- Diagnostics & Recovery (runtime) ----------------------------
        SettingsCard {
            visible: root.isLauncherRuntimeSection
            Layout.fillWidth: true
            title: "Diagnostics & Recovery"
            iconName: "arrow-clockwise.svg"
            description: "Runtime reset actions and launcher maintenance controls."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsActionButton {
                    width: root.compactMode ? implicitWidth : 0
                    Layout.fillWidth: !root.compactMode
                    label: "Reset Runtime Metrics"
                    iconName: "arrow-clockwise.svg"
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
                iconName: "arrow-clockwise.svg"
                onClicked: root.resetLauncherDefaults()
            }
        }
    }
}

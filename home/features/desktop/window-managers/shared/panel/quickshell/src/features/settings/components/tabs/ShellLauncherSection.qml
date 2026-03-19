import QtQuick
import QtQuick.Layouts
import Quickshell
import "ShellCoreHelpers.js" as Helpers
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    required property bool compactMode
    required property var settingsRoot
    required property string sectionMode

    // Drag state owned here
    property string dragModeKey: ""
    property int dragModeTargetIndex: -1
    property string dragWebProviderKey: ""
    property int dragWebProviderTargetIndex: -1

    // Section visibility
    readonly property bool isLauncherSection: sectionMode === "launcher"
    readonly property bool isLauncherGeneralSection: sectionMode === "launcher-general" || isLauncherSection
    readonly property bool isLauncherSearchSection: sectionMode === "launcher-search"
    readonly property bool isLauncherWebSection: sectionMode === "launcher-web"
    readonly property bool isLauncherModesSection: sectionMode === "launcher-modes"
    readonly property bool isLauncherRuntimeSection: sectionMode === "launcher-runtime"

    // Static data arrays
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
            icon: ""
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
            { key: "mdn", label: "MDN Web Docs", icon: "󰖟" },
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
            { key: "images", label: "Google Images", icon: "󰋩" }
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
    function clearModeDragState() {
        Helpers.clearModeDragState(root);
    }
    function currentModeDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentModeDropIndex(cardItem, rowIndex, listItem, Config, CompositorAdapter, launcherModes);
    }
    function moveDraggedMode(targetIndex) {
        return Helpers.moveDraggedMode(Config, CompositorAdapter, launcherModes, root, targetIndex);
    }
    function toggleWebProvider(providerKey) {
        Helpers.toggleWebProvider(Config, webProviders, webProviderDefaultOrder, providerKey);
    }
    function moveWebProvider(providerKey, delta) {
        Helpers.moveWebProvider(Config, webProviders, webProviderDefaultOrder, providerKey, delta);
    }
    function clearWebProviderDragState() {
        Helpers.clearWebProviderDragState(root);
    }
    function currentWebProviderDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentWebProviderDropIndex(cardItem, rowIndex, listItem, Config, webProviders, webProviderDefaultOrder);
    }
    function moveDraggedWebProvider(targetIndex) {
        return Helpers.moveDraggedWebProvider(Config, webProviders, webProviderDefaultOrder, root, targetIndex);
    }
    function resetLauncherDefaults() {
        Helpers.resetLauncherDefaults(Config, webAliasDefaults, webProviderDefaultOrder, launcherDefaultModes, CompositorAdapter, launcherModes);
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
                    icon: "󰌌"
                    configKey: "launcherShowModeHints"
                }
                SettingsToggleRow {
                    label: "Keep Query on Mode Switch"
                    icon: "󰔟"
                    configKey: "launcherKeepSearchOnModeSwitch"
                }
                SettingsModeRow {
                    label: "Tab Behavior"
                    icon: "󰌌"
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
                            icon: "󰍉"
                        },
                        {
                            value: "mode",
                            label: "Mode Switch",
                            icon: "󰌌"
                        }
                    ]
                    onModeSelected: modeValue => Config.launcherTabBehavior = modeValue
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
                    icon: "󰆍"
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
                icon: "󰑓"
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

        // ----- Search Limits (search) ---------------------------------------
        SettingsCard {
            visible: root.isLauncherSearchSection
            Layout.fillWidth: true
            title: "Search Limits"
            iconName: "󰔛"
            description: "Tune search breadth, file query thresholds, and response timing."

            SettingsSliderRow {
                label: "Max Results"
                icon: "󰔛"
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
                icon: "󰌌"
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
                            color: Colors.primaryMarked
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
                                        iconName: "󰅃"
                                        onClicked: root.moveWebProvider(webProviderRow.modelData, -1)
                                    }

                                    SettingsActionButton {
                                        compact: true
                                        enabled: webProviderRow.index < (root.orderedWebProviders().length - 1)
                                        iconName: "󰅀"
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
                    color: Colors.primaryMarked
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

            property string newEngineKey: ""
            property string newEngineName: ""
            property string newEngineUrl: ""
            property string newEngineIcon: ""

            SettingsTextInputRow {
                label: "Key (short ID)"
                placeholderText: "e.g. rustdoc"
                text: parent.newEngineKey
                onSubmitted: value => parent.newEngineKey = value
                onTextEdited: value => parent.newEngineKey = value
            }

            SettingsTextInputRow {
                label: "Name"
                placeholderText: "e.g. Rust Docs"
                text: parent.newEngineName
                onSubmitted: value => parent.newEngineName = value
                onTextEdited: value => parent.newEngineName = value
            }

            SettingsTextInputRow {
                label: "URL Template"
                placeholderText: "https://example.com/search?q=%s"
                text: parent.newEngineUrl
                onSubmitted: value => parent.newEngineUrl = value
                onTextEdited: value => parent.newEngineUrl = value
            }

            SettingsTextInputRow {
                label: "Icon (optional)"
                placeholderText: "Nerd Font icon"
                text: parent.newEngineIcon
                onSubmitted: value => parent.newEngineIcon = value
                onTextEdited: value => parent.newEngineIcon = value
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Add Custom Engine"
                iconName: "󰐕"
                enabled: parent.newEngineKey.trim() !== "" && parent.newEngineName.trim() !== "" && parent.newEngineUrl.trim() !== ""
                onClicked: {
                    var engines = Array.isArray(Config.launcherWebCustomEngines) ? Config.launcherWebCustomEngines.slice() : [];
                    var key = parent.newEngineKey.trim().toLowerCase().replace(/[^a-z0-9-]/g, "");
                    if (key === "")
                        return;
                    engines.push({
                        key: key,
                        name: parent.newEngineName.trim(),
                        exec: parent.newEngineUrl.trim(),
                        home: "",
                        icon: parent.newEngineIcon.trim() || "󰖟"
                    });
                    Config.launcherWebCustomEngines = engines;
                    parent.newEngineKey = "";
                    parent.newEngineName = "";
                    parent.newEngineUrl = "";
                    parent.newEngineIcon = "";
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

        // ----- Mode Order (modes) -------------------------------------------
        SettingsCard {
            visible: root.isLauncherModesSection
            Layout.fillWidth: true
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
                            color: Colors.primaryMarked
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
                                    iconName: "󰅃"
                                    compact: true
                                    enabled: modeRow.index > 0
                                    onClicked: root.moveMode(modeRow.modelData, -1)
                                }

                                SettingsActionButton {
                                    iconName: "󰅀"
                                    compact: true
                                    enabled: modeRow.index < (root.orderedEnabledModes().length - 1)
                                    onClicked: root.moveMode(modeRow.modelData, 1)
                                }
                                }                            }
                        }
                    }
                }

                Rectangle {
                    width: parent ? parent.width : 0
                    height: 12
                    radius: Colors.radiusXXS
                    visible: root.dragModeKey !== "" && root.dragModeTargetIndex === root.orderedEnabledModes().length
                    color: Colors.primaryMarked
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

        // ----- Diagnostics & Recovery (runtime) ----------------------------
        SettingsCard {
            visible: root.isLauncherRuntimeSection
            Layout.fillWidth: true
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
    }
}

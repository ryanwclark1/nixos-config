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
                SettingsToggleRow {
                    label: "Paste Characters on Select"
                    icon: "󰆏"
                    configKey: "launcherCharacterPasteOnSelect"
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

            SettingsTextInputRow {
                label: "File Search Root"
                leadingIcon: "󰉋"
                placeholderText: "~"
                text: Config.launcherFileSearchRoot
                onSubmitted: value => Config.launcherFileSearchRoot = value.trim() === "" ? "~" : value.trim()
                onTextEdited: value => Config.launcherFileSearchRoot = value.trim() === "" ? "~" : value.trim()
            }

            SettingsToggleRow {
                label: "Show Hidden Files"
                icon: "󰘓"
                configKey: "launcherFileShowHidden"
                enabledText: "Include dotfiles and hidden directories in file mode."
                disabledText: "Hide dotfiles and hidden directories in file mode."
            }

            SettingsTextInputRow {
                label: "File Opener"
                leadingIcon: "󰈔"
                placeholderText: "xdg-open"
                text: Config.launcherFileOpener
                onSubmitted: value => Config.launcherFileOpener = value.trim() === "" ? "xdg-open" : value.trim()
                onTextEdited: value => Config.launcherFileOpener = value.trim() === "" ? "xdg-open" : value.trim()
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

            Column {
                id: primaryModeOrderList
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root.orderedPrimaryModes()

                    delegate: Item {
                        id: primaryModeRow
                        width: parent ? parent.width : 0
                        implicitHeight: primaryModeCard.implicitHeight + (primaryDropBeforeIndicator.visible ? primaryDropBeforeIndicator.height + Colors.spacingXS : 0)
                        height: implicitHeight
                        required property int index
                        required property var modelData
                        readonly property bool dropBeforeActive: primaryModeReorderState.active && primaryModeReorderState.targetListId === "launcher-primary-mode" && primaryModeReorderState.targetIndex === index

                        SettingsDropIndicator {
                            id: primaryDropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            active: primaryModeRow.dropBeforeActive
                            visible: primaryModeRow.dropBeforeActive
                        }

                        SettingsListRow {
                            id: primaryModeCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: primaryDropBeforeIndicator.bottom
                                topMargin: primaryDropBeforeIndicator.visible ? Colors.spacingXS : 0
                            }
                            minimumHeight: root.compactMode ? 82 : 54
                            dragging: primaryDragHandle.dragActive
                            dropTargeted: primaryModeRow.dropBeforeActive
                            onYChanged: {
                                if (primaryDragHandle.dragActive)
                                    primaryModeReorderState.updateTarget("launcher-primary-mode", root.currentModeDropIndex(primaryModeCard, primaryModeRow.index, primaryModeOrderList, root.orderedPrimaryModes().length));
                            }

                            Behavior on y {
                                enabled: !primaryDragHandle.dragActive

                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SettingsDragHandle {
                                id: primaryDragHandle
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                                dragTarget: primaryModeCard
                                onPressedChanged: {
                                    if (pressed)
                                        root.beginPrimaryModeDrag(primaryModeRow.modelData, primaryModeRow.index);
                                }
                                onReleased: function (wasDragging) {
                                    var targetIndex = primaryModeReorderState.targetIndex;
                                    if (wasDragging)
                                        targetIndex = root.currentModeDropIndex(primaryModeCard, primaryModeRow.index, primaryModeOrderList, root.orderedPrimaryModes().length);
                                    primaryModeCard.x = 0;
                                    primaryModeCard.y = 0;
                                    if (wasDragging) {
                                        if (!root.moveDraggedPrimaryMode(targetIndex))
                                            root.clearModeDragState();
                                    } else {
                                        root.clearModeDragState();
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: Colors.radiusCard
                                color: Colors.surface
                                border.color: Colors.border
                                border.width: 1
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.launcherModeMeta(primaryModeRow.modelData).icon
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingS

                                    Text {
                                        text: root.launcherModeMeta(primaryModeRow.modelData).label
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeSmall
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        visible: String(ModeData.modeInfo(primaryModeRow.modelData).prefix || "") !== ""
                                        radius: Colors.radiusPill
                                        color: Colors.primarySubtle
                                        border.color: Colors.primaryRing
                                        border.width: 1
                                        implicitHeight: 22
                                        implicitWidth: prefixLabel.implicitWidth + 12

                                        Text {
                                            id: prefixLabel
                                            anchors.centerIn: parent
                                            text: (ModeData.modeInfo(primaryModeRow.modelData).prefix || "") + " prefix"
                                            color: Colors.primary
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: ModeData.modeInfo(primaryModeRow.modelData).hint || "Launcher mode"
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Drag to reorder within the primary sidebar, or use the arrow buttons."
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Flow {
                                spacing: Colors.spacingS
                                Layout.alignment: Qt.AlignTop

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅃"
                                    enabled: primaryModeRow.index > 0
                                    onClicked: root.movePrimaryMode(primaryModeRow.modelData, -1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅀"
                                    enabled: primaryModeRow.index < (root.orderedPrimaryModes().length - 1)
                                    onClicked: root.movePrimaryMode(primaryModeRow.modelData, 1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    label: "Advanced"
                                    onClicked: root.demoteLauncherMode(primaryModeRow.modelData)
                                }

                                SettingsActionButton {
                                    compact: true
                                    label: "Disable"
                                    onClicked: root.disableLauncherMode(primaryModeRow.modelData)
                                }
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: primaryModeReorderState.active && primaryModeReorderState.targetListId === "launcher-primary-mode" && primaryModeReorderState.targetIndex === root.orderedPrimaryModes().length
                    visible: active
                }

                Text {
                    width: parent ? parent.width : 0
                    visible: primaryModeReorderState.active && primaryModeReorderState.targetListId === "launcher-primary-mode" && primaryModeReorderState.targetIndex === root.orderedPrimaryModes().length
                    text: "Drop at end of primary sidebar"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }
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

            Column {
                id: advancedModeOrderList
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root.orderedAdvancedModes()

                    delegate: Item {
                        id: advancedModeRow
                        width: parent ? parent.width : 0
                        implicitHeight: advancedModeCard.implicitHeight + (advancedDropBeforeIndicator.visible ? advancedDropBeforeIndicator.height + Colors.spacingXS : 0)
                        height: implicitHeight
                        required property int index
                        required property var modelData
                        readonly property bool dropBeforeActive: advancedModeReorderState.active && advancedModeReorderState.targetListId === "launcher-advanced-mode" && advancedModeReorderState.targetIndex === index

                        SettingsDropIndicator {
                            id: advancedDropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            active: advancedModeRow.dropBeforeActive
                            visible: advancedModeRow.dropBeforeActive
                        }

                        SettingsListRow {
                            id: advancedModeCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: advancedDropBeforeIndicator.bottom
                                topMargin: advancedDropBeforeIndicator.visible ? Colors.spacingXS : 0
                            }
                            minimumHeight: root.compactMode ? 84 : 56
                            dragging: advancedDragHandle.dragActive
                            dropTargeted: advancedModeRow.dropBeforeActive
                            onYChanged: {
                                if (advancedDragHandle.dragActive)
                                    advancedModeReorderState.updateTarget("launcher-advanced-mode", root.currentModeDropIndex(advancedModeCard, advancedModeRow.index, advancedModeOrderList, root.orderedAdvancedModes().length));
                            }

                            Behavior on y {
                                enabled: !advancedDragHandle.dragActive

                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SettingsDragHandle {
                                id: advancedDragHandle
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                                dragTarget: advancedModeCard
                                onPressedChanged: {
                                    if (pressed)
                                        root.beginAdvancedModeDrag(advancedModeRow.modelData, advancedModeRow.index);
                                }
                                onReleased: function (wasDragging) {
                                    var targetIndex = advancedModeReorderState.targetIndex;
                                    if (wasDragging)
                                        targetIndex = root.currentModeDropIndex(advancedModeCard, advancedModeRow.index, advancedModeOrderList, root.orderedAdvancedModes().length);
                                    advancedModeCard.x = 0;
                                    advancedModeCard.y = 0;
                                    if (wasDragging) {
                                        if (!root.moveDraggedAdvancedMode(targetIndex))
                                            root.clearModeDragState();
                                    } else {
                                        root.clearModeDragState();
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: Colors.radiusCard
                                color: Colors.surface
                                border.color: Colors.border
                                border.width: 1
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.launcherModeMeta(advancedModeRow.modelData).icon
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingS

                                    Text {
                                        text: root.launcherModeMeta(advancedModeRow.modelData).label
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeSmall
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        visible: String(ModeData.modeInfo(advancedModeRow.modelData).prefix || "") !== ""
                                        radius: Colors.radiusPill
                                        color: Colors.primarySubtle
                                        border.color: Colors.primaryRing
                                        border.width: 1
                                        implicitHeight: 22
                                        implicitWidth: advancedPrefixLabel.implicitWidth + 12

                                        Text {
                                            id: advancedPrefixLabel
                                            anchors.centerIn: parent
                                            text: (ModeData.modeInfo(advancedModeRow.modelData).prefix || "") + " prefix"
                                            color: Colors.primary
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: ModeData.modeInfo(advancedModeRow.modelData).hint || "Advanced launcher mode"
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Drag to reorder within advanced modes, or use the arrow buttons."
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Flow {
                                spacing: Colors.spacingS
                                Layout.alignment: Qt.AlignTop

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅃"
                                    enabled: advancedModeRow.index > 0
                                    onClicked: root.moveAdvancedMode(advancedModeRow.modelData, -1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅀"
                                    enabled: advancedModeRow.index < (root.orderedAdvancedModes().length - 1)
                                    onClicked: root.moveAdvancedMode(advancedModeRow.modelData, 1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    label: "Pin"
                                    onClicked: root.promoteLauncherMode(advancedModeRow.modelData)
                                }

                                SettingsActionButton {
                                    compact: true
                                    label: "Disable"
                                    onClicked: root.disableLauncherMode(advancedModeRow.modelData)
                                }
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: advancedModeReorderState.active && advancedModeReorderState.targetListId === "launcher-advanced-mode" && advancedModeReorderState.targetIndex === root.orderedAdvancedModes().length
                    visible: active
                }

                Text {
                    width: parent ? parent.width : 0
                    visible: advancedModeReorderState.active && advancedModeReorderState.targetListId === "launcher-advanced-mode" && advancedModeReorderState.targetIndex === root.orderedAdvancedModes().length
                    text: "Drop at end of advanced modes"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }
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

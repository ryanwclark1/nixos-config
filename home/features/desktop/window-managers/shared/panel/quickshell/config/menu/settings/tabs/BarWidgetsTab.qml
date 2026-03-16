import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property string addSection: "left"
    property string widgetSearchQuery: ""
    property bool widgetPickerOpen: false
    property string settingsSection: ""
    property string settingsInstanceId: ""
    property bool widgetSettingsOpen: false
    property string pluginSettingsError: ""
    property string validationMessage: ""
    property string dragSection: ""
    property int dragSourceIndex: -1
    property string dragTargetSection: ""
    property int dragTargetIndex: -1
    readonly property int overlayInset: root.tightSpacing ? 20 : 40
    readonly property bool dragReorderEnabled: true

    readonly property var selectedBar: {
        var bars = Config.barConfigs || [];
        var selectedId = String(Config.selectedBarId || "");
        var fallback = bars.length > 0 ? bars[0] : null;
        for (var i = 0; i < bars.length; ++i) {
            if (String(bars[i].id || "") === selectedId)
                return bars[i];
        }
        return fallback;
    }
    readonly property var currentSectionWidgets: {
        var bar = selectedBar;
        var sections = (bar && bar.sectionWidgets) ? bar.sectionWidgets : {};
        return {
            left: (sections.left || []).slice(),
            center: (sections.center || []).slice(),
            right: (sections.right || []).slice()
        };
    }
    readonly property var editingWidget: (selectedBar && settingsSection && settingsInstanceId) ? Config.widgetInstance(selectedBar.id, settingsSection, settingsInstanceId) : null
    readonly property string editingPluginId: {
        var typeName = editingWidget ? String(editingWidget.widgetType || "") : "";
        return typeName.indexOf("plugin:") === 0 ? typeName.slice(7) : "";
    }
    readonly property bool editingPluginHasSettings: editingPluginId !== "" && PluginService.pluginSupportsSettings(editingPluginId)
    readonly property bool editingPluginCanWriteSettings: editingPluginId !== "" && PluginService.pluginCanWriteSettings(editingPluginId)

    onWidgetSettingsOpenChanged: {
        if (!widgetSettingsOpen) {
            pluginSettingsError = "";
            if (pluginSettingsLoader)
                pluginSettingsLoader.source = "";
        }
    }
    onEditingPluginIdChanged: {
        if (widgetSettingsOpen)
            Qt.callLater(loadPluginSettingsPane);
    }
    function sectionWidgets(section) {
        return currentSectionWidgets[section] || [];
    }

    function sectionLabel(section) {
        return Config.sectionLabel(section, selectedBar ? selectedBar.position : "top");
    }

    function openWidgetPicker(section) {
        addSection = section;
        widgetSearchQuery = "";
        widgetPickerOpen = true;
    }

    function openWidgetSettings(section, instanceId) {
        settingsSection = section;
        settingsInstanceId = instanceId;
        pluginSettingsError = "";
        widgetSettingsOpen = true;
        Qt.callLater(loadPluginSettingsPane);
    }

    function addWidget(widgetType) {
        if (!selectedBar)
            return;
        var settings = BarWidgetRegistry.defaultSettings(widgetType);
        Config.addBarWidget(selectedBar.id, addSection, widgetType, settings);
        widgetPickerOpen = false;
    }

    function removeWidget(section, instanceId) {
        if (!selectedBar)
            return;
        Config.removeBarWidget(selectedBar.id, section, instanceId);
    }

    function moveWidget(section, index, delta) {
        if (!selectedBar)
            return false;
        var widgets = root.sectionWidgets(section);
        var targetIndex = index + delta;
        if (index < 0 || index >= widgets.length)
            return false;
        if (targetIndex < 0 || targetIndex >= widgets.length)
            return false;
        return Config.moveBarWidget(selectedBar.id, section, index, targetIndex, section);
    }

    function clearDragState() {
        dragSection = "";
        dragSourceIndex = -1;
        dragTargetSection = "";
        dragTargetIndex = -1;
    }

    function moveDraggedWidget(targetSection, targetIndex) {
        if (!selectedBar || dragSection === "" || dragSourceIndex < 0)
            return false;
        if (targetSection === "" || targetIndex < 0)
            return false;
        var ok = Config.moveBarWidget(selectedBar.id, dragSection, dragSourceIndex, targetIndex, targetSection);
        clearDragState();
        return ok;
    }

    function toggleWidgetEnabled(section, widgetInstance) {
        if (!selectedBar || !widgetInstance)
            return;
        Config.updateBarWidget(selectedBar.id, section, widgetInstance.instanceId, {
            enabled: widgetInstance.enabled === false
        });
    }

    function updateSpacerSize(value) {
        if (!selectedBar || !editingWidget)
            return;
        var settings = editingWidget.settings ? JSON.parse(JSON.stringify(editingWidget.settings)) : {};
        settings.size = value;
        Config.updateBarWidget(selectedBar.id, settingsSection, editingWidget.instanceId, {
            settings: settings
        });
    }

    function updateEditingWidgetSetting(key, value) {
        if (!selectedBar || !editingWidget)
            return;
        var settings = editingWidget.settings ? JSON.parse(JSON.stringify(editingWidget.settings)) : {};
        settings[key] = value;
        Config.updateBarWidget(selectedBar.id, settingsSection, editingWidget.instanceId, {
            settings: settings
        });
    }

    function isSystemStatWidget(widgetType) {
        return widgetType === "cpuStatus" || widgetType === "ramStatus" || widgetType === "gpuStatus";
    }

    function isSummaryDisplayWidget(widgetType) {
        return widgetType === "weather" || widgetType === "network" || widgetType === "audio" || widgetType === "battery";
    }

    function isWindowTitleWidget(widgetType) {
        return widgetType === "windowTitle";
    }

    function isMediaBarWidget(widgetType) {
        return widgetType === "mediaBar";
    }

    function isKeyboardLayoutWidget(widgetType) {
        return widgetType === "keyboardLayout";
    }

    function isDateTimeWidget(widgetType) {
        return widgetType === "dateTime";
    }

    function isNotificationsWidget(widgetType) {
        return widgetType === "notifications";
    }

    function isTrayWidget(widgetType) {
        return widgetType === "tray";
    }

    function isTaskbarWidget(widgetType) {
        return widgetType === "taskbar";
    }

    function isWorkspacesWidget(widgetType) {
        return widgetType === "workspaces";
    }

    function isUpdatesWidget(widgetType) {
        return widgetType === "updates";
    }

    function isBluetoothWidget(widgetType) {
        return widgetType === "bluetooth";
    }

    function isMusicWidget(widgetType) {
        return widgetType === "music";
    }

    function isPrinterWidget(widgetType) {
        return widgetType === "printer";
    }

    function isPrivacyWidget(widgetType) {
        return widgetType === "privacy";
    }

    function isRecordingWidget(widgetType) {
        return widgetType === "recording";
    }

    function isCavaWidget(widgetType) {
        return widgetType === "cava";
    }

    function isSeparatorWidget(widgetType) {
        return widgetType === "separator";
    }

    function statDisplayModeLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var mode = String(settings.displayMode || "auto");
        if (mode === "full")
            return "Full";
        if (mode === "compact")
            return "Compact";
        if (mode === "icon")
            return "Icon";
        return "Auto";
    }

    function statValueStyleLabel(widgetInstance) {
        var widgetType = widgetInstance ? String(widgetInstance.widgetType || "") : "";
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var style = String(settings.valueStyle || (widgetType === "ramStatus" ? "usage" : "percent"));
        if (style === "usageTemp")
            return "Usage + Temp";
        if (style === "usage")
            return "Usage";
        return "Percent";
    }

    function summaryDisplayModeLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var mode = String(settings.displayMode || "auto");
        if (mode === "full")
            return "Full";
        if (mode === "icon")
            return "Icon";
        return "Auto";
    }

    function keyboardLayoutModeLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        return String(settings.labelMode || "short") === "full" ? "Full" : "Short";
    }

    function windowTitleDetailsLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var parts = [];
        if (settings.showAppIcon !== false)
            parts.push("Icon");
        if (settings.showGitStatus !== false)
            parts.push("Git");
        if (settings.showMediaContext !== false)
            parts.push("Media");
        return parts.length > 0 ? parts.join(" + ") : "Title Only";
    }

    function mediaBarTextWidth(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var parsed = parseInt(settings.maxTextWidth !== undefined ? settings.maxTextWidth : 150, 10);
        return isNaN(parsed) ? 150 : parsed;
    }

    function taskbarSummary(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var buttonSize = parseInt(settings.buttonSize !== undefined ? settings.buttonSize : 32, 10);
        var iconSize = parseInt(settings.iconSize !== undefined ? settings.iconSize : 20, 10);
        var maxUnpinned = parseInt(settings.maxUnpinned !== undefined ? settings.maxUnpinned : 0, 10);
        return String(isNaN(buttonSize) ? 32 : buttonSize) + "px buttons • " + String(isNaN(iconSize) ? 20 : iconSize) + "px icons" + (maxUnpinned > 0 ? " • +" + maxUnpinned + " unpinned" : "");
    }

    function traySummary(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var itemSize = parseInt(settings.itemSize !== undefined ? settings.itemSize : 24, 10);
        var iconSize = parseInt(settings.iconSize !== undefined ? settings.iconSize : 18, 10);
        return String(isNaN(itemSize) ? 24 : itemSize) + "px items • " + String(isNaN(iconSize) ? 18 : iconSize) + "px icons";
    }

    function notificationBadgeLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var badgeStyle = String(settings.badgeStyle || "dot");
        if (badgeStyle === "count")
            return "Count";
        if (badgeStyle === "off")
            return "Off";
        return "Dot";
    }

    function workspaceSummary(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var parts = [];
        parts.push(settings.showAddButton !== false ? "Add On" : "Add Off");
        parts.push(settings.showMiniMap !== false ? "Mini-map On" : "Mini-map Off");
        return parts.join(" • ");
    }

    function musicTextWidth(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var parsed = parseInt(settings.maxTextWidth !== undefined ? settings.maxTextWidth : 100, 10);
        return isNaN(parsed) ? 100 : parsed;
    }

    function printerBadgeLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var badgeStyle = String(settings.badgeStyle || "count");
        if (badgeStyle === "dot")
            return "Dot";
        if (badgeStyle === "off")
            return "Off";
        return "Count";
    }

    function pulseDotLabel(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        return settings.showPulseDot !== false ? "Pulse On" : "Pulse Off";
    }

    function cavaBarCount(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var parsed = parseInt(settings.barCount !== undefined ? settings.barCount : 8, 10);
        return isNaN(parsed) ? 8 : parsed;
    }

    function separatorSummary(widgetInstance) {
        var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
        var thickness = parseInt(settings.thickness !== undefined ? settings.thickness : 1, 10);
        var length = parseInt(settings.length !== undefined ? settings.length : 20, 10);
        var opacity = Number(settings.opacity !== undefined ? settings.opacity : 0.8);
        return String(isNaN(thickness) ? 1 : thickness) + "px • " + String(isNaN(length) ? 20 : length) + "px • " + (isNaN(opacity) ? "80%" : Math.round(opacity * 100) + "%");
    }

    function loadPluginSettingsPane() {
        if (!pluginSettingsLoader)
            return;
        pluginSettingsLoader.source = "";
        if (!widgetSettingsOpen || editingPluginId === "" || !editingPluginHasSettings)
            return;
        if (!editingPluginCanWriteSettings) {
            pluginSettingsError = "This plugin does not have settings_write permission.";
            return;
        }
        var src = PluginService.pluginSettingsSource(editingPluginId);
        if (src === "") {
            pluginSettingsError = "Plugin settings entry point is missing.";
            return;
        }
        var api = PluginService.getPluginAPI(editingPluginId);
        pluginSettingsLoader.setSource(src, {
            pluginApi: api,
            pluginManifest: PluginService.pluginById(editingPluginId),
            pluginService: PluginService
        });
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Bar Widgets"
        iconName: "󰖲"
        subtitle: "Manage the widget composition for each bar independently."

        SettingsCard {
            title: "Active Bar"
            iconName: "󰕮"
            description: root.selectedBar ? "Choose which bar to manage before editing sections below." : "Create a bar first."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                Repeater {
                    model: Config.barConfigs
                    delegate: SharedWidgets.FilterChip {
                        required property var modelData
                        label: modelData.name || "Bar"
                        selected: Config.selectedBarId === modelData.id
                        onClicked: Config.setSelectedBar(modelData.id)
                    }
                }
            }
        }

        Repeater {
            model: ["left", "center", "right"]
            delegate: SettingsCard {
                id: widgetSectionCard
                required property string modelData
                readonly property string sectionKey: modelData
                title: root.sectionLabel(sectionKey) + " Section"
                iconName: sectionKey === "left" ? "󰁍" : (sectionKey === "center" ? "󰇘" : "󰁔")
                description: "Drag to reorder widgets, or use the arrow buttons as a fallback."
                visible: !!root.selectedBar

                ColumnLayout {
                    id: sectionColumn
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        Layout.fillWidth: true
                        text: root.sectionWidgets(sectionKey).length > 0 ? "Current widgets: " + root.sectionWidgets(sectionKey).length : "Current widgets: none"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.sectionWidgets(sectionKey).length === 0
                        radius: Colors.radiusSmall
                        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
                        border.color: root.dragReorderEnabled && root.dragTargetSection === sectionKey && root.dragTargetIndex === 0 ? Colors.primary : Colors.border
                        border.width: root.dragReorderEnabled && root.dragTargetSection === sectionKey && root.dragTargetIndex === 0 ? 2 : 1
                        implicitHeight: emptyDropColumn.implicitHeight + Colors.spacingM * 2

                        DropArea {
                            anchors.fill: parent
                            enabled: root.dragReorderEnabled
                            keys: ["bar-widget"]
                            onEntered: function (drag) {
                                if (root.dragSourceIndex < 0)
                                    return;
                                root.dragTargetSection = sectionKey;
                                root.dragTargetIndex = 0;
                            }
                            onExited: {
                                if (root.dragTargetSection === sectionKey && root.dragTargetIndex === 0) {
                                    root.dragTargetSection = "";
                                    root.dragTargetIndex = -1;
                                }
                            }
                            onDropped: function (drop) {
                                root.moveDraggedWidget(sectionKey, 0);
                            }
                        }

                        Column {
                            id: emptyDropColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            Text {
                                text: (root.dragReorderEnabled && root.dragSourceIndex >= 0) ? "Drop widget here" : "No widgets in this section yet"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            Text {
                                text: (root.dragReorderEnabled && root.dragSourceIndex >= 0) ? "Release to move the dragged widget into " + root.sectionLabel(sectionKey).toLowerCase() + "." : "Add one below, then drag it into place or use the arrow buttons."
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Repeater {
                        model: root.sectionWidgets(sectionKey).length
                        delegate: Item {
                            id: widgetRow
                            Layout.fillWidth: true
                            width: sectionColumn.width
                            implicitHeight: cardLayout.implicitHeight + Colors.spacingM * 2
                            height: implicitHeight
                            required property int index
                            readonly property string sectionKey: widgetSectionCard.sectionKey
                            readonly property var widgetInstance: root.sectionWidgets(sectionKey)[index]
                            readonly property bool dropBeforeActive: root.dragTargetSection === widgetRow.sectionKey && root.dragTargetIndex === widgetRow.index

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }
                                visible: root.dragReorderEnabled && widgetRow.dropBeforeActive
                                height: 10
                                radius: Colors.radiusXXS
                                color: Colors.withAlpha(Colors.primary, 0.22)
                                border.color: Colors.primary
                                border.width: 1
                                z: 3
                            }

                            DropArea {
                                anchors.fill: parent
                                enabled: root.dragReorderEnabled
                                keys: ["bar-widget"]
                                onEntered: function (drag) {
                                    if (root.dragSourceIndex < 0)
                                        return;
                                    root.dragTargetSection = widgetRow.sectionKey;
                                    root.dragTargetIndex = widgetRow.index;
                                }
                                onExited: {
                                    if (root.dragTargetSection === widgetRow.sectionKey && root.dragTargetIndex === widgetRow.index) {
                                        root.dragTargetSection = "";
                                        root.dragTargetIndex = -1;
                                    }
                                }
                                onDropped: function (drop) {
                                    root.moveDraggedWidget(widgetRow.sectionKey, widgetRow.index);
                                }
                            }

                            Rectangle {
                                id: card
                                anchors.fill: parent
                                implicitHeight: cardLayout.implicitHeight + Colors.spacingM * 2
                                radius: Colors.radiusSmall
                                color: Colors.modalFieldSurface
                                border.color: Colors.border
                                border.width: 1
                                opacity: dragHandle.dragActive ? 0.7 : 1.0

                                Behavior on y {
                                    enabled: !dragHandle.dragActive

                                    NumberAnimation {
                                        duration: Colors.durationFast
                                    }
                                }

                                ColumnLayout {
                                    id: cardLayout
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: Colors.spacingM
                                    }
                                    spacing: Colors.spacingS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingS

                                        Text {
                                            text: "󰆾"
                                            color: Colors.textDisabled
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeLarge
                                        }

                                        Text {
                                            text: BarWidgetRegistry.displayIcon(widgetRow.widgetInstance.widgetType)
                                            color: Colors.primary
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeLarge
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Colors.spacingXXS

                                            Text {
                                                text: BarWidgetRegistry.displayName(widgetRow.widgetInstance.widgetType)
                                                color: Colors.text
                                                font.pixelSize: Colors.fontSizeMedium
                                                font.weight: Font.Medium
                                                Layout.fillWidth: true
                                                wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
                                                elide: root.compactMode ? Text.ElideNone : Text.ElideRight
                                            }

                                            Text {
                                                text: BarWidgetRegistry.description(widgetRow.widgetInstance.widgetType)
                                                color: Colors.textSecondary
                                                font.pixelSize: Colors.fontSizeXS
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }

                                            Text {
                                                text: root.dragReorderEnabled ? "Drag to reorder within or across sections, or use the arrow buttons." : "Use the arrow buttons to reorder within this section."
                                                color: Colors.textSecondary
                                                font.pixelSize: Colors.fontSizeXS
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        width: parent.width
                                        spacing: Colors.spacingS

                                        SharedWidgets.FilterChip {
                                            label: widgetRow.widgetInstance.enabled === false ? "Hidden" : "Visible"
                                            selected: widgetRow.widgetInstance.enabled !== false
                                            onClicked: root.toggleWidgetEnabled(widgetRow.sectionKey, widgetRow.widgetInstance)
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isSystemStatWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Mode: " + root.statDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isSystemStatWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Value: " + root.statValueStyleLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isSummaryDisplayWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isWindowTitleWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.windowTitleDetailsLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isMediaBarWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isMediaBarWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Text: " + root.mediaBarTextWidth(widgetRow.widgetInstance) + "px"
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isKeyboardLayoutWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Label: " + root.keyboardLayoutModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isDateTimeWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isDateTimeWidget(widgetRow.widgetInstance.widgetType)
                                            label: (widgetRow.widgetInstance.settings && widgetRow.widgetInstance.settings.showDate !== false) ? "Date On" : "Date Off"
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isNotificationsWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isNotificationsWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Badge: " + root.notificationBadgeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isTrayWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.traySummary(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isTaskbarWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.taskbarSummary(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isWorkspacesWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.workspaceSummary(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isUpdatesWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isBluetoothWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isMusicWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isMusicWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Text: " + root.musicTextWidth(widgetRow.widgetInstance) + "px"
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isPrinterWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isPrinterWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Badge: " + root.printerBadgeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isPrivacyWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isPrivacyWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.pulseDotLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isRecordingWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Display: " + root.summaryDisplayModeLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isRecordingWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.pulseDotLabel(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isCavaWidget(widgetRow.widgetInstance.widgetType)
                                            label: "Bars: " + root.cavaBarCount(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: root.isSeparatorWidget(widgetRow.widgetInstance.widgetType)
                                            label: root.separatorSummary(widgetRow.widgetInstance)
                                            selected: false
                                            enabled: false
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            label: "↑"
                                            enabled: widgetRow.index > 0
                                            onClicked: root.moveWidget(widgetRow.sectionKey, widgetRow.index, -1)
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            label: "↓"
                                            enabled: widgetRow.index < (root.sectionWidgets(widgetRow.sectionKey).length - 1)
                                            onClicked: root.moveWidget(widgetRow.sectionKey, widgetRow.index, 1)
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            iconName: "󰍜"
                                            label: "Settings"
                                            enabled: BarWidgetRegistry.supportsSettings(widgetRow.widgetInstance.widgetType)
                                            onClicked: root.openWidgetSettings(widgetRow.sectionKey, widgetRow.widgetInstance.instanceId)
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            iconName: "󰅖"
                                            label: "Remove"
                                            onClicked: root.removeWidget(widgetRow.sectionKey, widgetRow.widgetInstance.instanceId)
                                        }
                                    }
                                }
                            }

                            Item {
                                id: dragProxy
                                width: widgetRow.width
                                height: widgetRow.height
                                visible: false
                                Drag.active: root.dragReorderEnabled && dragHandle.dragActive
                                Drag.source: dragProxy
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2
                                Drag.keys: ["bar-widget"]
                            }

                            SettingsDragHandle {
                                id: dragHandle
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    topMargin: Colors.spacingS
                                    rightMargin: Colors.spacingS
                                }
                                enabled: root.dragReorderEnabled
                                visible: root.dragReorderEnabled
                                dragTarget: root.dragReorderEnabled ? card : null
                                onPressedChanged: {
                                    root.dragSection = widgetRow.sectionKey;
                                    root.dragSourceIndex = widgetRow.index;
                                    root.dragTargetSection = widgetRow.sectionKey;
                                    root.dragTargetIndex = widgetRow.index;
                                }
                                onReleased: function (wasDragging) {
                                    card.x = 0;
                                    card.y = 0;
                                    if (wasDragging && dragProxy.Drag.active)
                                        dragProxy.Drag.drop();
                                    else
                                        root.clearDragState();
                                }
                                onDragActiveChanged: {
                                    if (!dragActive) {
                                        card.x = 0;
                                        card.y = 0;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 12
                        radius: Colors.radiusXXS
                        visible: root.sectionWidgets(sectionKey).length > 0 && root.dragReorderEnabled && root.dragSourceIndex >= 0 && root.dragTargetSection === sectionKey && root.dragTargetIndex === root.sectionWidgets(sectionKey).length
                        color: Colors.withAlpha(Colors.primary, 0.22)
                        border.color: Colors.primary
                        border.width: 1
                    }

                    DropArea {
                        Layout.fillWidth: true
                        height: root.sectionWidgets(sectionKey).length > 0 ? 28 : 0
                        visible: root.dragReorderEnabled && root.sectionWidgets(sectionKey).length > 0
                        enabled: root.dragReorderEnabled
                        keys: ["bar-widget"]
                        onEntered: function (drag) {
                            if (root.dragSourceIndex < 0)
                                return;
                            root.dragTargetSection = sectionKey;
                            root.dragTargetIndex = root.sectionWidgets(sectionKey).length;
                        }
                        onExited: {
                            if (root.dragTargetSection === sectionKey && root.dragTargetIndex === root.sectionWidgets(sectionKey).length) {
                                root.dragTargetSection = "";
                                root.dragTargetIndex = -1;
                            }
                        }
                        onDropped: function (drop) {
                            root.moveDraggedWidget(sectionKey, root.sectionWidgets(sectionKey).length);
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.dragReorderEnabled && root.dragSourceIndex >= 0 ? "Drop at end of " + root.sectionLabel(sectionKey).toLowerCase() : ""
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }
                }

                SettingsActionButton {
                    Layout.fillWidth: true
                    emphasized: true
                    iconName: "󰐕"
                    label: "Add Widget"
                    onClicked: root.openWidgetPicker(sectionKey)
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.widgetPickerOpen
        color: Qt.rgba(0, 0, 0, 0.45)
        z: 20

        MouseArea {
            anchors.fill: parent
            onClicked: root.widgetPickerOpen = false
        }

        Rectangle {
            width: Math.min(root.compactMode ? 560 : 640, parent.width - root.overlayInset * 2)
            height: Math.min(560, parent.height - root.overlayInset * 2)
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: Math.max(root.overlayInset, (parent.height - height) / 2)
            anchors.leftMargin: Math.max(root.overlayInset, (parent.width - width) / 2)
            radius: Colors.radiusLarge
            color: Colors.popupSurface
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingLarge
                spacing: Colors.spacingM

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Text {
                        width: root.compactMode ? parent.width : Math.max(0, parent.width - closePickerButton.implicitWidth - Colors.spacingS)
                        text: "Add Widget to " + root.sectionLabel(root.addSection)
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeXL
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }

                    SettingsActionButton {
                        id: closePickerButton
                        compact: true
                        iconName: "󰅖"
                        label: "Close"
                        onClicked: root.widgetPickerOpen = false
                    }
                }

                SettingsTextInputRow {
                    label: "Search"
                    leadingIcon: "󰍉"
                    placeholderText: "Filter widgets by name"
                    text: root.widgetSearchQuery
                    onTextEdited: value => root.widgetSearchQuery = value
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: pickerColumn.implicitHeight

                    Column {
                        id: pickerColumn
                        width: parent.width
                        spacing: Colors.spacingS

                        Repeater {
                            model: BarWidgetRegistry.search(root.widgetSearchQuery, root.addSection)
                            delegate: SettingsListRow {
                                required property var modelData
                                minimumHeight: root.compactMode ? 88 : 64

                                Text {
                                    text: modelData.icon
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeLarge
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingXXS

                                    Text {
                                        text: modelData.label
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeMedium
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: modelData.description || ""
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    width: parent.width
                                    spacing: Colors.spacingS

                                    SettingsActionButton {
                                        compact: true
                                        emphasized: true
                                        iconName: "󰐕"
                                        label: "Add"
                                        onClicked: root.addWidget(modelData.widgetType)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.widgetSettingsOpen
        color: Qt.rgba(0, 0, 0, 0.45)
        z: 21

        MouseArea {
            anchors.fill: parent
            onClicked: root.widgetSettingsOpen = false
        }

        Rectangle {
            width: Math.min(460, parent.width - root.overlayInset * 2)
            height: Math.min(settingsFlick.contentHeight, parent.height - root.overlayInset * 2)
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: Math.max(root.overlayInset, (parent.height - height) / 2)
            anchors.leftMargin: Math.max(root.overlayInset, (parent.width - width) / 2)
            radius: Colors.radiusLarge
            color: Colors.popupSurface
            border.color: Colors.border
            border.width: 1

            Flickable {
                id: settingsFlick
                anchors.fill: parent
                anchors.margins: Colors.paddingLarge
                clip: true
                contentHeight: settingsColumn.implicitHeight

                ColumnLayout {
                    id: settingsColumn
                    width: settingsFlick.width
                    spacing: Colors.spacingM

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        Text {
                            width: root.compactMode ? parent.width : Math.max(0, parent.width - closeSettingsButton.implicitWidth - Colors.spacingS)
                            text: root.editingWidget ? (BarWidgetRegistry.displayName(root.editingWidget.widgetType) + " Settings") : "Widget Settings"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeXL
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }

                        SettingsActionButton {
                            id: closeSettingsButton
                            compact: true
                            iconName: "󰅖"
                            label: "Close"
                            onClicked: root.widgetSettingsOpen = false
                        }
                    }

                    SettingsInfoCallout {
                        visible: !root.editingWidget || (!BarWidgetRegistry.supportsSettings(root.editingWidget.widgetType) && root.editingPluginId === "")
                        title: "No configurable options"
                        body: "This widget does not expose custom per-instance settings yet."
                    }

                    SettingsInfoCallout {
                        visible: root.editingPluginId !== "" && root.editingPluginHasSettings && !root.editingPluginCanWriteSettings
                        title: "Permission required"
                        body: "This plugin is missing settings_write permission in its manifest."
                    }

                    SettingsInfoCallout {
                        visible: root.pluginSettingsError !== ""
                        title: "Plugin settings failed to load"
                        body: root.pluginSettingsError
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.editingWidget.widgetType === "spacer"
                        label: "Spacer Size"
                        min: 8
                        max: 80
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.size !== undefined ? root.editingWidget.settings.size : 24
                        onMoved: value => root.updateSpacerSize(value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isSystemStatWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only. Compact mode may shorten long values automatically to keep vertical bars narrow."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            {
                                value: "auto",
                                label: "Auto"
                            },
                            {
                                value: "full",
                                label: "Full"
                            },
                            {
                                value: "compact",
                                label: "Compact"
                            },
                            {
                                value: "icon",
                                label: "Icon"
                            }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isSystemStatWidget(root.editingWidget.widgetType)
                        label: "Value Style"
                        description: root.editingWidget && root.editingWidget.widgetType === "ramStatus" ? "Choose whether memory shows percent used or the current used-memory value. Compact mode can still fall back to percent when the usage text is too long." : "Choose whether this stat shows percent only, usage text, or usage with temperature. Compact mode can shorten long values automatically."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.valueStyle ? root.editingWidget.settings.valueStyle : (root.editingWidget && root.editingWidget.widgetType === "ramStatus" ? "usage" : "percent")
                        options: root.editingWidget && root.editingWidget.widgetType === "ramStatus" ? [
                            {
                                value: "usage",
                                label: "Usage"
                            },
                            {
                                value: "percent",
                                label: "Percent"
                            }
                        ] : [
                            {
                                value: "percent",
                                label: "Percent"
                            },
                            {
                                value: "usage",
                                label: "Usage"
                            },
                            {
                                value: "usageTemp",
                                label: "Usage + Temp"
                            }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("valueStyle", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isSummaryDisplayWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            {
                                value: "auto",
                                label: "Auto"
                            },
                            {
                                value: "full",
                                label: "Full"
                            },
                            {
                                value: "icon",
                                label: "Icon"
                            }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isWindowTitleWidget(root.editingWidget.widgetType)
                        label: "Title Width"
                        icon: "󰨈"
                        min: 120
                        max: 520
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.maxTitleWidth !== undefined ? root.editingWidget.settings.maxTitleWidth : 300
                        onMoved: value => root.updateEditingWidgetSetting("maxTitleWidth", value)
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isWindowTitleWidget(root.editingWidget.widgetType)
                        label: "App Icon"
                        icon: "󰀻"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showAppIcon !== false : true
                        enabledText: "Show the active app icon before the title."
                        disabledText: "Hide the app icon and show only textual context."
                        onToggled: root.updateEditingWidgetSetting("showAppIcon", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showAppIcon !== false))
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isWindowTitleWidget(root.editingWidget.widgetType)
                        label: "Git Status"
                        icon: "󰊢"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showGitStatus !== false : true
                        enabledText: "Show inline repository status next to the active window title."
                        disabledText: "Hide inline repository status from the title widget."
                        onToggled: root.updateEditingWidgetSetting("showGitStatus", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showGitStatus !== false))
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isWindowTitleWidget(root.editingWidget.widgetType)
                        label: "Media Context"
                        icon: "󰎆"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showMediaContext !== false : true
                        enabledText: "Show the mini media context badge when media is active."
                        disabledText: "Hide inline media context from the title widget."
                        onToggled: root.updateEditingWidgetSetting("showMediaContext", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showMediaContext !== false))
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isMediaBarWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the media widget adapts to bar orientation automatically, always shows track text, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            {
                                value: "auto",
                                label: "Auto"
                            },
                            {
                                value: "full",
                                label: "Full"
                            },
                            {
                                value: "icon",
                                label: "Icon"
                            }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isMediaBarWidget(root.editingWidget.widgetType)
                        label: "Track Text Width"
                        icon: "󰛇"
                        min: 80
                        max: 240
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.maxTextWidth !== undefined ? root.editingWidget.settings.maxTextWidth : 150
                        onMoved: value => root.updateEditingWidgetSetting("maxTextWidth", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isKeyboardLayoutWidget(root.editingWidget.widgetType)
                        label: "Label Mode"
                        description: "Choose between the compact three-letter abbreviation or the full layout name."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.labelMode ? root.editingWidget.settings.labelMode : "short"
                        options: [
                            {
                                value: "short",
                                label: "Short"
                            },
                            {
                                value: "full",
                                label: "Full"
                            }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("labelMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isDateTimeWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the clock adapts to bar orientation automatically, always shows the full time row, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isDateTimeWidget(root.editingWidget.widgetType)
                        label: "Show Date"
                        icon: "󰃭"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showDate !== false : true
                        enabledText: "Show the date segment alongside the time when space allows."
                        disabledText: "Show only the time in the bar widget."
                        onToggled: root.updateEditingWidgetSetting("showDate", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showDate !== false))
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isNotificationsWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the notifications widget adapts to bar orientation automatically, always shows extra status text, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isNotificationsWidget(root.editingWidget.widgetType)
                        label: "Badge Style"
                        description: "Choose whether unread notifications show as a dot, a count, or no badge at all."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.badgeStyle ? root.editingWidget.settings.badgeStyle : "dot"
                        options: [
                            { value: "dot", label: "Dot" },
                            { value: "count", label: "Count" },
                            { value: "off", label: "Off" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("badgeStyle", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isTrayWidget(root.editingWidget.widgetType)
                        label: "Item Size"
                        icon: "󰍹"
                        min: 18
                        max: 40
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.itemSize !== undefined ? root.editingWidget.settings.itemSize : 24
                        onMoved: value => root.updateEditingWidgetSetting("itemSize", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isTrayWidget(root.editingWidget.widgetType)
                        label: "Icon Size"
                        icon: "󰀻"
                        min: 12
                        max: 32
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.iconSize !== undefined ? root.editingWidget.settings.iconSize : 18
                        onMoved: value => root.updateEditingWidgetSetting("iconSize", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isTrayWidget(root.editingWidget.widgetType)
                        label: "Spacing"
                        icon: "󰝗"
                        min: 2
                        max: 16
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.spacing !== undefined ? root.editingWidget.settings.spacing : 6
                        onMoved: value => root.updateEditingWidgetSetting("spacing", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isTaskbarWidget(root.editingWidget.widgetType)
                        label: "Button Size"
                        icon: "󰝗"
                        min: 24
                        max: 56
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.buttonSize !== undefined ? root.editingWidget.settings.buttonSize : 32
                        onMoved: value => root.updateEditingWidgetSetting("buttonSize", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isTaskbarWidget(root.editingWidget.widgetType)
                        label: "Icon Size"
                        icon: "󰀻"
                        min: 14
                        max: 36
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.iconSize !== undefined ? root.editingWidget.settings.iconSize : 20
                        onMoved: value => root.updateEditingWidgetSetting("iconSize", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isTaskbarWidget(root.editingWidget.widgetType)
                        label: "Max Unpinned Apps"
                        icon: "󰇚"
                        min: 0
                        max: 20
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.maxUnpinned !== undefined ? root.editingWidget.settings.maxUnpinned : 0
                        onMoved: value => root.updateEditingWidgetSetting("maxUnpinned", value)
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isTaskbarWidget(root.editingWidget.widgetType)
                        label: "Running Indicator"
                        icon: "󰄯"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showRunningIndicator !== false : true
                        enabledText: "Show the running-state dot on active task buttons."
                        disabledText: "Hide the running-state indicator dot."
                        onToggled: root.updateEditingWidgetSetting("showRunningIndicator", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showRunningIndicator !== false))
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isTaskbarWidget(root.editingWidget.widgetType)
                        label: "Separator"
                        icon: "󰇘"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showSeparator !== false : true
                        enabledText: "Separate pinned apps from unpinned running apps."
                        disabledText: "Remove the divider between pinned and unpinned apps."
                        onToggled: root.updateEditingWidgetSetting("showSeparator", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showSeparator !== false))
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isWorkspacesWidget(root.editingWidget.widgetType)
                        label: "Add Button"
                        icon: "󰐕"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showAddButton !== false : true
                        enabledText: "Show the quick add-workspace button at the end of the strip."
                        disabledText: "Hide the add-workspace button from this widget instance."
                        onToggled: root.updateEditingWidgetSetting("showAddButton", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showAddButton !== false))
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isWorkspacesWidget(root.editingWidget.widgetType)
                        label: "Mini-map"
                        icon: "󰍹"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showMiniMap !== false : true
                        enabledText: "Show live mini-map window previews inside workspace pills."
                        disabledText: "Hide mini-map previews and keep the pills text-only."
                        onToggled: root.updateEditingWidgetSetting("showMiniMap", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showMiniMap !== false))
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isUpdatesWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the updates widget adapts to bar orientation automatically, always shows its count, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isBluetoothWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the Bluetooth widget adapts to bar orientation automatically, always shows status text, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isMusicWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the music widget adapts to bar orientation automatically, always shows track text, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isMusicWidget(root.editingWidget.widgetType)
                        label: "Track Text Width"
                        icon: "󰛇"
                        min: 60
                        max: 220
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.maxTextWidth !== undefined ? root.editingWidget.settings.maxTextWidth : 100
                        onMoved: value => root.updateEditingWidgetSetting("maxTextWidth", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isPrinterWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the printer widget adapts to bar orientation automatically, always shows job badges, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isPrinterWidget(root.editingWidget.widgetType)
                        label: "Badge Style"
                        description: "Choose whether active print jobs show as a count badge, a dot, or no badge."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.badgeStyle ? root.editingWidget.settings.badgeStyle : "count"
                        options: [
                            { value: "count", label: "Count" },
                            { value: "dot", label: "Dot" },
                            { value: "off", label: "Off" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("badgeStyle", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isPrivacyWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the privacy widget adapts to bar orientation automatically, always shows text, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isPrivacyWidget(root.editingWidget.widgetType)
                        label: "Pulse Dot"
                        icon: "󰄯"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showPulseDot !== false : true
                        enabledText: "Show the animated activity dot beside the privacy icon."
                        disabledText: "Hide the animated pulse dot and keep only the icon/text."
                        onToggled: root.updateEditingWidgetSetting("showPulseDot", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showPulseDot !== false))
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isRecordingWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether the recording widget adapts to bar orientation automatically, always shows REC text, or stays icon-only."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode ? root.editingWidget.settings.displayMode : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsToggleRow {
                        visible: !!root.editingWidget && root.isRecordingWidget(root.editingWidget.widgetType)
                        label: "Pulse Dot"
                        icon: "󰄯"
                        checked: root.editingWidget && root.editingWidget.settings ? root.editingWidget.settings.showPulseDot !== false : true
                        enabledText: "Show the animated recording dot beside the label."
                        disabledText: "Hide the recording pulse dot."
                        onToggled: root.updateEditingWidgetSetting("showPulseDot", !(root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.showPulseDot !== false))
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isCavaWidget(root.editingWidget.widgetType)
                        label: "Bar Count"
                        icon: "󰎈"
                        min: 4
                        max: 20
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.barCount !== undefined ? root.editingWidget.settings.barCount : 8
                        onMoved: value => root.updateEditingWidgetSetting("barCount", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isSeparatorWidget(root.editingWidget.widgetType)
                        label: "Thickness"
                        icon: "󰇘"
                        min: 1
                        max: 8
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.thickness !== undefined ? root.editingWidget.settings.thickness : 1
                        onMoved: value => root.updateEditingWidgetSetting("thickness", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isSeparatorWidget(root.editingWidget.widgetType)
                        label: "Length"
                        icon: "󰝗"
                        min: 8
                        max: 64
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.length !== undefined ? root.editingWidget.settings.length : 20
                        onMoved: value => root.updateEditingWidgetSetting("length", value)
                    }

                    SettingsSliderRow {
                        visible: !!root.editingWidget && root.isSeparatorWidget(root.editingWidget.widgetType)
                        label: "Opacity"
                        icon: "󰖔"
                        min: 0.1
                        max: 1.0
                        step: 0.05
                        unit: "%"
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.opacity !== undefined ? root.editingWidget.settings.opacity : 0.8
                        onMoved: value => root.updateEditingWidgetSetting("opacity", value)
                    }

                    SharedWidgets.SshWidgetSettings {
                        Layout.fillWidth: true
                        visible: !!root.editingWidget && root.editingWidget.widgetType === "ssh"
                        widgetInstance: root.editingWidget
                    }

                    Loader {
                        id: pluginSettingsLoader
                        Layout.fillWidth: true
                        visible: root.editingPluginId !== "" && root.editingPluginHasSettings && root.editingPluginCanWriteSettings && status !== Loader.Error
                        onStatusChanged: {
                            if (status === Loader.Error)
                                root.pluginSettingsError = errorString();
                            else if (status === Loader.Ready)
                                root.pluginSettingsError = "";
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property bool _destroyed: false
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
    property bool applyingPendingBarWidgetTarget: false
    property int pickerCatalogRevision: 0
    property var editingWidget: null
    property var editingWidgetSchema: []
    readonly property int overlayInset: root.tightSpacing ? 20 : 40
    readonly property bool dragReorderEnabled: true
    readonly property var availablePickerWidgets: availableWidgetsForPicker()
    readonly property string dragSection: widgetReorderState.sourceListId
    readonly property int dragSourceIndex: widgetReorderState.sourceIndex
    readonly property string dragTargetSection: widgetReorderState.targetListId
    readonly property int dragTargetIndex: widgetReorderState.targetIndex

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
        Qt.callLater(function() { if (_destroyed) return; refreshEditingWidgetState(); });
    }
    onEditingPluginIdChanged: {
        if (widgetSettingsOpen)
            Qt.callLater(function() { if (_destroyed) return; loadPluginSettingsPane(); });
    }
    onSettingsSectionChanged: Qt.callLater(function() { if (_destroyed) return; refreshEditingWidgetState(); })
    onSettingsInstanceIdChanged: Qt.callLater(function() { if (_destroyed) return; refreshEditingWidgetState(); })

    Connections {
        target: Config
        function onBarConfigsChanged() {
            Qt.callLater(function() { if (root._destroyed) return; root.refreshEditingWidgetState(); });
        }
    }

    Connections {
        target: PluginService
        function onPluginCatalogUpdated() {
            root.pickerCatalogRevision += 1;
        }
        function onPluginRuntimeUpdated() {
            root.pickerCatalogRevision += 1;
        }
    }

    SettingsReorderState {
        id: widgetReorderState
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
        pickerCatalogRevision += 1;
        widgetPickerOpen = true;
    }

    function refreshEditingWidgetState() {
        if (!widgetSettingsOpen || !selectedBar || settingsSection === "" || settingsInstanceId === "") {
            editingWidget = null;
            editingWidgetSchema = [];
            return;
        }
        var widget = Config.widgetInstance(selectedBar.id, settingsSection, settingsInstanceId);
        editingWidget = widget;
        editingWidgetSchema = widget ? BarWidgetRegistry.settingsSchema(widget.widgetType) : [];
    }

    function queuePendingBarWidgetTarget() {
        if (pendingBarWidgetTargetTimer.running)
            pendingBarWidgetTargetTimer.restart();
        else
            pendingBarWidgetTargetTimer.start();
    }

    function applyPendingBarWidgetTarget() {
        if (applyingPendingBarWidgetTarget || !settingsRoot || !settingsRoot.pendingBarWidgetTarget)
            return false;
        applyingPendingBarWidgetTarget = true;
        var target = settingsRoot.pendingBarWidgetTarget;
        var targetBarId = String(target.barId || "");
        var targetSection = String(target.section || "");
        var targetInstanceId = String(target.instanceId || "");
        if (targetBarId === "" || targetSection === "" || targetInstanceId === "") {
            applyingPendingBarWidgetTarget = false;
            return false;
        }
        if (!selectedBar || String(selectedBar.id || "") !== targetBarId) {
            Config.setSelectedBar(targetBarId);
            applyingPendingBarWidgetTarget = false;
            queuePendingBarWidgetTarget();
            return false;
        }
        settingsSection = targetSection;
        settingsInstanceId = targetInstanceId;
        pluginSettingsError = "";
        widgetSettingsOpen = true;
        settingsRoot.pendingBarWidgetTarget = null;
        applyingPendingBarWidgetTarget = false;
        Qt.callLater(function() { if (_destroyed) return; loadPluginSettingsPane(); });
        return true;
    }

    function availableWidgetsForPicker() {
        var _revision = pickerCatalogRevision;
        var items = BarWidgetRegistry.search(widgetSearchQuery, "");
        if (!addSection)
            return items;

        return items.slice().sort(function (a, b) {
            var aScore = String(a.section || "") === addSection ? 0 : 1;
            var bScore = String(b.section || "") === addSection ? 0 : 1;
            if (aScore !== bScore)
                return aScore - bScore;
            return String(a.label || "").localeCompare(String(b.label || ""));
        });
    }

    function openWidgetSettings(section, instanceId) {
        settingsSection = section;
        settingsInstanceId = instanceId;
        pluginSettingsError = "";
        widgetSettingsOpen = true;
        Qt.callLater(function() { if (_destroyed) return; refreshEditingWidgetState(); });
        Qt.callLater(function() { if (_destroyed) return; loadPluginSettingsPane(); });
    }

    Component.onCompleted: queuePendingBarWidgetTarget()
    Component.onDestruction: _destroyed = true
    onSettingsRootChanged: queuePendingBarWidgetTarget()
    onSelectedBarChanged: {
        Qt.callLater(function() { if (_destroyed) return; refreshEditingWidgetState(); });
        if (settingsRoot && settingsRoot.pendingBarWidgetTarget)
            queuePendingBarWidgetTarget();
    }

    Timer {
        id: pendingBarWidgetTargetTimer
        interval: 0
        repeat: false
        onTriggered: root.applyPendingBarWidgetTarget()
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
        widgetReorderState.clear();
    }

    function beginWidgetDrag(section, instanceId, index) {
        widgetReorderState.begin(section, instanceId, index);
    }

    function setWidgetDropTarget(section, index) {
        if (root.dragSourceIndex < 0)
            return;
        widgetReorderState.updateTarget(section, index);
    }

    function clearWidgetDropTarget(section, index) {
        if (widgetReorderState.matchesTarget(section, index))
            widgetReorderState.updateTarget("", -1);
    }

    function moveDraggedWidget(targetSection, targetIndex) {
        if (!selectedBar || widgetReorderState.sourceListId === "" || widgetReorderState.sourceIndex < 0)
            return false;
        if (targetSection === "" || targetIndex < 0)
            return false;
        var ok = Config.moveBarWidget(selectedBar.id, widgetReorderState.sourceListId, widgetReorderState.sourceIndex, targetIndex, targetSection);
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

    function updateEditingWidgetSetting(key, value) {
        if (!selectedBar || !editingWidget)
            return;
        var settings = editingWidget.settings ? JSON.parse(JSON.stringify(editingWidget.settings)) : {};
        settings[key] = value;
        Config.updateBarWidget(selectedBar.id, settingsSection, editingWidget.instanceId, {
            settings: settings
        });
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

    function schemaFieldCurrentValue(field) {
        if (!editingWidget || !field)
            return "";
        var settings = editingWidget.settings ? editingWidget.settings : {};
        if (settings[field.key] !== undefined)
            return settings[field.key];
        var defaults = BarWidgetRegistry.defaultSettings(editingWidget.widgetType);
        if (defaults[field.key] !== undefined)
            return defaults[field.key];
        if (field.type === "toggle")
            return false;
        if (field.type === "slider")
            return field.min !== undefined ? field.min : 0;
        return "";
    }

    Component {
        id: schemaModeField

        SettingsModeRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            icon: field && field.icon ? field.icon : ""
            description: field && field.description ? field.description : ""
            currentValue: root.schemaFieldCurrentValue(field)
            options: field && field.options ? field.options : []
            onModeSelected: value => {
                if (field)
                    root.updateEditingWidgetSetting(field.key, value);
            }
        }
    }

    Component {
        id: schemaSliderField

        SettingsSliderRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            icon: field && field.icon ? field.icon : ""
            min: field && field.min !== undefined ? field.min : 0
            max: field && field.max !== undefined ? field.max : 100
            step: field && field.step !== undefined ? field.step : 1
            unit: field && field.unit ? field.unit : ""
            value: root.schemaFieldCurrentValue(field)
            onMoved: value => {
                if (field)
                    root.updateEditingWidgetSetting(field.key, value);
            }
        }
    }

    Component {
        id: schemaToggleField

        SettingsToggleRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            icon: field && field.icon ? field.icon : ""
            checked: !!root.schemaFieldCurrentValue(field)
            enabledText: field && field.enabledText ? field.enabledText : "Enabled"
            disabledText: field && field.disabledText ? field.disabledText : "Disabled"
            onToggled: {
                if (field)
                    root.updateEditingWidgetSetting(field.key, !root.schemaFieldCurrentValue(field));
            }
        }
    }

    Component {
        id: schemaTextField

        SettingsTextInputRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            leadingIcon: field && field.icon ? field.icon : ""
            placeholderText: field && field.placeholder ? field.placeholder : ""
            text: String(root.schemaFieldCurrentValue(field) || "")
            onTextEdited: value => {
                if (field)
                    root.updateEditingWidgetSetting(field.key, value);
            }
        }
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

            SettingsSelectRow {
                label: "Bar"
                icon: "󰕮"
                description: "Switch the bar you are editing without taking horizontal space away from the widget sections."
                currentValue: String(Config.selectedBarId || "")
                options: Config.barConfigs.map(function (barConfig) {
                    return {
                        value: String(barConfig.id || ""),
                        label: String(barConfig.name || "Bar")
                    };
                })
                onOptionSelected: value => Config.setSelectedBar(value)
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
                        color: Colors.withAlpha(Colors.primary, 0.06)
                        border.color: root.dragReorderEnabled && root.dragTargetSection === sectionKey && root.dragTargetIndex === 0 ? Colors.primary : Colors.border
                        border.width: root.dragReorderEnabled && root.dragTargetSection === sectionKey && root.dragTargetIndex === 0 ? 2 : 1
                        implicitHeight: emptyDropColumn.implicitHeight + Colors.spacingM * 2

                        DropArea {
                            anchors.fill: parent
                            enabled: root.dragReorderEnabled
                            keys: ["bar-widget"]
                            onEntered: function (drag) {
                                root.setWidgetDropTarget(sectionKey, 0);
                            }
                            onExited: {
                                root.clearWidgetDropTarget(sectionKey, 0);
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

                            SettingsDropIndicator {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }
                                active: root.dragReorderEnabled && widgetRow.dropBeforeActive
                                visible: root.dragReorderEnabled && widgetRow.dropBeforeActive
                                z: 3
                            }

                            DropArea {
                                anchors.fill: parent
                                enabled: root.dragReorderEnabled
                                keys: ["bar-widget"]
                                onEntered: function (drag) {
                                    root.setWidgetDropTarget(widgetRow.sectionKey, widgetRow.index);
                                }
                                onExited: {
                                    root.clearWidgetDropTarget(widgetRow.sectionKey, widgetRow.index);
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

                                        Repeater {
                                            model: BarWidgetRegistry.summaryChips(widgetRow.widgetInstance)

                                            delegate: SharedWidgets.FilterChip {
                                                required property var modelData
                                                label: String(modelData || "")
                                                selected: false
                                                enabled: false
                                            }
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            iconName: "󰅃"
                                            label: "↑"
                                            enabled: widgetRow.index > 0
                                            onClicked: root.moveWidget(widgetRow.sectionKey, widgetRow.index, -1)
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            iconName: "󰅀"
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
                                    if (pressed)
                                        root.beginWidgetDrag(widgetRow.sectionKey, widgetRow.widgetInstance.instanceId, widgetRow.index);
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

                    SettingsDropIndicator {
                        Layout.fillWidth: true
                        active: root.sectionWidgets(sectionKey).length > 0 && root.dragReorderEnabled && root.dragSourceIndex >= 0 && root.dragTargetSection === sectionKey && root.dragTargetIndex === root.sectionWidgets(sectionKey).length
                        visible: active
                    }

                    DropArea {
                        Layout.fillWidth: true
                        height: root.sectionWidgets(sectionKey).length > 0 ? 28 : 0
                        visible: root.dragReorderEnabled && root.sectionWidgets(sectionKey).length > 0
                        enabled: root.dragReorderEnabled
                        keys: ["bar-widget"]
                        onEntered: function (drag) {
                            root.setWidgetDropTarget(sectionKey, root.sectionWidgets(sectionKey).length);
                        }
                        onExited: {
                            root.clearWidgetDropTarget(sectionKey, root.sectionWidgets(sectionKey).length);
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
                            model: root.availablePickerWidgets
                            delegate: SettingsListRow {
                                required property var modelData
                                width: pickerColumn.width
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

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingS

                                        Text {
                                            text: modelData.label
                                            color: Colors.text
                                            font.pixelSize: Colors.fontSizeMedium
                                            font.weight: Font.Medium
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }

                                        Rectangle {
                                            radius: Colors.radiusSmall
                                            color: String(modelData.section || "") === root.addSection ? Colors.primaryStrong : Colors.cardSurface
                                            border.color: String(modelData.section || "") === root.addSection ? Colors.primary : Colors.border
                                            border.width: 1
                                            implicitWidth: sectionBadgeLabel.implicitWidth + Colors.spacingM
                                            implicitHeight: sectionBadgeLabel.implicitHeight + Colors.spacingXS

                                            Text {
                                                id: sectionBadgeLabel
                                                anchors.centerIn: parent
                                                text: "Best in " + root.sectionLabel(String(modelData.section || "right"))
                                                color: String(modelData.section || "") === root.addSection ? Colors.primary : Colors.textSecondary
                                                font.pixelSize: Colors.fontSizeXS
                                                font.weight: Font.Medium
                                            }
                                        }
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

                        Text {
                            width: parent.width
                            visible: root.availablePickerWidgets.length === 0
                            text: "No widgets match \"" + root.widgetSearchQuery + "\"."
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            wrapMode: Text.WordWrap
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

                    Repeater {
                        model: root.editingWidgetSchema

                        delegate: Loader {
                            required property var modelData
                            readonly property var field: modelData
                            Layout.fillWidth: true
                            active: !!root.editingWidget

                            sourceComponent: {
                                if (field.type === "mode")
                                    return schemaModeField;
                                if (field.type === "slider")
                                    return schemaSliderField;
                                if (field.type === "toggle")
                                    return schemaToggleField;
                                if (field.type === "text")
                                    return schemaTextField;
                                return null;
                            }

                            onLoaded: {
                                if (item && item.field !== undefined)
                                    item.field = field;
                            }
                        }
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

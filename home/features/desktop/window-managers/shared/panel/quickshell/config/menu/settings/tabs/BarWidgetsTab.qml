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
    property var currentSectionWidgets: ({ left: [], center: [], right: [] })
    readonly property int overlayInset: root.tightSpacing ? 20 : 40

    readonly property var selectedBar: Config.selectedBar()
    readonly property var editingWidget: (selectedBar && settingsSection && settingsInstanceId)
        ? Config.widgetInstance(selectedBar.id, settingsSection, settingsInstanceId)
        : null
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
    onSelectedBarChanged: refreshSectionWidgets()

    Connections {
        target: Config
        function onBarConfigsChanged() { root.refreshSectionWidgets(); }
        function onSelectedBarIdChanged() { root.refreshSectionWidgets(); }
    }

    function sectionWidgets(section) {
        return currentSectionWidgets[section] || [];
    }

    function refreshSectionWidgets() {
        if (!selectedBar) {
            currentSectionWidgets = { left: [], center: [], right: [] };
            return;
        }
        currentSectionWidgets = {
            left: Config.barSectionWidgets(selectedBar, "left").slice(),
            center: Config.barSectionWidgets(selectedBar, "center").slice(),
            right: Config.barSectionWidgets(selectedBar, "right").slice()
        };
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
        if (!selectedBar) return;
        var settings = BarWidgetRegistry.defaultSettings(widgetType);
        Config.addBarWidget(selectedBar.id, addSection, widgetType, settings);
        widgetPickerOpen = false;
    }

    function removeWidget(section, instanceId) {
        if (!selectedBar) return;
        Config.removeBarWidget(selectedBar.id, section, instanceId);
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
        if (!selectedBar || !widgetInstance) return;
        Config.updateBarWidget(selectedBar.id, section, widgetInstance.instanceId, { enabled: widgetInstance.enabled === false });
    }

    function updateSpacerSize(value) {
        if (!selectedBar || !editingWidget) return;
        var settings = editingWidget.settings ? JSON.parse(JSON.stringify(editingWidget.settings)) : {};
        settings.size = value;
        Config.updateBarWidget(selectedBar.id, settingsSection, editingWidget.instanceId, { settings: settings });
    }

    function updateEditingWidgetSetting(key, value) {
        if (!selectedBar || !editingWidget) return;
        var settings = editingWidget.settings ? JSON.parse(JSON.stringify(editingWidget.settings)) : {};
        settings[key] = value;
        Config.updateBarWidget(selectedBar.id, settingsSection, editingWidget.instanceId, { settings: settings });
    }

    function isSystemStatWidget(widgetType) {
        return widgetType === "cpuStatus" || widgetType === "ramStatus" || widgetType === "gpuStatus";
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
                description: "Drag widgets to reorder inside this section, or add new widgets from the searchable picker."
                visible: !!root.selectedBar

                Column {
                    id: sectionColumn
                    width: widgetSectionCard.width - Colors.spacingL * 2
                    spacing: Colors.spacingS

                    Text {
                        width: parent.width
                        text: root.sectionWidgets(sectionKey).length > 0
                            ? "Current widgets: " + root.sectionWidgets(sectionKey).length
                            : "Current widgets: none"
                        color: Colors.fgSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        visible: root.sectionWidgets(sectionKey).length === 0
                        radius: Colors.radiusSmall
                        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
                        border.color: root.dragTargetSection === sectionKey && root.dragTargetIndex === 0
                            ? Colors.primary
                            : Colors.border
                        border.width: root.dragTargetSection === sectionKey && root.dragTargetIndex === 0 ? 2 : 1
                        implicitHeight: emptyDropColumn.implicitHeight + Colors.spacingM * 2

                        DropArea {
                            anchors.fill: parent
                            keys: ["bar-widget"]
                            onEntered: function(drag) {
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
                            onDropped: function(drop) {
                                root.moveDraggedWidget(sectionKey, 0);
                            }
                        }

                        Column {
                            id: emptyDropColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            Text {
                                text: root.dragSourceIndex >= 0 ? "Drop widget here" : "No widgets in this section yet"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            Text {
                                text: root.dragSourceIndex >= 0
                                    ? "Release to move the dragged widget into " + root.sectionLabel(sectionKey).toLowerCase() + "."
                                    : "Add one below, or drag a widget here from another section."
                                color: Colors.fgSecondary
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Repeater {
                        model: root.sectionWidgets(sectionKey).length
                        delegate: Item {
                            id: widgetRow
                            width: sectionColumn.width
                            implicitHeight: cardLayout.implicitHeight + Colors.spacingM * 2
                            height: implicitHeight
                            required property int index
                            readonly property string sectionKey: widgetSectionCard.sectionKey
                            readonly property var widgetInstance: root.sectionWidgets(sectionKey)[index]
                            readonly property bool dropBeforeActive: root.dragTargetSection === widgetRow.sectionKey
                                && root.dragTargetIndex === widgetRow.index

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }
                                visible: widgetRow.dropBeforeActive
                                height: 10
                                radius: 5
                                color: Colors.withAlpha(Colors.primary, 0.22)
                                border.color: Colors.primary
                                border.width: 1
                                z: 3
                            }

                            DropArea {
                                anchors.fill: parent
                                keys: ["bar-widget"]
                                onEntered: function(drag) {
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
                                onDropped: function(drop) {
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
                                opacity: dragHandle.drag.active ? 0.7 : 1.0

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
                                            color: Colors.fgDim
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
                                                color: Colors.fgSecondary
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
                                Drag.active: dragHandle.drag.active
                                Drag.source: dragProxy
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2
                                Drag.keys: ["bar-widget"]
                            }

                            MouseArea {
                                id: dragHandle
                                width: 44
                                height: 44
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    topMargin: Colors.spacingS
                                }
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                drag.target: card
                                drag.axis: Drag.YAxis
                                cursorShape: Qt.OpenHandCursor
                                onPressed: {
                                    root.dragSection = widgetRow.sectionKey;
                                    root.dragSourceIndex = widgetRow.index;
                                    root.dragTargetSection = widgetRow.sectionKey;
                                    root.dragTargetIndex = widgetRow.index;
                                }
                                onReleased: {
                                    card.x = 0;
                                    card.y = 0;
                                    if (dragProxy.Drag.active)
                                        dragProxy.Drag.drop();
                                    else
                                        root.clearDragState();
                                }
                                drag.onActiveChanged: {
                                    if (!drag.active) {
                                        card.x = 0;
                                        card.y = 0;
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        right: parent.right
                                        rightMargin: Colors.spacingS
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: 28
                                    height: 28
                                    radius: Colors.radiusMedium
                                    color: dragHandle.pressed
                                        ? Colors.withAlpha(Colors.primary, 0.18)
                                        : (dragHandle.containsMouse ? Colors.withAlpha(Colors.text, 0.10) : "transparent")
                                    border.color: dragHandle.containsMouse ? Colors.border : "transparent"
                                    border.width: dragHandle.containsMouse ? 1 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒓"
                                        color: dragHandle.pressed ? Colors.primary : Colors.fgSecondary
                                        font.family: Colors.fontMono
                                        font.pixelSize: Colors.fontSizeMedium
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 12
                        radius: Colors.radiusXXS
                        visible: root.sectionWidgets(sectionKey).length > 0
                            && root.dragSourceIndex >= 0
                            && root.dragTargetSection === sectionKey
                            && root.dragTargetIndex === root.sectionWidgets(sectionKey).length
                        color: Colors.withAlpha(Colors.primary, 0.22)
                        border.color: Colors.primary
                        border.width: 1
                    }

                    DropArea {
                        width: parent.width
                        height: root.sectionWidgets(sectionKey).length > 0 ? 28 : 0
                        visible: root.sectionWidgets(sectionKey).length > 0
                        keys: ["bar-widget"]
                        onEntered: function(drag) {
                            if (root.dragSourceIndex < 0)
                                return;
                            root.dragTargetSection = sectionKey;
                            root.dragTargetIndex = root.sectionWidgets(sectionKey).length;
                        }
                        onExited: {
                            if (root.dragTargetSection === sectionKey
                                    && root.dragTargetIndex === root.sectionWidgets(sectionKey).length) {
                                root.dragTargetSection = "";
                                root.dragTargetIndex = -1;
                            }
                        }
                        onDropped: function(drop) {
                            root.moveDraggedWidget(sectionKey, root.sectionWidgets(sectionKey).length);
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.dragSourceIndex >= 0 ? "Drop at end of " + root.sectionLabel(sectionKey).toLowerCase() : ""
                            color: Colors.fgSecondary
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }
                }

                SettingsActionButton {
                    width: sectionColumn.width
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
                                    spacing: 2

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
                                        color: Colors.fgSecondary
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
                        value: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.size !== undefined
                            ? root.editingWidget.settings.size
                            : 24
                        onMoved: value => root.updateSpacerSize(value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isSystemStatWidget(root.editingWidget.widgetType)
                        label: "Display Mode"
                        description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only. Compact mode may shorten long values automatically to keep vertical bars narrow."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.displayMode
                            ? root.editingWidget.settings.displayMode
                            : "auto"
                        options: [
                            { value: "auto", label: "Auto" },
                            { value: "full", label: "Full" },
                            { value: "compact", label: "Compact" },
                            { value: "icon", label: "Icon" }
                        ]
                        onModeSelected: value => root.updateEditingWidgetSetting("displayMode", value)
                    }

                    SettingsModeRow {
                        visible: !!root.editingWidget && root.isSystemStatWidget(root.editingWidget.widgetType)
                        label: "Value Style"
                        description: root.editingWidget && root.editingWidget.widgetType === "ramStatus"
                            ? "Choose whether memory shows percent used or the current used-memory value. Compact mode can still fall back to percent when the usage text is too long."
                            : "Choose whether this stat shows percent only, usage text, or usage with temperature. Compact mode can shorten long values automatically."
                        currentValue: root.editingWidget && root.editingWidget.settings && root.editingWidget.settings.valueStyle
                            ? root.editingWidget.settings.valueStyle
                            : (root.editingWidget && root.editingWidget.widgetType === "ramStatus" ? "usage" : "percent")
                        options: root.editingWidget && root.editingWidget.widgetType === "ramStatus"
                            ? [
                                { value: "usage", label: "Usage" },
                                { value: "percent", label: "Percent" }
                              ]
                            : [
                                { value: "percent", label: "Percent" },
                                { value: "usage", label: "Usage" },
                                { value: "usageTemp", label: "Usage + Temp" }
                              ]
                        onModeSelected: value => root.updateEditingWidgetSetting("valueStyle", value)
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

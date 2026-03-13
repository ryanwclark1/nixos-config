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
    property string validationMessage: ""
    property string dragSection: ""
    property int dragSourceIndex: -1
    readonly property int overlayInset: root.tightSpacing ? 20 : 40

    readonly property var selectedBar: Config.selectedBar()
    readonly property var editingWidget: (selectedBar && settingsSection && settingsInstanceId)
        ? Config.widgetInstance(selectedBar.id, settingsSection, settingsInstanceId)
        : null

    function sectionWidgets(section) {
        if (!selectedBar || !selectedBar.sectionWidgets)
            return [];
        return selectedBar.sectionWidgets[section] || [];
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
        widgetSettingsOpen = true;
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
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: root.sectionWidgets(sectionKey)
                        delegate: Item {
                            id: widgetRow
                            width: sectionColumn.width
                            height: cardLayout.implicitHeight + Colors.spacingM * 2
                            required property var modelData
                            required property int index
                            readonly property string sectionKey: widgetSectionCard.sectionKey

                            DropArea {
                                anchors.fill: parent
                                keys: ["bar-widget-" + widgetRow.sectionKey]
                                onDropped: function(drop) {
                                    if (!root.selectedBar || root.dragSection !== widgetRow.sectionKey)
                                        return;
                                    Config.moveBarWidget(root.selectedBar.id, root.dragSection, root.dragSourceIndex, widgetRow.index);
                                    root.dragSection = "";
                                    root.dragSourceIndex = -1;
                                }
                            }

                            Rectangle {
                                id: card
                                anchors.fill: parent
                                radius: Colors.radiusSmall
                                color: Colors.bgWidget
                                border.color: Colors.border
                                border.width: 1
                                opacity: dragArea.drag.active ? 0.7 : 1.0

                                ColumnLayout {
                                    id: cardLayout
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingM
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
                                            text: BarWidgetRegistry.displayIcon(widgetRow.modelData.widgetType)
                                            color: Colors.primary
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeLarge
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: BarWidgetRegistry.displayName(widgetRow.modelData.widgetType)
                                                color: Colors.text
                                                font.pixelSize: Colors.fontSizeMedium
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: BarWidgetRegistry.description(widgetRow.modelData.widgetType)
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
                                            label: widgetRow.modelData.enabled === false ? "Hidden" : "Visible"
                                            selected: widgetRow.modelData.enabled !== false
                                            onClicked: root.toggleWidgetEnabled(widgetRow.sectionKey, widgetRow.modelData)
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            iconName: "󰍜"
                                            label: "Settings"
                                            enabled: BarWidgetRegistry.supportsSettings(widgetRow.modelData.widgetType)
                                            onClicked: root.openWidgetSettings(widgetRow.sectionKey, widgetRow.modelData.instanceId)
                                        }

                                        SettingsActionButton {
                                            compact: true
                                            iconName: "󰅖"
                                            label: "Remove"
                                            onClicked: root.removeWidget(widgetRow.sectionKey, widgetRow.modelData.instanceId)
                                        }
                                    }
                                }
                            }

                            Item {
                                id: dragProxy
                                width: widgetRow.width
                                height: widgetRow.height
                                visible: false
                                Drag.active: dragArea.drag.active
                                Drag.source: dragProxy
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2
                                Drag.keys: ["bar-widget-" + widgetRow.sectionKey]
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                drag.target: card
                                drag.axis: Drag.YAxis
                                onPressed: {
                                    root.dragSection = widgetRow.sectionKey;
                                    root.dragSourceIndex = widgetRow.index;
                                }
                                onReleased: {
                                    card.x = 0;
                                    card.y = 0;
                                    if (dragProxy.Drag.active)
                                        dragProxy.Drag.drop();
                                    root.dragSection = "";
                                    root.dragSourceIndex = -1;
                                }
                            }
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
                        visible: !root.editingWidget || !BarWidgetRegistry.supportsSettings(root.editingWidget.widgetType)
                        title: "No configurable options"
                        body: "This widget does not expose custom per-instance settings yet."
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
                }
            }
        }
    }
}

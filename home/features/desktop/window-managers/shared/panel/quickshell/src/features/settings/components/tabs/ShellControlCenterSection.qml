import QtQuick
import QtQuick.Layouts
import "ShellCoreHelpers.js" as Helpers
import "../../../../services"
import "../../../../services/IconHelpers.js" as IconHelpers
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    required property bool compactMode
    required property var settingsRoot

    // --- Quick Links (all items including hidden, for settings reorder UI) ---
    readonly property var orderedQuickLinksModel: (function() {
        void Config.controlCenterQuickLinkOrder;
        void Config.controlCenterHiddenQuickLinks;
        return Helpers.orderedControlCenterQuickLinks(ControlCenterRegistry, Config);
    })()
    function beginQuickLinkDrag(linkId, index) {
        quickLinkReorderState.begin("control-center-quick-link", linkId, index);
    }
    function clearQuickLinkDragState() {
        quickLinkReorderState.clear();
    }
    function currentQuickLinkDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedQuickLinksModel.length);
    }
    function moveDraggedQuickLink(targetIndex) {
        return Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterQuickLinkOrder", quickLinkReorderState, targetIndex);
    }

    // --- Quick Toggles ---
    readonly property var orderedTogglesModel: (function() {
        void Config.controlCenterToggleOrder;
        void Config.controlCenterHiddenToggles;
        return Helpers.orderedControlCenterToggles(ControlCenterRegistry, Config);
    })()
    function beginToggleDrag(toggleId, index) {
        toggleReorderState.begin("control-center-toggle", toggleId, index);
    }
    function clearToggleDragState() {
        toggleReorderState.clear();
    }
    function currentToggleDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedTogglesModel.length);
    }
    function moveDraggedToggle(targetIndex) {
        return Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", toggleReorderState, targetIndex);
    }

    // --- Command Center Widgets ---
    readonly property var orderedWidgetsModel: (function() {
        void Config.controlCenterWidgetOrder;
        void Config.controlCenterShowMediaWidget;
        void Config.controlCenterShowPomodoro;
        void Config.controlCenterShowTodo;
        void Config.controlCenterShowDevOps;
        void Config.controlCenterShowBrightness;
        void Config.controlCenterShowAudioOutput;
        void Config.controlCenterShowAudioInput;
        void Config.controlCenterShowCpuGpuTemp;
        void Config.controlCenterShowCpuWidget;
        void Config.controlCenterShowSystemGraphs;
        void Config.controlCenterShowProcessWidget;
        void Config.controlCenterShowNetworkGraphs;
        void Config.controlCenterShowRamWidget;
        void Config.controlCenterShowDiskWidget;
        void Config.controlCenterShowGpuWidget;
        void Config.controlCenterShowUpdateWidget;
        void Config.controlCenterShowScratchpad;
        void Config.controlCenterShowPowerActions;
        return Helpers.orderedControlCenterWidgets(ControlCenterRegistry, Config);
    })()
    function beginWidgetDrag(widgetId, index) {
        widgetReorderState.begin("control-center-widget", widgetId, index);
    }
    function clearWidgetDragState() {
        widgetReorderState.clear();
    }
    function currentWidgetDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedWidgetsModel.length);
    }
    function moveDraggedWidget(targetIndex) {
        return Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterWidgetOrder", widgetReorderState, targetIndex);
    }

    // --- Plugins ---
    readonly property var orderedPluginsModel: (function() {
        void Config.controlCenterPluginOrder;
        void Config.controlCenterHiddenPlugins;
        void PluginService.controlCenterPlugins;
        return Helpers.orderedControlCenterPlugins(PluginService, Config);
    })()
    function beginPluginDrag(pluginId, index) {
        pluginReorderState.begin("control-center-plugin", pluginId, index);
    }
    function clearPluginDragState() {
        pluginReorderState.clear();
    }
    function currentPluginDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedPluginsModel.length);
    }
    function moveDraggedPlugin(targetIndex) {
        return Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", pluginReorderState, targetIndex);
    }

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    SettingsReorderState { id: quickLinkReorderState }
    SettingsReorderState { id: toggleReorderState }
    SettingsReorderState { id: widgetReorderState }
    SettingsReorderState { id: pluginReorderState }

    SettingsCard {
        id: card
        anchors.fill: parent
        title: "Control Center"
        iconName: "options.svg"
        description: "Visibility and width of control center modules."

        SettingsSliderRow {
            label: "Control Center Width"
            icon: "options.svg"
            min: Config.controlCenterWidthMin
            max: Config.controlCenterWidthMax
            value: Config.controlCenterWidth
            onMoved: v => Config.controlCenterWidth = v
        }

        SettingsInfoCallout {
            iconName: "globe-search.svg"
            title: "Drag layout"
            body: "Drag rows to control the order inside the Control Center. Hidden items stay in the list so you can stage their position before turning them back on."
        }

        SettingsCard {
            title: "Pinned Footer"
            iconName: "power.svg"
            description: "Keep Power Actions visible at the bottom of the Command Center while the rest of the content scrolls."

            SettingsToggleRow {
                label: "Power Actions"
                icon: "power.svg"
                configKey: "controlCenterShowPowerActions"
                description: "Always pinned to the bottom of the Command Center when enabled."
            }
        }

        // =====================================================================
        // QUICK LINKS
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacingL
            spacing: Appearance.spacingS

            Text {
                text: "Quick Links"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Control quick link visibility and order in the Control Center."
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: quickLinkOrderList
                Layout.fillWidth: true
                Layout.bottomMargin: Appearance.spacingS
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.orderedQuickLinksModel

                    delegate: SettingsReorderRow {
                        id: linkRow
                        required property int index
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenQuickLinks) && Config.controlCenterHiddenQuickLinks.indexOf(modelData.id) !== -1
                        reorderState: quickLinkReorderState
                        listId: "control-center-quick-link"
                        itemId: String(linkRow.modelData.id || "")
                        rowIndex: linkRow.index
                        itemCount: root.orderedQuickLinksModel.length
                        listItem: quickLinkOrderList
                        compactMode: root.compactMode
                        minimumHeight: root.compactMode ? 78 : 62
                        active: !linkRow.hidden
                        beginDragFn: function(listId, itemId, index) {
                            root.beginQuickLinkDrag(itemId, index);
                        }
                        moveDraggedFn: function(listId, targetIndex) {
                            return root.moveDraggedQuickLink(targetIndex);
                        }
                        clearDragStateFn: root.clearQuickLinkDragState
                        dropIndexFn: root.currentQuickLinkDropIndex

                        SettingsMetricIcon {
                            icon: linkRow.modelData.icon || "settings.svg"
                            iconColor: linkRow.hidden ? Colors.textDisabled : Colors.primary
                            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: linkRow.modelData.title || linkRow.modelData.id
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: linkRow.hidden ? "Hidden in Control Center. Drag to stage its position, or use the switch to show it again." : (linkRow.modelData.subtitle || "Visible in Control Center.")
                                color: linkRow.hidden ? Colors.textDisabled : Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            spacing: Appearance.spacingS
                            Layout.alignment: Qt.AlignTop

                            SettingsReorderButtons {
                                moveUpEnabled: linkRow.index > 0
                                moveDownEnabled: linkRow.index < root.orderedQuickLinksModel.length - 1
                                onMoveUp: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterQuickLinkOrder", linkRow.modelData.id, -1)
                                onMoveDown: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterQuickLinkOrder", linkRow.modelData.id, 1)
                            }

                            SharedWidgets.ToggleSwitch {
                                checked: !linkRow.hidden
                                onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenQuickLinks", linkRow.modelData.id)
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: quickLinkReorderState.active && quickLinkReorderState.targetListId === "control-center-quick-link" && quickLinkReorderState.targetIndex === root.orderedQuickLinksModel.length
                    visible: active
                    label: "Drop at end of quick links"
                }
            }
        }

        // =====================================================================
        // QUICK TOGGLES
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacingL
            spacing: Appearance.spacingS

            Text {
                text: "Quick Toggles"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Control toggle visibility and order in the Control Center grid."
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: toggleOrderList
                Layout.fillWidth: true
                Layout.bottomMargin: Appearance.spacingS
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.orderedTogglesModel

                    delegate: SettingsReorderRow {
                        id: toggleRow
                        required property int index
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenToggles) && Config.controlCenterHiddenToggles.indexOf(modelData.id) !== -1
                        reorderState: toggleReorderState
                        listId: "control-center-toggle"
                        itemId: String(toggleRow.modelData.id || "")
                        rowIndex: toggleRow.index
                        itemCount: root.orderedTogglesModel.length
                        listItem: toggleOrderList
                        compactMode: root.compactMode
                        minimumHeight: root.compactMode ? 78 : 62
                        active: !toggleRow.hidden
                        beginDragFn: function(listId, itemId, index) {
                            root.beginToggleDrag(itemId, index);
                        }
                        moveDraggedFn: function(listId, targetIndex) {
                            return root.moveDraggedToggle(targetIndex);
                        }
                        clearDragStateFn: root.clearToggleDragState
                        dropIndexFn: root.currentToggleDropIndex

                        SettingsMetricIcon {
                            icon: toggleRow.modelData.icon || "settings.svg"
                            iconColor: toggleRow.hidden ? Colors.textDisabled : Colors.primary
                            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: toggleRow.modelData.label || toggleRow.modelData.id
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: toggleRow.hidden ? "Hidden in Control Center. Drag to stage its position, or use the switch to show it again." : "Visible in Control Center. Drag to reorder, or use the arrow buttons."
                                color: toggleRow.hidden ? Colors.textDisabled : Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            spacing: Appearance.spacingS
                            Layout.alignment: Qt.AlignTop

                            SettingsReorderButtons {
                                moveUpEnabled: toggleRow.index > 0
                                moveDownEnabled: toggleRow.index < root.orderedTogglesModel.length - 1
                                onMoveUp: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", toggleRow.modelData.id, -1)
                                onMoveDown: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", toggleRow.modelData.id, 1)
                            }

                            SharedWidgets.ToggleSwitch {
                                checked: !toggleRow.hidden
                                onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenToggles", toggleRow.modelData.id)
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: toggleReorderState.active && toggleReorderState.targetListId === "control-center-toggle" && toggleReorderState.targetIndex === root.orderedTogglesModel.length
                    visible: active
                    label: "Drop at end of quick toggles"
                }
            }
        }

        // =====================================================================
        // COMMAND CENTER WIDGETS
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacingL
            spacing: Appearance.spacingS

            Text {
                text: "Command Center Widgets"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Control widget visibility and order in the Command Center."
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: widgetOrderList
                Layout.fillWidth: true
                Layout.bottomMargin: Appearance.spacingS
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.orderedWidgetsModel

                    delegate: SettingsReorderRow {
                        id: widgetRow
                        required property int index
                        required property var modelData
                        readonly property bool hidden: modelData.configKey ? (Config[modelData.configKey] === false) : false
                        reorderState: widgetReorderState
                        listId: "control-center-widget"
                        itemId: String(widgetRow.modelData.id || "")
                        rowIndex: widgetRow.index
                        itemCount: root.orderedWidgetsModel.length
                        listItem: widgetOrderList
                        compactMode: root.compactMode
                        minimumHeight: root.compactMode ? 78 : 62
                        active: !widgetRow.hidden
                        beginDragFn: function(listId, itemId, index) {
                            root.beginWidgetDrag(itemId, index);
                        }
                        moveDraggedFn: function(listId, targetIndex) {
                            return root.moveDraggedWidget(targetIndex);
                        }
                        clearDragStateFn: root.clearWidgetDragState
                        dropIndexFn: root.currentWidgetDropIndex

                        SettingsMetricIcon {
                            icon: widgetRow.modelData.icon || "settings.svg"
                            iconColor: widgetRow.hidden ? Colors.textDisabled : Colors.primary
                            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: widgetRow.modelData.label || widgetRow.modelData.id
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: widgetRow.hidden ? "Hidden in Control Center. Drag to stage its position, or use the switch to show it again." : "Visible in Control Center. Drag to reorder, or use the arrow buttons."
                                color: widgetRow.hidden ? Colors.textDisabled : Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            spacing: Appearance.spacingS
                            Layout.alignment: Qt.AlignTop

                            SettingsReorderButtons {
                                moveUpEnabled: widgetRow.index > 0
                                moveDownEnabled: widgetRow.index < root.orderedWidgetsModel.length - 1
                                onMoveUp: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterWidgetOrder", widgetRow.modelData.id, -1)
                                onMoveDown: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterWidgetOrder", widgetRow.modelData.id, 1)
                            }

                            SharedWidgets.ToggleSwitch {
                                checked: !widgetRow.hidden
                                onToggled: Helpers.toggleWidgetVisibility(Config, ControlCenterRegistry, widgetRow.modelData.id)
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: widgetReorderState.active && widgetReorderState.targetListId === "control-center-widget" && widgetReorderState.targetIndex === root.orderedWidgetsModel.length
                    visible: active
                    label: "Drop at end of widgets"
                }
            }
        }

        // =====================================================================
        // PLUGIN WIDGETS
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacingL
            spacing: Appearance.spacingS
            visible: PluginService.controlCenterPlugins.length > 0

            Text {
                text: "Plugin Widgets"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Manage third-party widgets exposed inside the Control Center."
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: pluginOrderList
                Layout.fillWidth: true
                Layout.bottomMargin: Appearance.spacingS
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.orderedPluginsModel

                    delegate: SettingsReorderRow {
                        id: pluginRow
                        required property int index
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenPlugins) && Config.controlCenterHiddenPlugins.indexOf(modelData.id) !== -1
                        reorderState: pluginReorderState
                        listId: "control-center-plugin"
                        itemId: String(pluginRow.modelData.id || "")
                        rowIndex: pluginRow.index
                        itemCount: root.orderedPluginsModel.length
                        listItem: pluginOrderList
                        compactMode: root.compactMode
                        minimumHeight: root.compactMode ? 82 : 66
                        active: !pluginRow.hidden
                        beginDragFn: function(listId, itemId, index) {
                            root.beginPluginDrag(itemId, index);
                        }
                        moveDraggedFn: function(listId, targetIndex) {
                            return root.moveDraggedPlugin(targetIndex);
                        }
                        clearDragStateFn: root.clearPluginDragState
                        dropIndexFn: root.currentPluginDropIndex

                        Rectangle {
                            width: root.compactMode ? 30 : 34
                            height: width
                            radius: Appearance.radiusSmall
                            color: pluginRow.hidden ? Colors.textFaint : Colors.primarySubtle
                            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: "puzzle-piece.svg"
                                color: pluginRow.hidden ? Colors.textDisabled : Colors.primary
                                size: Appearance.fontSizeMedium
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: pluginRow.modelData.name || pluginRow.modelData.id
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: pluginRow.hidden ? "Hidden in Control Center. Drag to stage its slot before showing it again." : "Visible in Control Center. Drag to reorder, or use the arrow buttons."
                                color: pluginRow.hidden ? Colors.textDisabled : Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            spacing: Appearance.spacingS
                            Layout.alignment: Qt.AlignTop

                            SettingsReorderButtons {
                                moveUpEnabled: pluginRow.index > 0
                                moveDownEnabled: pluginRow.index < root.orderedPluginsModel.length - 1
                                onMoveUp: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", pluginRow.modelData.id, -1)
                                onMoveDown: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", pluginRow.modelData.id, 1)
                            }

                            SharedWidgets.ToggleSwitch {
                                checked: !pluginRow.hidden
                                onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenPlugins", pluginRow.modelData.id)
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: pluginReorderState.active && pluginReorderState.targetListId === "control-center-plugin" && pluginReorderState.targetIndex === root.orderedPluginsModel.length
                    visible: active
                    label: "Drop at end of plugin widgets"
                }
            }
        }
    }
}

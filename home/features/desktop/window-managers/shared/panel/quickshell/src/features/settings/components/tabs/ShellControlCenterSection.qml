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

    function orderedToggles() {
        return Helpers.orderedControlCenterToggles(ControlCenterRegistry, Config);
    }
    function orderedPlugins() {
        return Helpers.orderedControlCenterPlugins(PluginService, Config);
    }

    readonly property var orderedTogglesModel: (function() {
        void Config.controlCenterToggleOrder;
        void Config.controlCenterHiddenToggles;
        return Helpers.orderedControlCenterToggles(ControlCenterRegistry, Config);
    })()
    readonly property var orderedPluginsModel: (function() {
        void Config.controlCenterPluginOrder;
        void Config.controlCenterHiddenPlugins;
        void PluginService.controlCenterPlugins;
        return Helpers.orderedControlCenterPlugins(PluginService, Config);
    })()
    function beginToggleDrag(toggleId, index) {
        toggleReorderState.begin("control-center-toggle", toggleId, index);
    }
    function beginPluginDrag(pluginId, index) {
        pluginReorderState.begin("control-center-plugin", pluginId, index);
    }
    function clearToggleDragState() {
        toggleReorderState.clear();
    }
    function clearPluginDragState() {
        pluginReorderState.clear();
    }
    function currentToggleDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedTogglesModel.length);
    }
    function currentPluginDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedPluginsModel.length);
    }
    function moveDraggedToggle(targetIndex) {
        return Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", toggleReorderState, targetIndex);
    }
    function moveDraggedPlugin(targetIndex) {
        return Helpers.moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", pluginReorderState, targetIndex);
    }

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    SettingsReorderState {
        id: toggleReorderState
    }

    SettingsReorderState {
        id: pluginReorderState
    }

    SettingsCard {
        id: card
        anchors.fill: parent
        title: "Control Center"
        iconName: "options.svg"
        description: "Visibility and width of control center modules."

        SettingsSectionLabel { text: "ESSENTIAL TOOLS" }

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2

            SettingsToggleRow {
                label: "Quick Links"
                icon: "wifi-4.svg"
                configKey: "controlCenterShowQuickLinks"
            }
        }

        SettingsSectionLabel { text: "ACTIVE SESSION" }

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2

            SettingsToggleRow {
                label: "Media Widget"
                icon: "music-note-2.svg"
                configKey: "controlCenterShowMediaWidget"
            }
            SettingsToggleRow {
                label: "Pomodoro Timer"
                icon: "timer.svg"
                configKey: "controlCenterShowPomodoro"
            }
            SettingsToggleRow {
                label: "Todo List"
                icon: "checkbox-checked.svg"
                configKey: "controlCenterShowTodo"
            }
            SettingsToggleRow {
                label: "DevOps Section"
                icon: "terminal-filled.svg"
                configKey: "controlCenterShowDevOps"
            }
        }

        SettingsSectionLabel { text: "SYSTEM CONTROLS" }

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2

            SettingsToggleRow {
                label: "Brightness"
                icon: "weather-sunny.svg"
                configKey: "controlCenterShowBrightness"
            }
            SettingsToggleRow {
                label: "Audio Output"
                icon: "speaker.svg"
                configKey: "controlCenterShowAudioOutput"
            }
            SettingsToggleRow {
                label: "Audio Input"
                icon: "mic.svg"
                configKey: "controlCenterShowAudioInput"
            }
            SettingsToggleRow {
                label: "CPU / GPU Temp"
                icon: "temperature.svg"
                configKey: "controlCenterShowCpuGpuTemp"
            }
            SettingsToggleRow {
                label: "CPU Widget"
                icon: "developer-board.svg"
                configKey: "controlCenterShowCpuWidget"
            }
            SettingsToggleRow {
                label: "System Graphs"
                icon: "developer-board.svg"
                configKey: "controlCenterShowSystemGraphs"
            }
            SettingsToggleRow {
                label: "Process Widget"
                icon: "arrow-sync.svg"
                configKey: "controlCenterShowProcessWidget"
            }
            SettingsToggleRow {
                label: "Network Graphs"
                icon: "ethernet.svg"
                configKey: "controlCenterShowNetworkGraphs"
            }
            SettingsToggleRow {
                label: "RAM Widget"
                icon: "board.svg"
                configKey: "controlCenterShowRamWidget"
            }
            SettingsToggleRow {
                label: "Disk Widget"
                icon: "hard-drive.svg"
                configKey: "controlCenterShowDiskWidget"
            }
            SettingsToggleRow {
                label: "GPU Widget"
                icon: "developer-board.svg"
                configKey: "controlCenterShowGpuWidget"
            }
            SettingsToggleRow {
                label: "Update Widget"
                icon: "arrow-sync.svg"
                configKey: "controlCenterShowUpdateWidget"
            }
            SettingsToggleRow {
                label: "Scratchpad"
                icon: "edit.svg"
                configKey: "controlCenterShowScratchpad"
            }
            SettingsToggleRow {
                label: "Power Actions"
                icon: "power.svg"
                configKey: "controlCenterShowPowerActions"
            }
        }

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
            body: "Drag rows to control the order inside the Control Center. Hidden toggles and plugin widgets stay in this list so you can stage their position before turning them back on."
        }

        ColumnLayout {
            Layout.fillWidth: true
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

        ColumnLayout {
            Layout.fillWidth: true
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

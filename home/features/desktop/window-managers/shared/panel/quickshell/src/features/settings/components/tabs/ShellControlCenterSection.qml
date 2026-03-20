import QtQuick
import QtQuick.Layouts
import "ShellCoreHelpers.js" as Helpers
import "../../../../services"
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
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedToggles().length);
    }
    function currentPluginDropIndex(cardItem, rowIndex, listItem) {
        return Helpers.currentOrderedDropIndex(cardItem, rowIndex, listItem, root.orderedPlugins().length);
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

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2

            SettingsToggleRow {
                label: "Quick Links"
                icon: "wifi-4.svg"
                configKey: "controlCenterShowQuickLinks"
            }
            SettingsToggleRow {
                label: "Media Widget"
                icon: "music-note-2.svg"
                configKey: "controlCenterShowMediaWidget"
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
            iconName: "󰛢"
            title: "Drag layout"
            body: "Drag rows to control the order inside the Control Center. Hidden toggles and plugin widgets stay in this list so you can stage their position before turning them back on."
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "Quick Toggles"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Control toggle visibility and order in the Control Center grid."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: toggleOrderList
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root.orderedToggles()

                    delegate: Item {
                        id: toggleRow
                        width: parent ? parent.width : 0
                        implicitHeight: toggleCard.implicitHeight + (toggleDropBeforeIndicator.visible ? toggleDropBeforeIndicator.height + Colors.spacingXS : 0)
                        height: implicitHeight
                        required property int index
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenToggles) && Config.controlCenterHiddenToggles.indexOf(modelData.id) !== -1
                        readonly property bool dropBeforeActive: toggleReorderState.active && toggleReorderState.targetListId === "control-center-toggle" && toggleReorderState.targetIndex === index

                        SettingsDropIndicator {
                            id: toggleDropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            active: toggleRow.dropBeforeActive
                            visible: toggleRow.dropBeforeActive
                        }

                        SettingsListRow {
                            id: toggleCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: toggleDropBeforeIndicator.bottom
                                topMargin: toggleDropBeforeIndicator.visible ? Colors.spacingXS : 0
                            }
                            minimumHeight: root.compactMode ? 78 : 62
                            active: !toggleRow.hidden
                            dragging: toggleDragHandle.dragActive
                            dropTargeted: toggleRow.dropBeforeActive
                            onYChanged: {
                                if (toggleDragHandle.dragActive)
                                    toggleReorderState.updateTarget("control-center-toggle", root.currentToggleDropIndex(toggleCard, toggleRow.index, toggleOrderList));
                            }

                            Behavior on y {
                                enabled: !toggleDragHandle.dragActive

                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SettingsDragHandle {
                                id: toggleDragHandle
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                                dragTarget: toggleCard
                                onPressedChanged: {
                                    if (pressed)
                                        root.beginToggleDrag(toggleRow.modelData.id, toggleRow.index);
                                }
                                onReleased: function(wasDragging) {
                                    var targetIndex = toggleReorderState.targetIndex;
                                    if (wasDragging)
                                        targetIndex = root.currentToggleDropIndex(toggleCard, toggleRow.index, toggleOrderList);
                                    toggleCard.x = 0;
                                    toggleCard.y = 0;
                                    if (wasDragging) {
                                        if (!root.moveDraggedToggle(targetIndex))
                                            root.clearToggleDragState();
                                    } else {
                                        root.clearToggleDragState();
                                    }
                                }
                            }

                            Text {
                                text: toggleRow.modelData.icon || "󰖲"
                                color: toggleRow.hidden ? Colors.textDisabled : Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXXS

                                Text {
                                    text: toggleRow.modelData.label || toggleRow.modelData.id
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.Medium
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: toggleRow.hidden ? "Hidden in Control Center. Drag to stage its position, or use the switch to show it again." : "Visible in Control Center. Drag to reorder, or use the arrow buttons."
                                    color: toggleRow.hidden ? Colors.textDisabled : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            RowLayout {
                                spacing: Colors.spacingS
                                Layout.alignment: Qt.AlignTop

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅃"
                                    enabled: toggleRow.index > 0
                                    onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", toggleRow.modelData.id, -1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅀"
                                    enabled: toggleRow.index < root.orderedToggles().length - 1
                                    onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", toggleRow.modelData.id, 1)
                                }

                                SharedWidgets.ToggleSwitch {
                                    checked: !toggleRow.hidden
                                    onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenToggles", toggleRow.modelData.id)
                                }
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: toggleReorderState.active && toggleReorderState.targetListId === "control-center-toggle" && toggleReorderState.targetIndex === root.orderedToggles().length
                    visible: active
                    label: "Drop at end of quick toggles"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: PluginService.controlCenterPlugins.length > 0

            Text {
                text: "Plugin Widgets"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Manage third-party widgets exposed inside the Control Center."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Column {
                id: pluginOrderList
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Repeater {
                    model: root.orderedPlugins()

                    delegate: Item {
                        id: pluginRow
                        width: parent ? parent.width : 0
                        implicitHeight: pluginCard.implicitHeight + (pluginDropBeforeIndicator.visible ? pluginDropBeforeIndicator.height + Colors.spacingXS : 0)
                        height: implicitHeight
                        required property int index
                        required property var modelData
                        readonly property bool hidden: Array.isArray(Config.controlCenterHiddenPlugins) && Config.controlCenterHiddenPlugins.indexOf(modelData.id) !== -1
                        readonly property bool dropBeforeActive: pluginReorderState.active && pluginReorderState.targetListId === "control-center-plugin" && pluginReorderState.targetIndex === index

                        SettingsDropIndicator {
                            id: pluginDropBeforeIndicator
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            active: pluginRow.dropBeforeActive
                            visible: pluginRow.dropBeforeActive
                        }

                        SettingsListRow {
                            id: pluginCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: pluginDropBeforeIndicator.bottom
                                topMargin: pluginDropBeforeIndicator.visible ? Colors.spacingXS : 0
                            }
                            minimumHeight: root.compactMode ? 82 : 66
                            active: !pluginRow.hidden
                            dragging: pluginDragHandle.dragActive
                            dropTargeted: pluginRow.dropBeforeActive
                            onYChanged: {
                                if (pluginDragHandle.dragActive)
                                    pluginReorderState.updateTarget("control-center-plugin", root.currentPluginDropIndex(pluginCard, pluginRow.index, pluginOrderList));
                            }

                            Behavior on y {
                                enabled: !pluginDragHandle.dragActive

                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SettingsDragHandle {
                                id: pluginDragHandle
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                                dragTarget: pluginCard
                                onPressedChanged: {
                                    if (pressed)
                                        root.beginPluginDrag(pluginRow.modelData.id, pluginRow.index);
                                }
                                onReleased: function(wasDragging) {
                                    var targetIndex = pluginReorderState.targetIndex;
                                    if (wasDragging)
                                        targetIndex = root.currentPluginDropIndex(pluginCard, pluginRow.index, pluginOrderList);
                                    pluginCard.x = 0;
                                    pluginCard.y = 0;
                                    if (wasDragging) {
                                        if (!root.moveDraggedPlugin(targetIndex))
                                            root.clearPluginDragState();
                                    } else {
                                        root.clearPluginDragState();
                                    }
                                }
                            }

                            Rectangle {
                                width: root.compactMode ? 30 : 34
                                height: width
                                radius: Colors.radiusSmall
                                color: pluginRow.hidden ? Colors.textFaint : Colors.primarySubtle
                                Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰏗"
                                    color: pluginRow.hidden ? Colors.textDisabled : Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeMedium
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXXS

                                Text {
                                    text: pluginRow.modelData.name || pluginRow.modelData.id
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.Medium
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: pluginRow.hidden ? "Hidden in Control Center. Drag to stage its slot before showing it again." : "Visible in Control Center. Drag to reorder, or use the arrow buttons."
                                    color: pluginRow.hidden ? Colors.textDisabled : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            RowLayout {
                                spacing: Colors.spacingS
                                Layout.alignment: Qt.AlignTop

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅃"
                                    enabled: pluginRow.index > 0
                                    onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", pluginRow.modelData.id, -1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅀"
                                    enabled: pluginRow.index < root.orderedPlugins().length - 1
                                    onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", pluginRow.modelData.id, 1)
                                }

                                SharedWidgets.ToggleSwitch {
                                    checked: !pluginRow.hidden
                                    onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenPlugins", pluginRow.modelData.id)
                                }
                            }
                        }
                    }
                }

                SettingsDropIndicator {
                    width: parent ? parent.width : 0
                    active: pluginReorderState.active && pluginReorderState.targetListId === "control-center-plugin" && pluginReorderState.targetIndex === root.orderedPlugins().length
                    visible: active
                    label: "Drop at end of plugin widgets"
                }
            }
        }
    }
}

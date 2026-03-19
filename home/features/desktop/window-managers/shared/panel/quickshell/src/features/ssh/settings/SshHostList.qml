import QtQuick
import QtQuick.Layouts
import "../../settings/components/SettingsReorderHelpers.js" as ReorderHelpers
import "../../../services"
import "../../../features/settings/components"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root
    required property var sshData
    required property var filteredManualHosts
    required property string editingHostId
    required property string searchQuery

    signal editHost(int index)
    signal duplicateHost(int index)
    signal removeHost(int index)
    signal moveHost(int index, int delta)
    signal searchChanged(string query)

    readonly property bool reorderDisabled: root.searchQuery.trim() !== ""

    function beginHostDrag(hostId, index) {
        hostReorderState.begin("ssh-manual-host", hostId, index);
    }
    function clearHostDragState() {
        hostReorderState.clear();
    }
    function currentHostDropIndex(cardItem, rowIndex, listItem) {
        if (!cardItem || !listItem)
            return rowIndex;
        return ReorderHelpers.targetIndexFromMappedY(cardItem.mapToItem(listItem, 0, cardItem.y).y, cardItem.height, listItem.spacing, root.filteredManualHosts.length);
    }
    function moveDraggedHost(targetIndex) {
        var hostId = String(hostReorderState.sourceItemId || "");
        hostReorderState.clear();
        if (hostId === "" || root.reorderDisabled)
            return false;
        return root.sshData.moveManualHost(hostId, targetIndex);
    }

    Layout.fillWidth: true
    implicitHeight: listColumn.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    SettingsReorderState {
        id: hostReorderState
    }

    ColumnLayout {
        id: listColumn
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "Manual Hosts"
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            SharedWidgets.FilterChip {
                label: String(root.filteredManualHosts.length) + "/" + String(root.sshData.manualHosts.length)
                selected: false
                enabled: false
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: height / 2
            color: Colors.bgWidget
            border.color: manualSearchInput.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                spacing: Colors.spacingS

                Text {
                    text: "󰍉"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                }

                TextInput {
                    id: manualSearchInput
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    clip: true
                    text: root.searchQuery
                    onTextChanged: root.searchChanged(text)

                    Text {
                        anchors.fill: parent
                        text: "Filter manual hosts..."
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeSmall
                        visible: !manualSearchInput.text && !manualSearchInput.activeFocus
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        SettingsInfoCallout {
            Layout.fillWidth: true
            visible: root.reorderDisabled && root.sshData.manualHosts.length > 0
            iconName: "󰌑"
            title: "Reordering paused while filtering"
            body: "Clear search to drag hosts or use the up and down buttons."
        }

        Text {
            Layout.fillWidth: true
            visible: root.filteredManualHosts.length === 0
            text: root.searchQuery.trim() !== "" ? "No manual hosts match \"" + root.searchQuery + "\"." : "No manual hosts saved yet."
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
        }

        Column {
            id: hostOrderList
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Repeater {
                model: root.filteredManualHosts

                delegate: Item {
                    id: hostRow
                    width: parent ? parent.width : 0
                    implicitHeight: hostCard.implicitHeight + (hostDropBeforeIndicator.visible ? hostDropBeforeIndicator.height + Colors.spacingXS : 0)
                    height: implicitHeight
                    required property var modelData
                    readonly property var host: modelData.host
                    readonly property int hostIndex: modelData.index
                    readonly property bool editingThisHost: String(host.id || "") === root.editingHostId
                    readonly property bool dropBeforeActive: hostReorderState.active && hostReorderState.targetListId === "ssh-manual-host" && hostReorderState.targetIndex === modelData.index

                    SettingsDropIndicator {
                        id: hostDropBeforeIndicator
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        active: hostRow.dropBeforeActive
                        visible: hostRow.dropBeforeActive
                    }

                    SettingsListRow {
                        id: hostCard
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: hostDropBeforeIndicator.bottom
                            topMargin: hostDropBeforeIndicator.visible ? Colors.spacingXS : 0
                        }
                        minimumHeight: 0
                        active: hostRow.editingThisHost
                        dragging: hostDragHandle.dragActive
                        dropTargeted: hostRow.dropBeforeActive
                        onYChanged: {
                            if (hostDragHandle.dragActive)
                                hostReorderState.updateTarget("ssh-manual-host", root.currentHostDropIndex(hostCard, hostRow.hostIndex, hostOrderList));
                        }

                        Behavior on y {
                            enabled: !hostDragHandle.dragActive

                            NumberAnimation {
                                duration: Colors.durationFast
                            }
                        }

                        SettingsDragHandle {
                            id: hostDragHandle
                            Layout.alignment: Qt.AlignTop
                            dragTarget: hostCard
                            enabled: !root.reorderDisabled
                            onPressedChanged: {
                                if (pressed)
                                    root.beginHostDrag(hostRow.host.id, hostRow.hostIndex);
                            }
                            onReleased: function(wasDragging) {
                                var targetIndex = hostReorderState.targetIndex;
                                if (wasDragging)
                                    targetIndex = root.currentHostDropIndex(hostCard, hostRow.hostIndex, hostOrderList);
                                hostCard.x = 0;
                                hostCard.y = 0;
                                if (wasDragging) {
                                    if (!root.moveDraggedHost(targetIndex))
                                        root.clearHostDragState();
                                } else {
                                    root.clearHostDragState();
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingS

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Colors.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingS

                                        Text {
                                            text: hostRow.host.label
                                            color: Colors.text
                                            font.pixelSize: Colors.fontSizeMedium
                                            font.weight: Font.Medium
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        SharedWidgets.FilterChip {
                                            visible: hostRow.editingThisHost
                                            label: "Editing"
                                            selected: true
                                            enabled: false
                                        }
                                    }

                                    Text {
                                        text: root.sshData.buildDisplayCommand(hostRow.host)
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        Layout.fillWidth: true
                                        wrapMode: Text.WrapAnywhere
                                    }

                                    Text {
                                        text: root.reorderDisabled ? "Clear search to reorder hosts." : "Drag to reorder hosts, or use the arrow buttons."
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
                                    visible: String(hostRow.host.group || "") !== ""
                                    label: String(hostRow.host.group || "")
                                    selected: false
                                    enabled: false
                                }

                                SharedWidgets.FilterChip {
                                    visible: String(hostRow.host.user || "") !== ""
                                    label: String(hostRow.host.user || "")
                                    selected: false
                                    enabled: false
                                }

                                Repeater {
                                    model: Array.isArray(hostRow.host.tags) ? hostRow.host.tags : []

                                    delegate: SharedWidgets.FilterChip {
                                        required property var modelData
                                        visible: String(modelData || "").trim() !== ""
                                        label: "#" + String(modelData || "")
                                        selected: false
                                        enabled: false
                                    }
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Colors.spacingS

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰏫"
                                    label: "Up"
                                    enabled: !root.reorderDisabled && hostRow.hostIndex > 0
                                    onClicked: root.moveHost(hostRow.hostIndex, -1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰏬"
                                    label: "Down"
                                    enabled: !root.reorderDisabled && hostRow.hostIndex < (root.sshData.manualHosts.length - 1)
                                    onClicked: root.moveHost(hostRow.hostIndex, 1)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰏫"
                                    label: "Edit"
                                    onClicked: root.editHost(hostRow.hostIndex)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰑕"
                                    label: "Duplicate"
                                    onClicked: root.duplicateHost(hostRow.hostIndex)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "󰅖"
                                    label: "Remove"
                                    onClicked: root.removeHost(hostRow.hostIndex)
                                }
                            }
                        }
                    }
                }
            }

            SettingsDropIndicator {
                width: parent ? parent.width : 0
                active: hostReorderState.active && hostReorderState.targetListId === "ssh-manual-host" && hostReorderState.targetIndex === root.filteredManualHosts.length
                visible: active
                label: "Drop at end of host list"
            }
        }
    }
}

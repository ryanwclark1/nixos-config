import QtQuick
import QtQuick.Layouts
import "../../../../launcher/LauncherModeData.js" as ModeData
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Column {
    id: root

    property var modeModel: []
    property var reorderState: null
    property string listId: ""
    property bool compactMode: false

    // Callback functions (DI pattern)
    property var beginDragFn: null       // function(modeKey, index)
    property var moveDraggedFn: null     // function(targetIndex) → bool
    property var clearDragStateFn: null  // function()
    property var moveModeFn: null        // function(modeKey, delta)
    property var modeMetaFn: null        // function(modeKey) → {label, icon}
    property var dropIndexFn: null       // function(card, rowIndex, list, count) → int

    // Action buttons config
    property string promoteLabel: ""     // e.g. "Pin" or "Advanced"
    property var promoteFn: null         // function(modeKey)
    property var disableFn: null         // function(modeKey)
    property string dropEndText: "Drop at end"
    property string dragHintText: "Drag to reorder"

    spacing: Appearance.spacingXS

    Repeater {
        model: root.modeModel

        delegate: Item {
            id: modeRow
            width: parent ? parent.width : 0
            implicitHeight: modeCard.implicitHeight + (dropBeforeIndicator.visible ? dropBeforeIndicator.height + Appearance.spacingXS : 0)
            height: implicitHeight
            required property int index
            required property var modelData
            readonly property bool dropBeforeActive: root.reorderState && root.reorderState.active && root.reorderState.targetListId === root.listId && root.reorderState.targetIndex === index

            SettingsDropIndicator {
                id: dropBeforeIndicator
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                active: modeRow.dropBeforeActive
                visible: modeRow.dropBeforeActive
            }

            SettingsListRow {
                id: modeCard
                anchors {
                    left: parent.left
                    right: parent.right
                    top: dropBeforeIndicator.bottom
                    topMargin: dropBeforeIndicator.visible ? Appearance.spacingXS : 0
                }
                minimumHeight: root.compactMode ? 82 : 54
                dragging: dragHandle.dragActive
                dropTargeted: modeRow.dropBeforeActive
                onYChanged: {
                    if (dragHandle.dragActive && root.reorderState && root.dropIndexFn)
                        root.reorderState.updateTarget(root.listId, root.dropIndexFn(modeCard, modeRow.index, root, root.modeModel.length));
                }

                Behavior on y {
                    enabled: !dragHandle.dragActive

                    NumberAnimation {
                        duration: Appearance.durationFast
                    }
                }

                SettingsDragHandle {
                    id: dragHandle
                    Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                    dragTarget: modeCard
                    onPressedChanged: {
                        if (pressed && root.beginDragFn)
                            root.beginDragFn(modeRow.modelData, modeRow.index);
                    }
                    onReleased: function (wasDragging) {
                        var targetIndex = root.reorderState ? root.reorderState.targetIndex : -1;
                        if (wasDragging && root.dropIndexFn)
                            targetIndex = root.dropIndexFn(modeCard, modeRow.index, root, root.modeModel.length);
                        modeCard.x = 0;
                        modeCard.y = 0;
                        if (wasDragging) {
                            if (root.moveDraggedFn && !root.moveDraggedFn(targetIndex))
                                if (root.clearDragStateFn)
                                    root.clearDragStateFn();
                        } else {
                            if (root.clearDragStateFn)
                                root.clearDragStateFn();
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Appearance.radiusCard
                    color: Colors.surface
                    border.color: Colors.border
                    border.width: 1
                    Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                    SettingsMetricIcon {
                        anchors.centerIn: parent
                        icon: root.modeMetaFn ? root.modeMetaFn(modeRow.modelData).icon : ""
                        iconSize: Appearance.fontSizeSmall
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingXS

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingS

                        Text {
                            text: root.modeMetaFn ? root.modeMetaFn(modeRow.modelData).label : ""
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            visible: String(ModeData.modeInfo(modeRow.modelData).prefix || "") !== ""
                            radius: Appearance.radiusPill
                            color: Colors.primarySubtle
                            border.color: Colors.primaryRing
                            border.width: 1
                            implicitHeight: 22
                            implicitWidth: prefixText.implicitWidth + 12

                            Text {
                                id: prefixText
                                anchors.centerIn: parent
                                text: (ModeData.modeInfo(modeRow.modelData).prefix || "") + " prefix"
                                color: Colors.primary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: ModeData.modeInfo(modeRow.modelData).hint || "Launcher mode"
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.dragHintText
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                        wrapMode: Text.WordWrap
                    }
                }

                Flow {
                    spacing: Appearance.spacingS
                    Layout.alignment: Qt.AlignTop

                    SettingsActionButton {
                        compact: true
                        iconName: "chevron-up.svg"
                        enabled: modeRow.index > 0
                        onClicked: if (root.moveModeFn) root.moveModeFn(modeRow.modelData, -1)
                    }

                    SettingsActionButton {
                        compact: true
                        iconName: "chevron-down.svg"
                        enabled: modeRow.index < (root.modeModel.length - 1)
                        onClicked: if (root.moveModeFn) root.moveModeFn(modeRow.modelData, 1)
                    }

                    SettingsActionButton {
                        compact: true
                        label: root.promoteLabel
                        onClicked: if (root.promoteFn) root.promoteFn(modeRow.modelData)
                    }

                    SettingsActionButton {
                        compact: true
                        label: "Disable"
                        onClicked: if (root.disableFn) root.disableFn(modeRow.modelData)
                    }
                }
            }
        }
    }

    SettingsDropIndicator {
        width: parent ? parent.width : 0
        active: root.reorderState && root.reorderState.active && root.reorderState.targetListId === root.listId && root.reorderState.targetIndex === root.modeModel.length
        visible: active
    }

    Text {
        width: parent ? parent.width : 0
        visible: root.reorderState && root.reorderState.active && root.reorderState.targetListId === root.listId && root.reorderState.targetIndex === root.modeModel.length
        text: root.dropEndText
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeXS
    }
}

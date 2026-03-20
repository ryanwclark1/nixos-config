import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"

Item {
    id: root

    default property alias rowContent: rowCard.rowContent

    property var reorderState: null
    property string listId: ""
    property string itemId: ""
    property int rowIndex: -1
    property int itemCount: 0
    property var listItem: null
    property bool compactMode: false
    property bool active: false
    property bool highlighted: false
    property bool dragEnabled: true
    property bool trackInternalDropTarget: true
    property bool autoCommitOnRelease: true
    property int minimumHeight: 0
    property int dragAxis: Drag.YAxis
    property var beginDragFn: null
    property var moveDraggedFn: null
    property var clearDragStateFn: null
    property var dropIndexFn: null

    readonly property bool dropBeforeActive: reorderState && reorderState.active && reorderState.targetListId === listId && reorderState.targetIndex === rowIndex
    readonly property bool dragging: dragHandle.dragActive
    readonly property real dragOffsetX: dragHandle.dragOffsetX
    readonly property real dragOffsetY: dragHandle.dragOffsetY

    signal dragReleased(bool wasDragging, int targetIndex)

    Layout.fillWidth: true
    width: parent ? parent.width : 0
    implicitHeight: rowCard.implicitHeight + (dropBeforeIndicator.visible ? dropBeforeIndicator.height + Appearance.spacingXS : 0)
    height: implicitHeight

    function resolvedTargetIndex() {
        if (!root.dropIndexFn)
            return root.rowIndex;
        return root.dropIndexFn(rowCard, root.rowIndex, root.listItem, root.itemCount, root.dragOffsetY, root.dragOffsetX);
    }

    function updateInternalTarget() {
        if (!root.trackInternalDropTarget || !dragHandle.dragActive || !root.reorderState)
            return;
        root.reorderState.updateTarget(root.listId, root.resolvedTargetIndex());
    }

    onDragOffsetYChanged: root.updateInternalTarget()
    onDragOffsetXChanged: root.updateInternalTarget()

    Behavior on y {
        enabled: !dragHandle.dragActive && !Colors.isTransitioning

        NumberAnimation {
            duration: Appearance.durationFast
        }
    }

    SettingsDropIndicator {
        id: dropBeforeIndicator
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        active: root.dropBeforeActive
        visible: root.dropBeforeActive
    }

    SettingsListRow {
        id: rowCard
        anchors {
            left: parent.left
            right: parent.right
            top: dropBeforeIndicator.bottom
            topMargin: dropBeforeIndicator.visible ? Appearance.spacingXS : 0
        }
        minimumHeight: root.minimumHeight
        active: root.active
        highlighted: root.highlighted
        dragging: dragHandle.dragActive
        dropTargeted: root.dropBeforeActive
        z: dragHandle.dragActive ? 2 : 0

        transform: Translate {
            x: root.dragOffsetX
            y: root.dragOffsetY
        }

        SettingsDragHandle {
            id: dragHandle
            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
            enabled: root.dragEnabled
            dragAxis: root.dragAxis
            onPressedChanged: {
                if (pressed && root.beginDragFn)
                    root.beginDragFn(root.listId, root.itemId, root.rowIndex);
            }
            onReleased: function(wasDragging) {
                var targetIndex = root.reorderState ? root.reorderState.targetIndex : -1;
                if (wasDragging)
                    targetIndex = root.resolvedTargetIndex();

                root.dragReleased(wasDragging, targetIndex);

                if (!root.autoCommitOnRelease)
                    return;

                if (wasDragging) {
                    if (root.moveDraggedFn && !root.moveDraggedFn(root.listId, targetIndex) && root.clearDragStateFn)
                        root.clearDragStateFn();
                } else if (root.clearDragStateFn) {
                    root.clearDragStateFn();
                }
            }
        }
    }
}

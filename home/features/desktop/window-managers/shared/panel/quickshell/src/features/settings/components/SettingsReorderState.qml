import QtQuick

QtObject {
    id: root

    property string sourceListId: ""
    property string sourceItemId: ""
    property int sourceIndex: -1
    property string targetListId: ""
    property int targetIndex: -1
    readonly property bool active: sourceItemId !== "" && sourceIndex >= 0

    function begin(listId, itemId, index) {
        sourceListId = String(listId || "");
        sourceItemId = String(itemId || "");
        sourceIndex = Math.max(-1, Math.round(Number(index) || -1));
        targetListId = sourceListId;
        targetIndex = sourceIndex;
    }

    function updateTarget(listId, index) {
        targetListId = String(listId || "");
        targetIndex = Math.max(-1, Math.round(Number(index) || -1));
    }

    function clear() {
        sourceListId = "";
        sourceItemId = "";
        sourceIndex = -1;
        targetListId = "";
        targetIndex = -1;
    }

    function matchesTarget(listId, index) {
        return active && targetListId === String(listId || "") && targetIndex === Math.round(Number(index) || -1);
    }
}

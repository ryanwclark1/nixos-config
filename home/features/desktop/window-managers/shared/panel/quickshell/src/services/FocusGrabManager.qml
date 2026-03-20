pragma Singleton
import QtQuick

QtObject {
    id: manager

    // Stack of {id: string, onRelease: function} entries.
    // Top of stack (last element) is the current grab owner.
    property var _grabStack: []

    readonly property bool hasGrabs: _grabStack.length > 0
    readonly property string topGrabId: _grabStack.length > 0
        ? _grabStack[_grabStack.length - 1].id : ""

    signal grabsChanged()

    function requestGrab(id, onRelease) {
        // Remove existing entry for this id (re-entrant push)
        var stack = _grabStack;
        for (var i = stack.length - 1; i >= 0; i--) {
            if (stack[i].id === id) {
                stack.splice(i, 1);
                break;
            }
        }
        stack.push({ id: id, onRelease: onRelease });
        _grabStack = stack;
        grabsChanged();
    }

    function releaseGrab(id) {
        var stack = _grabStack;
        for (var i = stack.length - 1; i >= 0; i--) {
            if (stack[i].id === id) {
                stack.splice(i, 1);
                _grabStack = stack;
                grabsChanged();
                return;
            }
        }
    }

    function clearTopGrab() {
        var stack = _grabStack;
        if (stack.length === 0) return;
        var entry = stack.pop();
        _grabStack = stack;
        grabsChanged();
        if (typeof entry.onRelease === "function")
            entry.onRelease();
    }

    function clearAllGrabs() {
        var stack = _grabStack;
        _grabStack = [];
        grabsChanged();
        for (var i = stack.length - 1; i >= 0; i--) {
            if (typeof stack[i].onRelease === "function")
                stack[i].onRelease();
        }
    }
}

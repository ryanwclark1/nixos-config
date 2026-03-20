pragma Singleton
import QtQuick

// Coordinates auto-hide between bar and dock on the same screen.
// When any registered surface is hovered, all auto-hide timers should
// check anyHovered() before actually hiding.
//
// Usage:
//   AutoHideCoordinator.setHovered(screenName, "bar-primary", true)
//   if (!AutoHideCoordinator.anyHovered(screenName)) { /* ok to hide */ }
QtObject {
    id: root

    // Map of screenName -> { sourceId: bool }
    property var _screens: ({})
    signal anyHoveredChanged()

    function setHovered(screenName, sourceId, isHovered) {
        if (!screenName) return;
        var screen = _screens[screenName];
        if (!screen) {
            screen = {};
            _screens[screenName] = screen;
        }
        var prev = !!screen[sourceId];
        if (prev === isHovered) return;
        screen[sourceId] = isHovered;
        anyHoveredChanged();
    }

    function anyHovered(screenName) {
        var screen = _screens[screenName || ""];
        if (!screen) return false;
        for (var key in screen) {
            if (screen[key]) return true;
        }
        return false;
    }

    function removeSource(screenName, sourceId) {
        var screen = _screens[screenName || ""];
        if (!screen) return;
        if (screen[sourceId]) {
            delete screen[sourceId];
            anyHoveredChanged();
        } else {
            delete screen[sourceId];
        }
    }
}

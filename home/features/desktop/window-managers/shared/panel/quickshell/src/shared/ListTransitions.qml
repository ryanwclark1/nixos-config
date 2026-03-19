pragma Singleton

import QtQuick
import "../services"

QtObject {
    // Fade in + scale up — cards, notifications, panel items
    readonly property Transition addFadeScale: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Colors.durationPanelOpen; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: Colors.durationPanelOpen; easing.type: Easing.OutBack }
    }

    // Fade in + expand height — inline list rows, todos
    readonly property Transition addFadeHeight: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Colors.durationFast }
        NumberAnimation { property: "height"; from: 0; duration: Colors.durationFast; easing.type: Easing.OutQuad }
    }

    // Fade out — standard removal
    readonly property Transition removeFade: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Colors.durationNormal }
    }

    // Fade out + collapse height — inline list rows, todos
    readonly property Transition removeFadeHeight: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Colors.durationFast }
        NumberAnimation { property: "height"; to: 0; duration: Colors.durationFast; easing.type: Easing.InQuad }
    }

    // Slide to new Y position — items displaced by add/remove
    readonly property Transition displaced: Transition {
        NumberAnimation { properties: "y"; duration: Colors.durationPanelOpen; easing.type: Easing.OutCubic }
    }

    // Reorder — items moving to new position
    readonly property Transition move: Transition {
        NumberAnimation { properties: "x,y"; duration: Colors.durationFast; easing.type: Easing.OutCubic }
    }
}

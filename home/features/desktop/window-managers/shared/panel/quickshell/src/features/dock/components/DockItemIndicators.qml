import QtQuick
import Quickshell
import "../../../services"

Loader {
    id: root
    required property var toplevels
    required property bool isFocused
    required property bool vertical

    sourceComponent: vertical ? verticalIndicators : horizontalIndicators

    Component {
        id: horizontalIndicators
        Row {
            spacing: 3
            Repeater {
                model: Math.min(root.toplevels.length, 3)
                Rectangle {
                    required property int index
                    width: 4; height: 4; radius: Colors.radiusMicro
                    color: {
                        if (!root.isFocused) return Colors.textSecondary;
                        var active = CompositorAdapter.activeWindow;
                        if (active && index < root.toplevels.length && CompositorAdapter.sameWindow(root.toplevels[index], active))
                            return Colors.primary;
                        return Colors.textSecondary;
                    }
                    Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                }
            }
        }
    }

    Component {
        id: verticalIndicators
        Column {
            spacing: 3
            Repeater {
                model: Math.min(root.toplevels.length, 3)
                Rectangle {
                    required property int index
                    width: 4; height: 4; radius: Colors.radiusMicro
                    color: {
                        if (!root.isFocused) return Colors.textSecondary;
                        var active = CompositorAdapter.activeWindow;
                        if (active && index < root.toplevels.length && CompositorAdapter.sameWindow(root.toplevels[index], active))
                            return Colors.primary;
                        return Colors.textSecondary;
                    }
                    Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                }
            }
        }
    }
}

import QtQuick
import "../../services"

// Auto-hide (timer + coordinator + hover) and bar wheel actions (workspace / volume).
// Lives as an early child of Panel so stacking matches the previous inline handlers.
Item {
    id: root

    required property var panel

    readonly property string _autoHideSourceId: "bar-" + ((panel.barConfig && panel.barConfig.id) || "default")
    readonly property string _autoHideScreenName: (panel.screenRef && panel.screenRef.name) || ""

    Timer {
        id: autoHideTimer
        interval: panel.autoHideDelay
        onTriggered: {
            if (panel.autoHide && !panel._hovered && !AutoHideCoordinator.anyHovered(root._autoHideScreenName))
                panel._autoHidden = true;
        }
    }

    Connections {
        target: AutoHideCoordinator
        function onAnyHoveredChanged() {
            if (!panel.autoHide || !panel._autoHidden)
                return;
            if (AutoHideCoordinator.anyHovered(root._autoHideScreenName)) {
                panel._autoHidden = false;
                autoHideTimer.stop();
            }
        }
    }

    Connections {
        target: panel
        function onAutoHideChanged() {
            if (!panel.autoHide) {
                panel._autoHidden = false;
                AutoHideCoordinator.removeSource(root._autoHideScreenName, root._autoHideSourceId);
            }
        }
    }

    Connections {
        target: panel
        function on_HoveredChanged() {
            if (panel.autoHide)
                AutoHideCoordinator.setHovered(root._autoHideScreenName, root._autoHideSourceId, panel._hovered);
            if (panel._hovered) {
                panel._autoHidden = false;
                autoHideTimer.stop();
            } else if (panel.autoHide) {
                autoHideTimer.restart();
            }
        }
    }

    HoverHandler {
        id: barHoverHandler
        onHoveredChanged: panel._hovered = barHoverHandler.hovered
    }

    WheelHandler {
        enabled: panel.scrollBehavior !== "none"
        onWheel: event => {
            var delta = event.angleDelta.y;
            if (delta === 0)
                return;
            if (panel.scrollBehavior === "workspace") {
                if (delta > 0)
                    CompositorAdapter.focusWorkspace("e-1");
                else
                    CompositorAdapter.focusWorkspace("e+1");
            } else if (panel.scrollBehavior === "volume") {
                var step = delta > 0 ? 0.02 : -0.02;
                AudioService.setVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1, AudioService.outputVolume + step)));
            }
        }
    }
}

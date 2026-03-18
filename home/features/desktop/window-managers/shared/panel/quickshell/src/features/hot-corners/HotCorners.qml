import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"

// HotCorners — invisible 4×4px PanelWindow triggers at each screen corner.
// When the mouse enters a corner zone a cooldown-gated `cornerActivated`
// signal is emitted with the corner name ("topLeft", "topRight",
// "bottomLeft", "bottomRight").  ShellRoot wires up the actions.
//
// IPC target "hotCorners":  toggle | enable | disable
// Config key: hotCornersEnabled (bool, default false)
Scope {
    id: root

    // ── Public API ───────────────────────────────────────────────────────────
    signal cornerActivated(string corner)

    property bool enabled: Config.hotCornersEnabled
    // Size of each invisible hit-zone in logical pixels.
    readonly property int triggerSize: 4
    // Minimum ms between two activations of the same corner.
    readonly property int cooldownMs: 500

    // ── IPC ──────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "hotCorners"
        function toggle(): void { root.enabled = !root.enabled; }
        function enable():  void { root.enabled = true;  }
        function disable(): void { root.enabled = false; }
    }

    // ── Per-screen corner triggers ───────────────────────────────────────────
    Variants {
        model: root.enabled ? Quickshell.screens : []

        delegate: Scope {
            id: screenScope
            required property var modelData

            // One tiny PanelWindow per corner.
            // `component` keyword creates a locally-scoped reusable type.
            component CornerTrigger: PanelWindow {
                id: trigger

                // Which corner this trigger covers.
                property string corner: "topLeft"

                screen: screenScope.modelData
                color: "transparent"
                implicitWidth:  root.triggerSize
                implicitHeight: root.triggerSize
                exclusiveZone: 0

                WlrLayershell.layer:         WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.namespace:     "quickshell:hotcorner"

                // Per-corner cooldown timer — prevents rapid re-triggering
                // when the cursor lingers on the edge.
                Timer {
                    id: cooldown
                    interval: root.cooldownMs
                    repeat: false
                    running: false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        if (!cooldown.running) {
                            cooldown.restart();
                            root.cornerActivated(trigger.corner);
                        }
                    }
                }
            }

            CornerTrigger {
                corner: "topLeft"
                anchors.top:  true
                anchors.left: true
            }

            CornerTrigger {
                corner: "topRight"
                anchors.top:   true
                anchors.right: true
            }

            CornerTrigger {
                corner: "bottomLeft"
                anchors.bottom: true
                anchors.left:   true
            }

            CornerTrigger {
                corner: "bottomRight"
                anchors.bottom: true
                anchors.right:  true
            }
        }
    }
}

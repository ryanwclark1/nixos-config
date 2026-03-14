pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

QtObject {
    id: root

    readonly property bool inhibiting: Config.idleInhibitEnabled
    readonly property bool canUseIdleInhibitor: (Quickshell.env("QT_QPA_PLATFORM") || "").toLowerCase() !== "offscreen"
    property var _idleInhibitor: null
    property var _inhibitorWindow: null

    function toggle() {
        Config.idleInhibitEnabled = !Config.idleInhibitEnabled;
    }

    function _syncIdleInhibitor() {
        if (!root.canUseIdleInhibitor)
            return;

        if (!root._inhibitorWindow) {
            try {
                root._inhibitorWindow = Qt.createQmlObject(`
                    import QtQuick
                    import Quickshell
                    import Quickshell.Wayland

                    PanelWindow {
                        implicitWidth: 1
                        implicitHeight: 1
                        color: "transparent"
                        WlrLayershell.layer: WlrLayer.Background
                        WlrLayershell.namespace: "quickshell-caffeine"
                        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    }
                `, root, "CaffeineInhibitorWindow");
            } catch (error) {
                console.warn("CaffeineService: failed to create inhibitor window:", error);
                root._inhibitorWindow = null;
                return;
            }
        }

        if (root._inhibitorWindow)
            root._inhibitorWindow.visible = root.inhibiting;

        if (!root._idleInhibitor) {
            try {
                root._idleInhibitor = Qt.createQmlObject(`
                    import QtQuick
                    import Quickshell.Wayland

                    IdleInhibitor {}
                `, root._inhibitorWindow, "CaffeineIdleInhibitor");
            } catch (error) {
                console.warn("CaffeineService: failed to create IdleInhibitor:", error);
                root._idleInhibitor = null;
                return;
            }
        }

        if (root._idleInhibitor)
            root._idleInhibitor.inhibit = root.inhibiting;
    }

    onInhibitingChanged: root._syncIdleInhibitor()

    // Native Wayland idle inhibitor via a zero-size PanelWindow.
    // When visible, the compositor prevents idle timeouts.
    Component.onCompleted: {
        if (root.inhibiting)
            root._syncIdleInhibitor();
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string _sentinelPath: Quickshell.statePath("first_run_done")
    property bool _isFirstRun: false
    property bool _checked: false

    property FileView _sentinel: FileView {
        path: root._sentinelPath
        blockLoading: true
        printErrors: false
        onLoaded: {
            root._isFirstRun = false;
            root._checked = true;
        }
        onLoadFailed: error => {
            if (error === 2) {
                root._isFirstRun = true;
                root._checked = true;
                Qt.callLater(root._showWelcome);
            }
        }
    }

    function _showWelcome() {
        if (!_isFirstRun) return;

        var compositor = CompositorAdapter.isNiri ? "Niri" : (CompositorAdapter.isHyprland ? "Hyprland" : "Compositor");
        ToastService.showNotice(
            "Welcome to Quickshell",
            "Your shell is ready. Press Super+S for settings, Super+Space for launcher."
        );

        // Mark first run as complete
        _sentinel.setText("done");
        _isFirstRun = false;
    }
}

pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    property bool active: false
    property string _savedProfile: ""
    property bool _savedCaffeine: false

    function toggle() { active ? deactivate() : activate() }

    function activate() {
        _savedProfile = PowerProfileService.currentProfile;
        _savedCaffeine = Config.idleInhibitEnabled;
        if (PowerProfileService.available)
            PowerProfileService.setProfile("performance");
        Config.idleInhibitEnabled = true;
        _disableCompositorEffects();
        active = true;
        ToastService.showNotice("Game Mode", "Performance mode activated");
    }

    function deactivate() {
        if (PowerProfileService.available && _savedProfile)
            PowerProfileService.setProfile(_savedProfile);
        Config.idleInhibitEnabled = _savedCaffeine;
        _restoreCompositorEffects();
        active = false;
        ToastService.showNotice("Game Mode", "Performance mode deactivated");
    }

    function _disableCompositorEffects() {
        if (CompositorAdapter.isHyprland) {
            CompositorAdapter.setHyprKeyword("animations:enabled", "0");
            CompositorAdapter.setHyprKeyword("decoration:blur:enabled", "0");
        }
    }

    function _restoreCompositorEffects() {
        if (CompositorAdapter.isHyprland) {
            CompositorAdapter.setHyprKeyword("animations:enabled", "1");
            CompositorAdapter.setHyprKeyword("decoration:blur:enabled", "1");
        }
    }

    IpcHandler {
        target: "GameMode"
        function toggle() { root.toggle() }
        function isActive() { return root.active }
    }
}

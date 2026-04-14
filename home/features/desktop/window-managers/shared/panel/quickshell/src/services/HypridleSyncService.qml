pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "." as Services
import "HypridleConfig.js" as HypridleConfig

QtObject {
    id: root

    readonly property bool active: Services.CompositorAdapter.isHyprland
        && Services.Config.configReady
        && (Quickshell.env("QT_QPA_PLATFORM") || "").toLowerCase() !== "offscreen"
    readonly property string stateRoot: {
        var stateHome = Quickshell.env("XDG_STATE_HOME") || "";
        if (stateHome !== "")
            return stateHome + "/quickshell";
        var home = Quickshell.env("HOME") || "";
        return home !== "" ? home + "/.local/state/quickshell" : "/tmp/quickshell";
    }
    readonly property string configPath: stateRoot + "/hypridle.conf"
    readonly property bool batteryProfileActive: Services.SystemStatus.isBatteryPowered
    readonly property var selectedProfile: ({
        monitorTimeout: batteryProfileActive ? Services.Config.powerBatMonitorTimeout : Services.Config.powerAcMonitorTimeout,
        lockTimeout: batteryProfileActive ? Services.Config.powerBatLockTimeout : Services.Config.powerAcLockTimeout,
        suspendTimeout: batteryProfileActive ? Services.Config.powerBatSuspendTimeout : Services.Config.powerAcSuspendTimeout,
        suspendAction: batteryProfileActive ? Services.Config.powerBatSuspendAction : Services.Config.powerAcSuspendAction
    })
    readonly property string renderedConfig: HypridleConfig.render(selectedProfile)

    property string _lastAppliedConfig: ""

    function scheduleApply() {
        if (!root.active)
            return;
        applyTimer.restart();
    }

    function _writeFile(path, contents, onDone) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { stdinEnabled: true }',
            root,
            "HypridleConfigWriter"
        );
        proc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && cat > \"$1\"", "sh", path];
        proc.onStarted.connect(function() {
            proc.write(contents);
            proc.stdinEnabled = false;
        });
        proc.onExited.connect(function(code) {
            if (onDone)
                onDone(code === 0);
            proc.destroy();
        });
        proc.running = true;
    }

    function _restartHypridle() {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process {}',
            root,
            "HypridleRestartProc"
        );
        proc.command = ["systemctl", "--user", "restart", "hypridle.service"];
        proc.onExited.connect(function(code) {
            if (code !== 0)
                Services.Logger.w("HypridleSyncService", "failed to restart hypridle.service", code);
            proc.destroy();
        });
        proc.running = true;
    }

    function applyProfile() {
        if (!root.active)
            return;
        if (root.renderedConfig === root._lastAppliedConfig)
            return;

        var nextConfig = root.renderedConfig;
        root._writeFile(root.configPath, nextConfig, function(success) {
            if (!success) {
                Services.Logger.e("HypridleSyncService", "failed to write runtime hypridle config");
                return;
            }
            root._lastAppliedConfig = nextConfig;
            root._restartHypridle();
        });
    }

    Connections {
        target: Services.Config
        function onConfigReadyChanged() {
            root.scheduleApply();
        }
        function onPowerAcMonitorTimeoutChanged() {
            root.scheduleApply();
        }
        function onPowerAcLockTimeoutChanged() {
            root.scheduleApply();
        }
        function onPowerAcSuspendTimeoutChanged() {
            root.scheduleApply();
        }
        function onPowerAcSuspendActionChanged() {
            root.scheduleApply();
        }
        function onPowerBatMonitorTimeoutChanged() {
            root.scheduleApply();
        }
        function onPowerBatLockTimeoutChanged() {
            root.scheduleApply();
        }
        function onPowerBatSuspendTimeoutChanged() {
            root.scheduleApply();
        }
        function onPowerBatSuspendActionChanged() {
            root.scheduleApply();
        }
    }

    Connections {
        target: Services.SystemStatus
        function onIsBatteryPoweredChanged() {
            root.scheduleApply();
        }
    }

    property Timer applyTimer: Timer {
        interval: 250
        onTriggered: root.applyProfile()
    }

    Component.onCompleted: root.scheduleApply()
}

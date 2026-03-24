import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

ColumnLayout {
    id: root

    required property bool compactMode
    required property var resetLauncherDefaultsFn

    spacing: Appearance.spacingL

    SettingsCard {
        Layout.fillWidth: true
        title: "Runtime Behavior"
        iconName: "timer.svg"
        description: "Preload policy and runtime metric visibility."

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2
            minimumColumnWidth: 280

            SettingsToggleRow {
                label: "Background Preload"
                icon: "timer.svg"
                configKey: "launcherEnablePreload"
            }

            SettingsToggleRow {
                label: "Debug Launcher Timings"
                icon: "clock.svg"
                configKey: "launcherEnableDebugTimings"
            }

            SettingsToggleRow {
                label: "Show Runtime Metrics"
                icon: "board.svg"
                configKey: "launcherShowRuntimeMetrics"
            }
        }

        SettingsSliderRow {
            label: "Preload Failure Threshold"
            icon: "timer.svg"
            min: 1
            max: 10
            step: 1
            value: Config.launcherPreloadFailureThreshold
            unit: ""
            onMoved: v => Config.launcherPreloadFailureThreshold = v
        }

        SettingsSliderRow {
            label: "Preload Backoff"
            icon: "clock.svg"
            min: 10
            max: 900
            step: 10
            value: Config.launcherPreloadFailureBackoffSec
            unit: "s"
            onMoved: v => Config.launcherPreloadFailureBackoffSec = v
        }
    }

    LauncherDiagnosticsSettingsCard {
        Layout.fillWidth: true
        compactMode: root.compactMode
        resetLauncherDefaults: function() {
            root.resetLauncherDefaultsFn();
        }
    }
}

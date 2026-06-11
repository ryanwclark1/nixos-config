import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../../services/ShellUtils.js" as SU
import ".."

// Diagnostics & recovery controls for the launcher settings runtime section.
SettingsCard {
    id: root
    property bool compactMode: false
    property var resetLauncherDefaults: function() {}

    title: "Diagnostics & Recovery"
    iconName: "arrow-clockwise.svg"
    description: "Runtime reset actions and launcher maintenance controls."

    Flow {
        Layout.fillWidth: true
        spacing: Appearance.spacingS

        SettingsActionButton {
            width: root.compactMode ? implicitWidth : 0
            Layout.fillWidth: !root.compactMode
            label: "Reset Runtime Metrics"
            iconName: "arrow-clockwise.svg"
            compact: true
            onClicked: Quickshell.execDetached(SU.ipcCall("Launcher", "clearMetrics"))
        }

        SettingsActionButton {
            width: root.compactMode ? implicitWidth : 0
            Layout.fillWidth: !root.compactMode
            label: "Re-detect Files Backend"
            iconName: "arrow-counterclockwise.svg"
            compact: true
            onClicked: Quickshell.execDetached(SU.ipcCall("Launcher", "redetectFilesBackend"))
        }
    }

    SettingsActionButton {
        Layout.fillWidth: true
        label: "Launcher Diagnostic Reset"
        iconName: "timer.svg"
        compact: true
        onClicked: Quickshell.execDetached(SU.ipcCall("Launcher", "diagnosticReset"))
    }

    SettingsActionButton {
        Layout.fillWidth: true
        label: "Reset Launcher Defaults"
        iconName: "arrow-clockwise.svg"
        onClicked: root.resetLauncherDefaults()
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property string sectionMode: "system"
    readonly property bool isSystemSection: sectionMode === "system"
    readonly property bool isLauncherSection: sectionMode === "launcher"
    readonly property bool isLauncherGeneralSection: sectionMode === "launcher-general" || isLauncherSection
    readonly property bool isLauncherSearchSection: sectionMode === "launcher-search"
    readonly property bool isLauncherWebSection: sectionMode === "launcher-web"
    readonly property bool isLauncherModesSection: sectionMode === "launcher-modes"
    readonly property bool isLauncherRuntimeSection: sectionMode === "launcher-runtime"
    readonly property bool isControlCenterSection: sectionMode === "control-center"
    readonly property bool isAnyLauncherSection: isLauncherSection || isLauncherGeneralSection || isLauncherSearchSection || isLauncherWebSection || isLauncherModesSection || isLauncherRuntimeSection
    readonly property string pageTitle: {
        if (isLauncherSearchSection)
            return "Launcher Search";
        if (isLauncherWebSection)
            return "Launcher Web";
        if (isLauncherModesSection)
            return "Launcher Modes";
        if (isLauncherRuntimeSection)
            return "Launcher Runtime";
        if (isLauncherGeneralSection)
            return "Launcher";
        if (isControlCenterSection)
            return "Control Center";
        return "Shell";
    }
    readonly property string pageIcon: {
        if (isLauncherSearchSection)
            return "󰍉";
        if (isLauncherWebSection)
            return "󰖟";
        if (isLauncherModesSection)
            return "󰌌";
        if (isLauncherRuntimeSection)
            return "󰔟";
        if (isLauncherGeneralSection)
            return "󰍉";
        if (isControlCenterSection)
            return "󰖲";
        return "󰒓";
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: root.pageTitle
        iconName: root.pageIcon

        ShellSystemSection {
            visible: root.isSystemSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            settingsRoot: root.settingsRoot
        }

        ShellLauncherSection {
            visible: root.isAnyLauncherSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            settingsRoot: root.settingsRoot
            sectionMode: root.sectionMode
        }

        ShellControlCenterSection {
            visible: root.isControlCenterSection
            Layout.fillWidth: true
            compactMode: root.compactMode
            settingsRoot: root.settingsRoot
        }
    }
}

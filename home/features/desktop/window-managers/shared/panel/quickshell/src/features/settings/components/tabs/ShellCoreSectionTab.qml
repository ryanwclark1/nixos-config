import QtQuick
import QtQuick.Layouts
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

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId

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

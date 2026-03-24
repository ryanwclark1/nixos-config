import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

ColumnLayout {
    id: root

    required property bool compactMode
    required property var orderedPrimaryModesFn
    required property var orderedAdvancedModesFn
    required property var disabledLauncherModesFn
    required property var applyModePresetFn
    required property var primaryModeReorderState
    required property var advancedModeReorderState
    required property var beginPrimaryModeDragFn
    required property var moveDraggedPrimaryModeFn
    required property var beginAdvancedModeDragFn
    required property var moveDraggedAdvancedModeFn
    required property var clearModeDragStateFn
    required property var movePrimaryModeFn
    required property var moveAdvancedModeFn
    required property var launcherModeMetaFn
    required property var currentModeDropIndexFn
    required property var demoteLauncherModeFn
    required property var promoteLauncherModeFn
    required property var disableLauncherModeFn
    required property var enableLauncherModeFn

    spacing: Appearance.spacingL

    SettingsCard {
        Layout.fillWidth: true
        title: "Launcher Presets"
        iconName: "keyboard.svg"
        description: "Choose a focused default set, an extended power-user set, or everything."

        SettingsInfoCallout {
            iconName: "globe-search.svg"
            title: "Sidebar vs advanced"
            body: "Primary sidebar modes stay visible in the launcher. Advanced modes stay enabled, but live behind More and their prefixes."
        }

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SettingsActionButton {
                width: root.compactMode ? implicitWidth : 0
                Layout.fillWidth: !root.compactMode
                label: "Focused"
                compact: true
                onClicked: root.applyModePresetFn("focused")
            }

            SettingsActionButton {
                width: root.compactMode ? implicitWidth : 0
                Layout.fillWidth: !root.compactMode
                label: "Extended"
                compact: true
                onClicked: root.applyModePresetFn("extended")
            }

            SettingsActionButton {
                width: root.compactMode ? implicitWidth : 0
                Layout.fillWidth: !root.compactMode
                label: "All"
                compact: true
                onClicked: root.applyModePresetFn("all")
            }
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Primary Sidebar"
        iconName: "search-visual.svg"
        description: "These modes stay pinned in the launcher sidebar."

        LauncherModeList {
            id: primaryModeOrderList
            Layout.fillWidth: true
            modeModel: root.orderedPrimaryModesFn()
            reorderState: root.primaryModeReorderState
            listId: "launcher-primary-mode"
            compactMode: root.compactMode
            beginDragFn: root.beginPrimaryModeDragFn
            moveDraggedFn: root.moveDraggedPrimaryModeFn
            clearDragStateFn: root.clearModeDragStateFn
            moveModeFn: root.movePrimaryModeFn
            modeMetaFn: root.launcherModeMetaFn
            dropIndexFn: root.currentModeDropIndexFn
            promoteLabel: "Advanced"
            promoteFn: root.demoteLauncherModeFn
            disableFn: root.disableLauncherModeFn
            dropEndText: "Drop at end of primary sidebar"
            dragHintText: "Drag to reorder within the primary sidebar, or use the arrow buttons."
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Advanced / Prefix"
        iconName: "options.svg"
        description: "These modes stay enabled behind More. Prefix-first modes remain one keystroke away."

        SettingsInfoCallout {
            iconName: "globe-search.svg"
            title: "Prefix-first modes"
            body: "Settings, Run, SSH, and Web stay visible under the search field as prefix shortcuts even when they are not pinned in the sidebar."
        }

        LauncherModeList {
            id: advancedModeOrderList
            Layout.fillWidth: true
            modeModel: root.orderedAdvancedModesFn()
            reorderState: root.advancedModeReorderState
            listId: "launcher-advanced-mode"
            compactMode: root.compactMode
            beginDragFn: root.beginAdvancedModeDragFn
            moveDraggedFn: root.moveDraggedAdvancedModeFn
            clearDragStateFn: root.clearModeDragStateFn
            moveModeFn: root.moveAdvancedModeFn
            modeMetaFn: root.launcherModeMetaFn
            dropIndexFn: root.currentModeDropIndexFn
            promoteLabel: "Primary"
            promoteFn: root.promoteLauncherModeFn
            disableFn: root.disableLauncherModeFn
            dropEndText: "Drop at end of advanced modes"
            dragHintText: "Drag to reorder within advanced modes, or use the arrow buttons."
        }

        SettingsInfoCallout {
            visible: root.orderedAdvancedModesFn().length === 0
            iconName: "globe-search.svg"
            title: "No advanced modes"
            body: "Enable another launcher mode to keep it available behind More."
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Disabled Modes"
        iconName: "dismiss.svg"
        description: "Disabled modes are hidden from the launcher until you re-enable them."

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Repeater {
                model: root.disabledLauncherModesFn()

                delegate: SharedWidgets.FilterChip {
                    required property var modelData
                    label: root.launcherModeMetaFn(modelData).label
                    icon: root.launcherModeMetaFn(modelData).icon
                    selected: false
                    onClicked: root.enableLauncherModeFn(modelData, false)
                }
            }
        }

        SettingsInfoCallout {
            visible: root.disabledLauncherModesFn().length === 0
            iconName: "checkmark.svg"
            title: "Everything is enabled"
            body: "Use disable on a primary or advanced mode if you want to remove it from launcher cycling entirely."
        }
    }
}

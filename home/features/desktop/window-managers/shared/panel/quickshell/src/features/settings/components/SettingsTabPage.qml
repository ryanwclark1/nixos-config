pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../widgets" as SharedWidgets
import "../../../services"
import "."

SharedWidgets.ScrollableContent {
    id: root

    property var settingsRoot: null
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    readonly property var tabMeta: SettingsRegistry.findTab(tabId)
    readonly property string resolvedTitle: title !== "" ? title : (tabMeta ? String(tabMeta.label || "") : "")
    readonly property string resolvedSubtitle: subtitle !== "" ? subtitle : (tabMeta && tabMeta.description ? String(tabMeta.description) : "")
    readonly property string resolvedIconName: iconName !== "" ? iconName : (tabMeta ? String(tabMeta.icon || "") : "")
    readonly property var resolvedSettingsRoot: {
        if (root.settingsRoot)
            return root.settingsRoot;
        if (root.parent && root.parent.settingsRoot !== undefined)
            return root.parent.settingsRoot;
        return null;
    }

    default property alias pageContent: contentColumn.data

    anchors.fill: parent
    columnSpacing: Appearance.spacingXL

    ColumnLayout {
        id: contentColumn
        Layout.fillWidth: true
        Layout.leftMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        Layout.rightMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        Layout.topMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        Layout.bottomMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        spacing: Appearance.spacingXL

        SettingsPageHero {
            Layout.fillWidth: true
            settingsRoot: root.resolvedSettingsRoot
            tabId: root.tabId
            title: root.resolvedTitle
            subtitle: root.resolvedSubtitle
            iconName: root.resolvedIconName
            compactMode: root.compactMode
        }
    }
}

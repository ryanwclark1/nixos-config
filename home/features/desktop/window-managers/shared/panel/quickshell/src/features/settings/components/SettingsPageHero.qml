pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "."

Rectangle {
    id: root

    property var settingsRoot: null
    property string tabId: ""
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property bool compactMode: false

    readonly property var tabMeta: SettingsRegistry.findTab(tabId)
    readonly property var categoryMeta: tabMeta ? SettingsRegistry.findCategory(tabMeta.categoryId) : null
    readonly property string resolvedTitle: title !== "" ? title : (tabMeta ? String(tabMeta.label || "") : "")
    readonly property string resolvedSubtitle: subtitle !== "" ? subtitle : (tabMeta && tabMeta.description ? String(tabMeta.description) : "")
    readonly property string resolvedIcon: iconName !== "" ? iconName : (tabMeta ? String(tabMeta.icon || "") : "")
    readonly property string eyebrowText: categoryMeta ? String(categoryMeta.label || "Settings") : "Settings"
    readonly property string eyebrowDetail: categoryMeta && categoryMeta.description ? String(categoryMeta.description) : ""
    readonly property var relatedTabs: SettingsRegistry.relatedTabsFor(tabId, compactMode ? 3 : 4)

    Layout.fillWidth: true
    radius: Colors.radiusLarge
    color: Colors.withAlpha(Colors.surface, 0.7)
    border.color: Colors.withAlpha(Colors.primary, 0.18)
    border.width: 1
    implicitHeight: heroColumn.implicitHeight + (compactMode ? Colors.spacingM * 2 : Colors.spacingL * 2)
    clip: true

    SharedWidgets.InnerHighlight { highlightOpacity: 0.1 }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.max(parent.radius + Colors.spacingL, heroColumn.implicitHeight * 0.45)
        color: Colors.withAlpha(Colors.primary, 0.05)
    }

    ColumnLayout {
        id: heroColumn
        anchors.fill: parent
        anchors.margins: compactMode ? Colors.spacingM : Colors.spacingL
        spacing: compactMode ? Colors.spacingS : Colors.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            Rectangle {
                Layout.alignment: Qt.AlignTop
                width: compactMode ? 44 : 52
                height: width
                radius: Colors.radiusLarge
                color: Colors.primarySubtle
                border.color: Colors.primaryRing
                border.width: 1

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: root.resolvedIcon.endsWith(".svg") ? _heroSvgIcon : _heroNerdIcon
                }
                Component {
                    id: _heroSvgIcon
                    SharedWidgets.SvgIcon { source: root.resolvedIcon; color: Colors.primary; size: compactMode ? Colors.fontSizeXL : Colors.fontSizeXXL }
                }
                Component {
                    id: _heroNerdIcon
                    Text {
                        text: root.resolvedIcon
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: compactMode ? Colors.fontSizeXL : Colors.fontSizeXXL
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                Text {
                    text: root.eyebrowText.toUpperCase()
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                }

                Text {
                    Layout.fillWidth: true
                    text: root.resolvedTitle
                    color: Colors.text
                    font.pixelSize: compactMode ? Colors.fontSizeXL : Colors.fontSizeHuge
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingTight
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.resolvedSubtitle
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                    visible: !!text
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.eyebrowDetail
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
            visible: !!text
        }

        SettingsQuickLinksRow {
            Layout.fillWidth: true
            settingsRoot: root.settingsRoot
            currentTabId: root.tabId
            tabsModel: root.relatedTabs
        }

        SettingsSummaryStrip {
            Layout.fillWidth: true
            ownerMeta: root.tabMeta ? root.tabMeta.owner : null
        }
    }
}

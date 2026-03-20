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
    readonly property real heroPadding: compactMode ? Appearance.spacingM : Appearance.spacingL
    readonly property real heroSpacing: compactMode ? Appearance.spacingS : Appearance.spacingM
    readonly property bool showHeroMeta: quickLinksRow.visible || summaryStrip.visible
    readonly property real heroHeaderBandHeight: heroHeaderColumn.implicitHeight + root.heroPadding * 2 + (root.showHeroMeta ? root.heroSpacing * 0.5 : 0)

    Layout.fillWidth: true
    radius: Appearance.radiusLarge
    color: Colors.withAlpha(Colors.surface, 0.7)
    border.color: Colors.withAlpha(Colors.primary, 0.18)
    border.width: 1
    implicitHeight: heroContentColumn.implicitHeight + root.heroPadding * 2
    clip: true

    SharedWidgets.InnerHighlight { highlightOpacity: 0.1 }

    SettingsHeaderBand {
        accentColor: Colors.primary
        parentRadius: root.radius
        bandHeight: root.heroHeaderBandHeight
        dividerY: root.heroHeaderBandHeight
        showDivider: root.showHeroMeta
        surfaceStrength: 0.9
        accentStrength: 0.95
    }

    ColumnLayout {
        id: heroContentColumn
        anchors.fill: parent
        anchors.margins: root.heroPadding
        spacing: root.heroSpacing

        ColumnLayout {
            id: heroHeaderColumn
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingM

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    width: compactMode ? 44 : 52
                    height: width
                    radius: Appearance.radiusLarge
                    color: Colors.primarySubtle
                    border.color: Colors.primaryRing
                    border.width: 1

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: String(root.resolvedIcon).endsWith(".svg") ? _heroSvgIcon : _heroNerdIcon
                    }
                    Component {
                        id: _heroSvgIcon
                        SharedWidgets.SvgIcon { source: root.resolvedIcon; color: Colors.primary; size: compactMode ? Appearance.fontSizeXL : Appearance.fontSizeXXL }
                    }
                    Component {
                        id: _heroNerdIcon
                        Text {
                            text: root.resolvedIcon
                            color: Colors.primary
                            font.family: Appearance.fontMono
                            font.pixelSize: compactMode ? Appearance.fontSizeXL : Appearance.fontSizeXXL
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingXS

                    Text {
                        text: root.eyebrowText.toUpperCase()
                        color: Colors.primary
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingExtraWide
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.resolvedTitle
                        color: Colors.text
                        font.pixelSize: compactMode ? Appearance.fontSizeXL : Appearance.fontSizeHuge
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingTight
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.resolvedSubtitle
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeSmall
                        wrapMode: Text.WordWrap
                        visible: !!text
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.eyebrowDetail
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                wrapMode: Text.WordWrap
                visible: !!text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: root.showHeroMeta

            SettingsQuickLinksRow {
                id: quickLinksRow
                Layout.fillWidth: true
                settingsRoot: root.settingsRoot
                currentTabId: root.tabId
                tabsModel: root.relatedTabs
            }

            SettingsSummaryStrip {
                id: summaryStrip
                Layout.fillWidth: true
                ownerMeta: root.tabMeta ? root.tabMeta.owner : null
            }
        }
    }
}

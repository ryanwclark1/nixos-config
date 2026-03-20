import QtQuick
import QtQuick.Layouts
import "../../../services"
import "."

Rectangle {
    id: root

    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false

    readonly property var tabMeta: SettingsRegistry.findTab(tabId)
    readonly property string titleText: tabMeta ? String(tabMeta.label || "Launcher") : "Launcher"
    readonly property string descriptionText: tabMeta && tabMeta.description ? String(tabMeta.description) : "Tune the launcher runtime, search flow, and mode surfaces from one place."
    readonly property var launcherTabs: ["launcher", "launcher-search", "launcher-web", "launcher-modes", "launcher-runtime"].map(function(id) {
        return SettingsRegistry.findTab(id);
    }).filter(function(tab) {
        return !!tab;
    })

    Layout.fillWidth: true
    radius: Appearance.radiusLarge
    color: Colors.withAlpha(Colors.primary, 0.08)
    border.color: Colors.primaryMarked
    border.width: 1
    implicitHeight: heroColumn.implicitHeight + (compactMode ? Appearance.spacingM * 2 : Appearance.spacingL * 2)

    ColumnLayout {
        id: heroColumn
        anchors.fill: parent
        anchors.margins: compactMode ? Appearance.spacingM : Appearance.spacingL
        spacing: Appearance.spacingM

        Text {
            text: "LAUNCHER CONTROL DECK"
            color: Colors.primary
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Appearance.letterSpacingExtraWide
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingM

            Rectangle {
                width: compactMode ? 42 : 48
                height: width
                radius: Appearance.radiusLarge
                color: Colors.primarySubtle
                border.color: Colors.primaryRing
                border.width: 1

                SettingsMetricIcon {
                    anchors.centerIn: parent
                    icon: tabMeta ? String(tabMeta.icon || "settings.svg") : "settings.svg"
                    iconSize: compactMode ? Appearance.fontSizeXL : Appearance.fontSizeXXL
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS

                Text {
                    Layout.fillWidth: true
                    text: root.titleText
                    color: Colors.text
                    font.pixelSize: compactMode ? Appearance.fontSizeXL : Appearance.fontSizeHuge
                    font.weight: Font.Black
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.descriptionText
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Repeater {
                model: root.launcherTabs

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool selected: String(modelData.id || "") === root.tabId

                    radius: Appearance.radiusPill
                    color: selected ? Colors.primarySubtle : Colors.withAlpha(Colors.surface, 0.7)
                    border.color: selected ? Colors.primaryRing : Colors.border
                    border.width: 1
                    implicitHeight: 30
                    implicitWidth: tabChipRow.implicitWidth + 20

                    RowLayout {
                        id: tabChipRow
                        anchors.centerIn: parent
                        spacing: Appearance.spacingXS

                        SettingsMetricIcon {
                            icon: modelData.icon || "settings.svg"
                            iconColor: selected ? Colors.primary : Colors.textSecondary
                            iconSize: Appearance.fontSizeXS
                        }

                        Text {
                            text: modelData.label || ""
                            color: selected ? Colors.primary : Colors.text
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: selected ? Font.Bold : Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.settingsRoot)
                                return;
                            if (root.settingsRoot.clearSettingHighlight)
                                root.settingsRoot.clearSettingHighlight();
                            if (root.settingsRoot.setCurrentTab)
                                root.settingsRoot.setCurrentTab(String(modelData.id || ""));
                        }
                    }
                }
            }
        }
    }
}

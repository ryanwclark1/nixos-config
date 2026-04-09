import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    required property bool compactMode
    required property string currentLauncherTabId
    required property var launcherHeroMeta
    required property var launcherHeroTabs
    required property var selectTabFn

    Layout.fillWidth: true
    radius: Appearance.radiusLarge
    color: Colors.withAlpha(Colors.primary, 0.08)
    border.color: Colors.primaryMarked
    border.width: 1
    implicitHeight: launcherHeroColumn.implicitHeight + (root.compactMode ? Appearance.spacingM * 2 : Appearance.spacingL * 2)

    ColumnLayout {
        id: launcherHeroColumn
        anchors.fill: parent
        anchors.margins: root.compactMode ? Appearance.spacingM : Appearance.spacingL
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
                width: root.compactMode ? 42 : 48
                height: width
                radius: Appearance.radiusLarge
                color: Colors.primarySubtle
                border.color: Colors.primaryRing
                border.width: 1

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: String(root.launcherHeroMeta.icon).endsWith(".svg") ? launcherSvgIcon : launcherNerdIcon
                }

                Component {
                    id: launcherSvgIcon

                    SharedWidgets.SvgIcon {
                        source: root.launcherHeroMeta.icon
                        color: Colors.primary
                        size: root.compactMode ? Appearance.fontSizeXL : Appearance.fontSizeXXL
                    }
                }

                Component {
                    id: launcherNerdIcon

                    Text {
                        text: root.launcherHeroMeta.icon
                        color: Colors.primary
                        font.family: Appearance.fontMono
                        font.pixelSize: root.compactMode ? Appearance.fontSizeXL : Appearance.fontSizeXXL
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS

                Text {
                    Layout.fillWidth: true
                    text: root.launcherHeroMeta.label
                    color: Colors.text
                    font.pixelSize: root.compactMode ? Appearance.fontSizeXL : Appearance.fontSizeHuge
                    font.weight: Font.Black
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.launcherHeroMeta.description
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            Repeater {
                model: root.launcherHeroTabs

                delegate: SharedWidgets.FilterChip {
                    required property var modelData
                    label: modelData.label
                    icon: modelData.icon
                    selected: modelData.id === root.currentLauncherTabId
                    onClicked: root.selectTabFn(modelData.id)
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            Repeater {
                model: root.launcherHeroMeta.chips

                delegate: SharedWidgets.Chip {
                    required property string modelData
                    text: modelData
                    icon: "info.svg"
                    iconColor: Colors.primary
                    textColor: Colors.text
                    bgColor: Colors.withAlpha(Colors.primary, 0.1)
                    borderColor: Colors.withAlpha(Colors.primary, 0.18)
                }
            }
        }
    }
}

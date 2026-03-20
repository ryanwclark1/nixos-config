import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    required property var providers
    required property string selectedKey
    property color accentColor: Colors.primary

    signal providerSelected(string key)

    Layout.fillWidth: true
    color: "transparent"
    implicitHeight: providerFlowContainer.implicitHeight

    Column {
        id: providerFlowContainer
        anchors.fill: parent
        spacing: Appearance.spacingXS

        Text {
            color: Colors.withAlpha(root.accentColor, 0.92)
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Appearance.letterSpacingExtraWide
            text: "ACTIVE PROVIDERS"
        }

        Flow {
            width: parent.width
            spacing: Appearance.spacingS

            Repeater {
                model: root.providers

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool selected: String(modelData.key || "") === root.selectedKey
                    color: selected ? Colors.withAlpha(root.accentColor, 0.16) : Colors.withAlpha(Colors.surface, 0.72)
                    radius: Appearance.radiusPill
                    border.color: selected ? Colors.withAlpha(root.accentColor, 0.4) : Colors.border
                    border.width: 1
                    implicitHeight: 28
                    implicitWidth: Math.min(providerChipRow.implicitWidth + 24, providerFlowContainer.width)

                    RowLayout {
                        id: providerChipRow
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 18)
                        spacing: Appearance.spacingXS

                        Loader {
                            readonly property string iconName: String(modelData.icon || "globe-search.svg")
                            sourceComponent: iconName.endsWith(".svg") ? providerSvgIcon : providerGlyphIcon
                        }

                        Text {
                            text: modelData.name || ""
                            color: parent.parent.selected ? root.accentColor : Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Component {
                        id: providerSvgIcon
                        SharedWidgets.SvgIcon {
                            source: parent.iconName
                            color: parent.parent.parent.selected ? root.accentColor : Colors.textSecondary
                            size: Appearance.fontSizeXS
                        }
                    }

                    Component {
                        id: providerGlyphIcon
                        Text {
                            text: parent.iconName
                            color: parent.parent.parent.selected ? root.accentColor : Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            font.family: Appearance.fontMono
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.providerSelected(String(modelData.key || ""))
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets
import "LauncherModeData.js" as ModeData

Rectangle {
    id: root

    required property bool tightMode
    required property string mode
    required property real parentRadius
    property color accentColor: Colors.primary
    property string modeLabel: "Launcher"
    property string heroLabel: "Launcher"
    property string summaryText: ""
    property string statusText: ""
    property string statusIcon: ""
    property string modePrefix: ""
    property string modeIcon: "󰍉"

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: tightMode ? 46 : 64
    radius: parentRadius
    color: Colors.withAlpha(Colors.surface, 0.98)
    border.width: 0

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Colors.withAlpha(root.accentColor, 0.18)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.tightMode ? Appearance.spacingM : Appearance.spacingL
        anchors.rightMargin: root.tightMode ? Appearance.spacingM : Appearance.spacingL
        spacing: root.tightMode ? Appearance.spacingS : Appearance.spacingM

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: root.tightMode ? 28 : 38
            height: width
            radius: root.tightMode ? Appearance.radiusMedium : Appearance.radiusLarge
            color: Colors.withAlpha(root.accentColor, root.tightMode ? 0.18 : 0.22)
            border.color: Colors.withAlpha(root.accentColor, 0.52)
            border.width: 1

            SharedWidgets.InnerHighlight {
                highlightOpacity: 0.18
            }

            Loader {
                anchors.centerIn: parent
                sourceComponent: (root.modeIcon || "").endsWith(".svg") ? _chromeSvg : _chromeNerd
            }
            Component { id: _chromeSvg; SharedWidgets.SvgIcon { source: root.modeIcon; color: root.accentColor; size: root.tightMode ? Appearance.fontSizeLarge : Appearance.fontSizeXL } }
            Component { id: _chromeNerd; Text { text: root.modeIcon; color: root.accentColor; font.family: Appearance.fontMono; font.pixelSize: root.tightMode ? Appearance.fontSizeLarge : Appearance.fontSizeXL } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: "COMMAND DECK"
                color: Colors.withAlpha(root.accentColor, 0.9)
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingExtraWide
            }

            Text {
                Layout.fillWidth: true
                text: root.heroLabel
                color: Colors.text
                font.pixelSize: root.tightMode ? Appearance.fontSizeMedium : Appearance.fontSizeXL
                font.weight: Font.Black
                font.letterSpacing: root.tightMode ? 0 : Appearance.letterSpacingTight
                elide: Text.ElideRight
            }

            Text {
                visible: !root.tightMode && root.summaryText !== ""
                Layout.fillWidth: true
                text: root.summaryText
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacingS

            Rectangle {
                visible: root.modePrefix !== "" && !root.tightMode
                radius: Appearance.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.34)
                border.width: 1
                implicitHeight: 24
                implicitWidth: prefixLabel.implicitWidth + 16

                Text {
                    id: prefixLabel
                    anchors.centerIn: parent
                    text: root.modePrefix + " prefix"
                    color: root.accentColor
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Black
                }
            }

            Rectangle {
                radius: Appearance.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.36)
                border.width: 1
                implicitHeight: root.tightMode ? 24 : 26
                implicitWidth: chromeModeLabel.implicitWidth + 18

                Text {
                    id: chromeModeLabel
                    anchors.centerIn: parent
                    text: root.modeLabel
                    color: root.accentColor
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Black
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Appearance.letterSpacingWide
                }
            }

            Rectangle {
                visible: !root.tightMode && root.statusText !== ""
                radius: Appearance.radiusPill
                color: Colors.withAlpha(Colors.surface, 0.84)
                border.color: Colors.border
                border.width: 1
                implicitHeight: 26
                implicitWidth: statusRow.implicitWidth + 16

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacingXS

                    Loader {
                        visible: root.statusIcon !== ""
                        sourceComponent: (root.statusIcon || "").endsWith(".svg") ? _statusSvg : _statusNerd
                    }
                    Component { id: _statusSvg; SharedWidgets.SvgIcon { source: root.statusIcon; color: root.accentColor; size: Appearance.fontSizeXS } }
                    Component { id: _statusNerd; Text { text: root.statusIcon; color: root.accentColor; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXS } }

                    Text {
                        text: root.statusText
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}

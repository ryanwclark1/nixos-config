import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../menu/settings"
import ".." as SharedWidgets

SharedWidgets.CollapsibleSection {
    id: root
    required property var sshData

    Layout.fillWidth: true
    title: "Import Diagnostics"
    icon: "󰅚"
    expanded: root.sshData.importErrors.length > 0 || root.sshData.skippedPatternEntries.length > 0

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingS

        SettingsInfoCallout {
            Layout.fillWidth: true
            visible: root.sshData.importErrors.length === 0 && root.sshData.skippedPatternEntries.length === 0
            title: "No import diagnostics"
            body: "SSH config import has no current errors or skipped wildcard patterns."
        }

        Repeater {
            model: root.sshData.importErrors

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: errorColumn.implicitHeight + Colors.spacingS * 2
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.warning, 0.08)
                border.color: Colors.withAlpha(Colors.warning, 0.35)
                border.width: 1

                ColumnLayout {
                    id: errorColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXXS

                    Text {
                        text: String(modelData.message || "Import error")
                        color: Colors.warning
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: String(modelData.path || "") + (Number(modelData.line || 0) > 0 ? (":" + String(modelData.line || 0)) : "")
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        Repeater {
            model: root.sshData.skippedPatternEntries

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: skippedColumn.implicitHeight + Colors.spacingS * 2
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: skippedColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXXS

                    Text {
                        text: "Skipped pattern: " + String(modelData.alias || "")
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: String(modelData.sourcePath || "") + (Number(modelData.sourceLine || 0) > 0 ? (":" + String(modelData.sourceLine || 0)) : "")
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}

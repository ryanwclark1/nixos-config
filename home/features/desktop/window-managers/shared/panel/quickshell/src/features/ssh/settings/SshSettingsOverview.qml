import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../menu/settings"

Rectangle {
    id: root
    required property var sshData
    signal resetStateRequested()
    signal resetAllRequested()

    Layout.fillWidth: true
    implicitHeight: overviewColumn.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: overviewColumn
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        Text {
            text: "Overview"
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
        }

        SettingsDataRow {
            Layout.fillWidth: true
            label: "Import Root"
            iconName: "󰈔"
            value: root.sshData.importRootPath
        }

        SettingsDataRow {
            Layout.fillWidth: true
            label: "Imported Aliases"
            iconName: "󰮔"
            value: String(root.sshData.importedHosts.length)
            monoValue: false
        }

        SettingsDataRow {
            Layout.fillWidth: true
            label: "Skipped Patterns"
            iconName: "󰇘"
            value: String(root.sshData.skippedPatternEntries.length)
            monoValue: false
        }

        SettingsDataRow {
            Layout.fillWidth: true
            label: "Import Errors"
            iconName: "󰅚"
            value: String(root.sshData.importErrors.length)
            monoValue: false
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SettingsActionButton {
                compact: true
                iconName: "󰑐"
                label: "Reset State"
                onClicked: root.resetStateRequested()
            }

            SettingsActionButton {
                compact: true
                iconName: "󰩺"
                label: "Reset All"
                onClicked: root.resetAllRequested()
            }
        }
    }
}

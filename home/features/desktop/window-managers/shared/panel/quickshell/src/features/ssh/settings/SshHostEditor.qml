import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../features/settings/components"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root
    required property string formLabel
    required property string formHost
    required property string formUser
    required property string formPort
    required property string formRemoteCommand
    required property string formTags
    required property string formGroup
    required property string formError
    required property bool isEditingExisting

    signal save()
    signal clear()
    signal cancel()
    signal fieldChanged(string field, string value)

    Layout.fillWidth: true
    implicitHeight: editorColumn.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusMedium
    color: Colors.modalFieldSurface
    border.color: root.formError !== "" ? Colors.error : (root.isEditingExisting ? Colors.primary : Colors.border)
    border.width: 1

    ColumnLayout {
        id: editorColumn
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
                text: root.isEditingExisting ? "Edit Host" : "Host Editor"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            SharedWidgets.FilterChip {
                label: root.isEditingExisting ? "Existing" : "New"
                selected: root.isEditingExisting
                enabled: false
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.isEditingExisting
                ? "Update the selected manual host. Cancel returns to list mode without saving."
                : "Create a new manual SSH host entry. Save persists only when the draft validates."
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            wrapMode: Text.WordWrap
        }

        SettingsTextInputRow {
            label: "Label"
            placeholderText: "Production Bastion"
            text: root.formLabel
            onTextEdited: value => root.fieldChanged("label", value)
            errorText: root.formError
        }

        SettingsTextInputRow {
            label: "Host"
            placeholderText: "bastion.example.com"
            text: root.formHost
            onTextEdited: value => root.fieldChanged("host", value)
        }

        SettingsTextInputRow {
            label: "User"
            placeholderText: "ubuntu"
            text: root.formUser
            onTextEdited: value => root.fieldChanged("user", value)
        }

        SettingsTextInputRow {
            label: "Port"
            placeholderText: "22"
            text: root.formPort
            onTextEdited: value => root.fieldChanged("port", value)
        }

        SettingsTextInputRow {
            label: "Remote Command"
            placeholderText: "tmux attach"
            text: root.formRemoteCommand
            onTextEdited: value => root.fieldChanged("remoteCommand", value)
        }

        SettingsTextInputRow {
            label: "Tags"
            placeholderText: "prod, infra"
            text: root.formTags
            onTextEdited: value => root.fieldChanged("tags", value)
        }

        SettingsTextInputRow {
            label: "Group"
            placeholderText: "platform"
            text: root.formGroup
            onTextEdited: value => root.fieldChanged("group", value)
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            SettingsActionButton {
                compact: true
                iconName: "save.svg"
                label: root.isEditingExisting ? "Save Changes" : "Save Host"
                onClicked: root.save()
            }

            SettingsActionButton {
                compact: true
                iconName: "delete.svg"
                label: "Clear"
                onClicked: root.clear()
            }

            SettingsActionButton {
                compact: true
                iconName: "dismiss.svg"
                label: "Cancel"
                visible: root.isEditingExisting
                onClicked: root.cancel()
            }
        }
    }
}

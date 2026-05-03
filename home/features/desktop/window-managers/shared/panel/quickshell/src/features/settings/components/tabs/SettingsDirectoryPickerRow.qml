import QtQuick
import QtQuick.Layouts
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets

SettingsTextInputRow {
    id: root

    property string callerId: ""

    SettingsActionButton {
        label: "Browse…"
        iconName: "folder.svg"
        compact: true
        onClicked: {
            if (settingsRoot && root.callerId !== "") {
                settingsRoot.pickFolder(root.callerId);
            }
        }
    }
}

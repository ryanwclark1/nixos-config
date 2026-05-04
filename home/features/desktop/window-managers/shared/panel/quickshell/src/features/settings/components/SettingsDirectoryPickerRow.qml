import QtQuick
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

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

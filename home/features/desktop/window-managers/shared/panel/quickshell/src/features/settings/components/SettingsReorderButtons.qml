import QtQuick
import QtQuick.Layouts
import "../../../services"

RowLayout {
    id: root

    property bool compact: true
    property bool moveUpEnabled: true
    property bool moveDownEnabled: true

    signal moveUp()
    signal moveDown()

    spacing: Appearance.spacingS

    SettingsActionButton {
        compact: root.compact
        iconName: "chevron-up.svg"
        enabled: root.moveUpEnabled
        onClicked: root.moveUp()
    }

    SettingsActionButton {
        compact: root.compact
        iconName: "chevron-down.svg"
        enabled: root.moveDownEnabled
        onClicked: root.moveDown()
    }
}

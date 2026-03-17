import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Desktop Widgets"
        iconName: "󰖲"

        SettingsCard {
            title: "Widgets"
            iconName: "󰖲"
            description: "Desktop widget visibility, snapping, and edit mode."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Desktop Widgets"
                    icon: "󰖲"
                    configKey: "desktopWidgetsEnabled"
                }
                SettingsToggleRow {
                    label: "Grid Snap"
                    icon: "󰕰"
                    configKey: "desktopWidgetsGridSnap"
                }
            }

            SettingsActionButton {
                Layout.fillWidth: true
                emphasized: true
                iconName: "󰏫"
                label: "Edit Widgets"
                onClicked: {
                    DesktopWidgetRegistry.editMode = true;
                    if (root.settingsRoot)
                        root.settingsRoot.close();
                }
            }
        }
    }
}

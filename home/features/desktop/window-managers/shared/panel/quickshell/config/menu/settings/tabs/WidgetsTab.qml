import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "Desktop Widgets"
    iconName: "󰖲"

    SettingsCard {
      title: "Widgets"
      iconName: "󰖲"

      SettingsFieldGrid {
        SettingsToggleRow { label: "Desktop Widgets"; icon: "󰖲"; configKey: "desktopWidgetsEnabled" }
        SettingsToggleRow { label: "Grid Snap"; icon: "󰕰"; configKey: "desktopWidgetsGridSnap" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 42
        radius: Colors.radiusSmall
        color: Colors.surface
        border.color: Colors.primary
        border.width: 1

        SharedWidgets.StateLayer {
          id: editWidgetsStateLayer
          hovered: editWidgetsHover.containsMouse
          pressed: editWidgetsHover.pressed
          stateColor: Colors.primary
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: Colors.spacingS
          Text { text: "󰏫"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
          Text { text: "Edit Widgets"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: Colors.fontSizeMedium }
        }

        MouseArea {
          id: editWidgetsHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            editWidgetsStateLayer.burst(mouse.x, mouse.y);
            DesktopWidgetRegistry.editMode = true;
            if (root.settingsRoot) root.settingsRoot.close();
          }
        }
      }
    }
  }
}

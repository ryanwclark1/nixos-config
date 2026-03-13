import QtQuick
import QtQuick.Layouts
import Quickshell
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
    title: "Hyprland Layout"
    iconName: "󱗼"

    SettingsCard {
      title: "Display Configuration"
      iconName: "󰍺"

      Rectangle {
        Layout.fillWidth: true
        height: 48
        radius: Colors.radiusSmall
        color: configDisplaysHover.containsMouse
               ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
               : Colors.bgWidget
        border.color: Colors.primary
        border.width: 1
        Behavior on color { ColorAnimation { duration: 160 } }

        RowLayout {
          anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
          spacing: Colors.spacingM
          Text { text: "󰍺"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
          Text { text: "Configure Displays"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: Colors.fontSizeMedium }
          Item { Layout.fillWidth: true }
          Text { text: "Arrange, resize & scale monitors →"; color: Colors.fgDim; font.pixelSize: Colors.fontSizeSmall }
        }

        MouseArea {
          id: configDisplaysHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.settingsRoot) root.settingsRoot.close();
            Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleDisplayConfig"]);
          }
        }
      }
    }

    SettingsCard {
      title: "Window Layout"
      iconName: "󱗼"

      RowLayout {
        spacing: Colors.spacingXL
        Layout.fillWidth: true
        Text { text: "Master Layout"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; Layout.fillWidth: true }
        SharedWidgets.DankToggle {
          checked: root.settingsRoot ? root.settingsRoot.layoutIsMaster : false
          onToggled: {
            if (!root.settingsRoot) return;
            var newLayout = !checked ? "master" : "dwindle";
            Quickshell.execDetached(["hyprctl", "keyword", "general:layout", newLayout]);
            root.settingsRoot.layoutIsMaster = !checked;
          }
        }
      }

      SettingsSliderRow {
        label: "Outer Gaps"
        min: 0; max: 50
        value: root.settingsRoot ? root.settingsRoot.layoutGapsOut : 10
        onMoved: (v) => {
          if (!root.settingsRoot) return;
          root.settingsRoot.layoutGapsOut = v;
          Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", v.toString()]);
        }
      }

      SettingsSliderRow {
        label: "Inner Gaps"
        min: 0; max: 30
        value: root.settingsRoot ? root.settingsRoot.layoutGapsIn : 5
        onMoved: (v) => {
          if (!root.settingsRoot) return;
          root.settingsRoot.layoutGapsIn = v;
          Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", v.toString()]);
        }
      }

      SettingsSliderRow {
        label: "Active Opacity"
        min: 0.5; max: 1.0; step: 0.05
        value: root.settingsRoot ? root.settingsRoot.layoutActiveOpacity : 1.0
        onMoved: (v) => {
          if (!root.settingsRoot) return;
          root.settingsRoot.layoutActiveOpacity = v;
          Quickshell.execDetached(["hyprctl", "keyword", "decoration:active_opacity", v.toString()]);
        }
      }
    }
  }
}

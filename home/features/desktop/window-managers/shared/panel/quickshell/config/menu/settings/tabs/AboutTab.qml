import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  property string aboutKernel: ""
  property string aboutHostname: ""
  property string aboutUptime: ""

  Process {
    id: aboutInfoProc
    command: ["sh", "-c", "uname -r; echo '---'; hostname; echo '---'; uptime -p"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = (this.text || "").split("---");
        root.aboutKernel = parts[0] ? parts[0].trim() : "";
        root.aboutHostname = parts[1] ? parts[1].trim() : "";
        root.aboutUptime = parts[2] ? parts[2].trim() : "";
      }
    }
  }

  Process {
    id: restartShellProc
    command: ["sh", "-c", "quickshell --restart || quickshell-restart || qs --restart || true"]
    running: false
  }

  Component.onCompleted: {
    if (!aboutInfoProc.running) aboutInfoProc.running = true;
  }

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "About"
    iconName: "󰭹"

    SettingsCard {
      title: "QuickShell"
      iconName: "󱗼"

      Text {
        text: "QML Desktop Shell"
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeMedium
      }
    }

    SettingsCard {
      title: "System Info"
      iconName: "󰘚"

      Repeater {
        model: [
          { icon: "󰍹", label: "Hostname", value: root.aboutHostname || "…" },
          { icon: "󰌢", label: "Kernel", value: root.aboutKernel || "…" },
          { icon: "󱑎", label: "Uptime", value: root.aboutUptime || "…" }
        ]

        delegate: Rectangle {
          Layout.fillWidth: true
          height: 52
          radius: Colors.radiusXS
          color: Colors.bgWidget
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors {
              fill: parent
              leftMargin: Colors.spacingM
              rightMargin: Colors.spacingM
            }
            spacing: Colors.spacingM

            Text {
              text: modelData.icon
              color: Colors.primary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeXL
            }
            Text {
              text: modelData.label
              color: Colors.fgSecondary
              font.pixelSize: Colors.fontSizeMedium
              Layout.preferredWidth: 80
            }
            Text {
              text: modelData.value
              color: Colors.text
              font.pixelSize: Colors.fontSizeMedium
              font.family: Colors.fontMono
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }
      }
    }

    SettingsCard {
      title: "Actions"
      iconName: "󰜉"

      Rectangle {
        Layout.fillWidth: true
        height: 48
        radius: Colors.radiusSmall
        color: Colors.primary

        SharedWidgets.StateLayer {
          id: restartStateLayer
          hovered: restartHover.containsMouse
          pressed: restartHover.pressed
          stateColor: Colors.primary
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: Colors.spacingM
          Text {
            text: "󰜉"
            color: Colors.text
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
          }
          Text {
            text: "Restart Shell"
            color: Colors.text
            font.weight: Font.Bold
            font.pixelSize: Colors.fontSizeMedium
          }
        }

        MouseArea {
          id: restartHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            restartStateLayer.burst(mouse.x, mouse.y);
            if (root.settingsRoot) root.settingsRoot.close();
            restartShellProc.running = true;
          }
        }
      }
    }

    SettingsCard {
      title: "Credits"
      iconName: "󰀾"

      Text {
        text: "Built with Quickshell"
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
      }
      Text {
        text: "Powered by Qt / QML"
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeMedium
      }
      Text {
        text: "Icons: Nerd Fonts"
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeMedium
      }
      Text {
        text: Config.themeName ? "Theme: " + Config.themeName : "Theming: pywal"
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeMedium
      }
    }
  }
}

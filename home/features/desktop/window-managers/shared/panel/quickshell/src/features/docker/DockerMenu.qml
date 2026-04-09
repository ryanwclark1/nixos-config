import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/SearchUtils.js" as SU
import "../../services/ShellUtils.js" as ShellUtils
import "../../widgets" as SharedWidgets
import "../settings/components"

BasePopupMenu {
  id: root
  popupMaxWidth: 440
  compactThreshold: 360
  implicitHeight: compactMode ? 560 : 600
  title: "Docker"
  subtitle: ServiceUnitService.dockerBusy ? "Refreshing containers..." : "Manage containers and images"
  contentSpacing: Appearance.spacingM
  focusOnOpen: true
  initialFocusTarget: searchBar.inputItem

  property var surfaceContext: null
  property string searchQuery: ""

  readonly property var filteredContainersResult: {
    var query = searchQuery.toLowerCase().trim();
    if (!query)
      return ServiceUnitService.dockerContainers;
    return ServiceUnitService.dockerContainers.filter(function(c) {
      if (!c) return false;
      var text = (String(c.name || "") + " " + String(c.image || "") + " " + String(c.id || "")).toLowerCase();
      return text.indexOf(query) !== -1;
    });
  }

  readonly property int totalContainers: ServiceUnitService.dockerContainers.length
  readonly property int runningContainers: {
    var count = 0;
    for (var i = 0; i < ServiceUnitService.dockerContainers.length; ++i) {
      if (ServiceUnitService.dockerContainers[i].state === "running") 
        count++;
    }
    return count;
  }
  readonly property int stoppedContainers: totalContainers - runningContainers

  readonly property bool hasSearchQuery: searchQuery.trim() !== ""
  readonly property bool hasContainers: totalContainers > 0
  readonly property bool hasFilteredContainers: filteredContainersResult.length > 0

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "arrow-clockwise.svg"
      tooltipText: "Refresh Docker state"
      onClicked: ServiceUnitService.dockerPoll.triggerPoll()
    }
  ]

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: statusGrid.implicitHeight + 16
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: ServiceUnitService.dockerStatus === "ready" ? Colors.border : Colors.warning
    border.width: 1

    GridLayout {
      id: statusGrid
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Appearance.spacingM
      }
      columns: root.compactMode ? 2 : 3
      columnSpacing: Appearance.spacingM
      rowSpacing: Appearance.spacingS

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: root.totalContainers
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Total"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: root.runningContainers
          color: Colors.primary
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Running"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: root.stoppedContainers
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Stopped"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }
  }

  SharedWidgets.SearchBar {
    id: searchBar
    placeholder: "Search containers by name, ID, or image..."
    preferredHeight: root.compactMode ? 34 : 36
    Layout.fillWidth: true
    onTextChanged: root.searchQuery = text
    inputItem.Keys.onEscapePressed: {
      if (searchBar.text !== "")
        searchBar.text = "";
      else
        root.closeRequested();
    }
  }

  SharedWidgets.ScrollableContent {
    id: scrollContent
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingS
    visible: !logOverlay.visible

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !ServiceUnitService.dockerBusy && !root.hasContainers
      icon: "server.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No Docker containers found"
    }

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !ServiceUnitService.dockerBusy && root.hasContainers && root.hasSearchQuery && !root.hasFilteredContainers
      icon: "search-visual.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No containers match \"" + root.searchQuery + "\""
    }

    Repeater {
      model: ScriptModel { values: root.filteredContainersResult }

      delegate: Rectangle {
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: hostLayout.implicitHeight + 20
        radius: Appearance.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
          id: hostLayout
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.spacingM
          }
          spacing: Appearance.spacingS

          RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.SvgIcon {
              source: "server.svg"
              color: modelData.state === "running" ? Colors.primary : Colors.textDisabled
              size: Appearance.fontSizeLarge
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Appearance.spacingXXS

              Text {
                text: String(modelData.name || "Unknown")
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: String(modelData.image || "")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                font.family: Appearance.fontMono
                elide: Text.ElideMiddle
                Layout.fillWidth: true
              }

              Text {
                text: String(modelData.status || "")
                color: modelData.state === "running" ? Colors.primary : Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Bold
                elide: Text.ElideMiddle
                Layout.fillWidth: true
              }
            }
          }

          Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            SettingsActionButton {
              compact: true
              iconName: modelData.state === "running" ? "stop.svg" : "play.svg"
              label: modelData.state === "running" ? "Stop" : "Start"
              onClicked: {
                ServiceUnitService.runDockerAction(modelData.id, modelData.state === "running" ? "stop" : "start");
              }
            }

            SettingsActionButton {
              compact: true
              iconName: "arrow-counterclockwise.svg"
              label: "Restart"
              visible: modelData.state === "running"
              onClicked: {
                ServiceUnitService.runDockerAction(modelData.id, "restart");
              }
            }

            SettingsActionButton {
              compact: true
              iconName: "text-description.svg"
              label: "Logs"
              onClicked: {
                logOverlay.title = "Docker: " + modelData.name;
                logOverlay.command = ServiceUnitService.getLogStreamCommand("docker", modelData.id);
                logOverlay.visible = true;
              }
            }

            SettingsActionButton {
              compact: true
              iconName: "terminal.svg"
              label: "Terminal"
              visible: modelData.state === "running"
              onClicked: {
                root.closeRequested();
                var cmd = "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then \"$runtime\" exec -it " + ShellUtils.shellQuote(modelData.id) + " /bin/sh; else exit 1; fi";
                Quickshell.execDetached(ShellUtils.terminalCommand(cmd));
              }
            }

            SettingsActionButton {
              compact: true
              iconName: "copy.svg"
              label: "Copy ID"
              onClicked: {
                Quickshell.execDetached(["sh", "-c", "printf '%s' " + ShellUtils.shellQuote(modelData.id) + " | (wl-copy || xclip -selection clipboard)"]);
              }
            }
          }
        }
      }
    }
  }

  SharedWidgets.LiveLogOverlay {
    id: logOverlay
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: false
    onCloseRequested: {
      visible = false;
      command = [];
    }
  }
}

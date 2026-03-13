import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Item {
  id: root
  anchors.fill: parent

  property string screenName: parent ? (parent.screen ? parent.screen.name : "") : ""

  visible: Config.desktopWidgetsEnabled || DesktopWidgetRegistry.editMode

  // Get widgets for this screen from config
  property var screenWidgets: DesktopWidgetRegistry.getWidgetsForScreen(screenName)
  onScreenNameChanged: screenWidgets = DesktopWidgetRegistry.getWidgetsForScreen(screenName)

  // Refresh when config changes
  Connections {
    target: Config
    function onDesktopWidgetsMonitorWidgetsChanged() {
      root.screenWidgets = DesktopWidgetRegistry.getWidgetsForScreen(root.screenName);
    }
  }

  IpcHandler {
    target: "DesktopWidgets"
    function toggleEditMode() {
      DesktopWidgetRegistry.editMode = !DesktopWidgetRegistry.editMode;
    }
  }

  // Grid overlay (only in edit mode with grid snap)
  Canvas {
    anchors.fill: parent
    visible: DesktopWidgetRegistry.editMode && Config.desktopWidgetsGridSnap
    opacity: 0.08
    onPaint: {
      var ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      ctx.strokeStyle = Colors.text;
      ctx.lineWidth = 1;
      var gridSize = 20;
      for (var x = 0; x < width; x += gridSize) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }
      for (var y = 0; y < height; y += gridSize) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
      }
    }
  }

  // Widget instances
  Repeater {
    model: root.screenWidgets

    delegate: DraggableDesktopWidget {
      required property var modelData
      required property int index

      widgetId: modelData.id || ""
      widgetType: modelData.type || ""
      screenName: root.screenName
      x: modelData.x || 0
      y: modelData.y || 0
      widgetScale: modelData.scale || 1.0

      // Load the appropriate widget component based on type
      Loader {
        active: true
        source: DesktopWidgetRegistry.pluginSourceForWidgetType(widgetType)
        sourceComponent: {
          if (source !== "") return undefined;
          switch (widgetType) {
            case "Clock": return clockComponent;
            case "SystemStat": return systemStatComponent;
            case "Weather": return weatherComponent;
            default: return placeholderComponent;
          }
        }
      }
    }
  }

  // Edit mode controls panel
  Rectangle {
    visible: DesktopWidgetRegistry.editMode
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 100
    width: editRow.implicitWidth + 40
    height: 48
    radius: 24
    color: Colors.bgGlass
    border.color: Colors.primary
    border.width: 2

    RowLayout {
      id: editRow
      anchors.centerIn: parent
      spacing: Colors.spacingL

      // Add Widget button with dropdown
      Item {
        Layout.preferredWidth: addRow.implicitWidth
        Layout.preferredHeight: 32

        RowLayout {
          id: addRow
          anchors.centerIn: parent
          spacing: 6

          Text {
            text: "󰐕"
            color: Colors.primary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
          }
          Text {
            text: "Add Widget"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Medium
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: addWidgetMenu.visible = !addWidgetMenu.visible
        }

        // Add widget dropdown
        Rectangle {
          id: addWidgetMenu
          visible: false
          anchors.bottom: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottomMargin: 12
          width: 160
          height: addMenuCol.implicitHeight + 16
          radius: Colors.radiusSmall
          color: Colors.bgGlass
          border.color: Colors.border
          border.width: 1

          Column {
            id: addMenuCol
            anchors.fill: parent
            anchors.margins: Colors.spacingS
            spacing: 2

            Repeater {
              model: DesktopWidgetRegistry.widgetCatalog

              delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: 30
                radius: 6
                color: addItemMa.containsMouse ? Colors.highlight : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: Colors.spacingS

                  Text {
                    text: modelData.icon
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                  }
                  Text {
                    text: modelData.name
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    Layout.fillWidth: true
                  }
                }

                MouseArea {
                  id: addItemMa
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    DesktopWidgetRegistry.addWidget(root.screenName, modelData.id);
                    addWidgetMenu.visible = false;
                  }
                }
              }
            }
          }
        }
      }

      // Separator
      Rectangle { width: 1; height: 24; color: Colors.border }

      // Grid Snap toggle
      Rectangle {
        Layout.preferredWidth: snapRow.implicitWidth + 16
        Layout.preferredHeight: 28
        radius: Colors.radiusMedium
        color: Config.desktopWidgetsGridSnap ? Colors.withAlpha(Colors.primary, 0.2) : "transparent"
        border.color: Config.desktopWidgetsGridSnap ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
          id: snapRow
          anchors.centerIn: parent
          spacing: Colors.spacingXS
          Text { text: "󰕰"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
          Text { text: "Grid"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.desktopWidgetsGridSnap = !Config.desktopWidgetsGridSnap
        }
      }

      // Separator
      Rectangle { width: 1; height: 24; color: Colors.border }

      // Exit Edit Mode
      Rectangle {
        Layout.preferredWidth: exitRow.implicitWidth + 16
        Layout.preferredHeight: 28
        radius: Colors.radiusMedium
        color: Colors.withAlpha(Colors.error, 0.15)
        border.color: Colors.error
        border.width: 1

        RowLayout {
          id: exitRow
          anchors.centerIn: parent
          spacing: Colors.spacingXS
          Text { text: "󰅖"; color: Colors.error; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
          Text { text: "Done"; color: Colors.error; font.pixelSize: Colors.fontSizeSmall }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: DesktopWidgetRegistry.editMode = false
        }
      }
    }
  }

  // Widget component definitions
  Component {
    id: clockComponent
    DesktopClock {}
  }

  Component {
    id: systemStatComponent
    DesktopSystemStat {}
  }

  Component {
    id: weatherComponent
    DesktopWeather {}
  }

  Component {
    id: placeholderComponent
    Rectangle {
      width: 120; height: 60
      radius: Colors.radiusSmall
      color: Colors.withAlpha(Colors.surface, 0.5)
      border.color: Colors.border
      Text {
        anchors.centerIn: parent
        text: "Unknown Widget"
        color: Colors.fgDim
        font.pixelSize: Colors.fontSizeSmall
      }
    }
  }
}

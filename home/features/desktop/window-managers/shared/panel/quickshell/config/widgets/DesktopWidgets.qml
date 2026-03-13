import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Item {
  id: root
  anchors.fill: parent

  property string screenName: parent ? (parent.screen ? parent.screen.name : "") : ""
  readonly property var screenRef: parent && parent.screen ? parent.screen : null
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
  readonly property real safeDragMinX: edgeMargins.left + 8 - x
  readonly property real safeDragMinY: edgeMargins.top + 8 - y
  readonly property real safeSpawnX: Math.max(100, edgeMargins.left + 24 - x)
  readonly property real safeSpawnY: Math.max(100, edgeMargins.top + 24 - y)

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
      minimumX: root.safeDragMinX
      minimumY: root.safeDragMinY
      maximumX: root.parent ? Math.max(root.safeDragMinX, root.parent.width - root.edgeMargins.right - 8 - root.x - width) : x
      maximumY: root.parent ? Math.max(root.safeDragMinY, root.parent.height - root.edgeMargins.bottom - 8 - root.y - height) : y
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
    anchors.bottomMargin: edgeMargins.bottom + 20
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
          property real menuInset: 8
          width: 160
          height: addMenuCol.implicitHeight + 16
          x: {
            var base = (parent.width - width) / 2;
            if (!root) return base;
            var parentPos = parent.mapToItem(root, 0, 0);
            var minX = -parentPos.x + menuInset;
            var maxX = root.width - parentPos.x - width - menuInset;
            return Math.min(Math.max(base, minX), Math.max(minX, maxX));
          }
          y: {
            if (!root) return -height - 12;
            var parentPos = parent.mapToItem(root, 0, 0);
            var above = -height - 12;
            var below = parent.height + 12;
            var minY = -parentPos.y + menuInset;
            var maxY = root.height - parentPos.y - height - menuInset;
            var target = parentPos.y + above >= menuInset ? above : below;
            return Math.min(Math.max(target, minY), Math.max(minY, maxY));
          }
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
                    DesktopWidgetRegistry.addWidgetAt(root.screenName, modelData.id, root.safeSpawnX, root.safeSpawnY);
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

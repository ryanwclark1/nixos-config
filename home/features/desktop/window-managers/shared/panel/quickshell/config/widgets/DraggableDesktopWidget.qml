import QtQuick
import "../services"

Item {
  id: root

  property string widgetId: ""
  property string widgetType: ""
  property string screenName: ""
  property real widgetScale: 1.0
  default property alias content: contentContainer.children

  x: 0
  y: 0
  width: contentContainer.childrenRect.width * widgetScale
  height: contentContainer.childrenRect.height * widgetScale

  // Edit mode decoration
  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: Colors.radiusMedium
    color: "transparent"
    border.color: DesktopWidgetRegistry.editMode ? Colors.primary : "transparent"
    border.width: DesktopWidgetRegistry.editMode ? 2 : 0
    opacity: 0.6
  }

  // Scaled content container
  Item {
    id: contentContainer
    transformOrigin: Item.TopLeft
    scale: root.widgetScale
    width: childrenRect.width
    height: childrenRect.height
  }

  // Drag handle (edit mode only)
  MouseArea {
    id: dragArea
    anchors.fill: parent
    enabled: DesktopWidgetRegistry.editMode
    cursorShape: DesktopWidgetRegistry.editMode ? Qt.SizeAllCursor : Qt.ArrowCursor
    drag.target: root
    drag.minimumX: -root.width * 0.75
    drag.minimumY: -root.height * 0.75

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onReleased: {
      if (drag.active) savePosition();
    }

    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton && DesktopWidgetRegistry.editMode) {
        widgetContextMenu.visible = !widgetContextMenu.visible;
      }
    }
  }

  // Scale handle (bottom-right corner, edit mode only)
  Rectangle {
    visible: DesktopWidgetRegistry.editMode
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: -8
    anchors.bottomMargin: -8
    width: 16; height: 16
    radius: 3
    color: Colors.primary
    opacity: scaleArea.containsMouse ? 1.0 : 0.6

    Text {
      anchors.centerIn: parent
      text: "󰁌"
      color: Colors.background
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXS
    }

    MouseArea {
      id: scaleArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.SizeFDiagCursor

      property real startX: 0
      property real startScale: 1.0

      onPressed: function(mouse) {
        startX = mouse.x + mapToItem(root, 0, 0).x;
        startScale = root.widgetScale;
      }

      onPositionChanged: function(mouse) {
        if (!pressed) return;
        var currentX = mouse.x + mapToItem(root, 0, 0).x;
        var delta = (currentX - startX) / 200;
        root.widgetScale = Math.max(0.5, Math.min(5.0, startScale + delta));
      }

      onReleased: savePosition()
    }
  }

  // Context menu
  Rectangle {
    id: widgetContextMenu
    visible: false
    anchors.top: parent.bottom
    anchors.left: parent.left
    anchors.topMargin: 8
    width: 140; height: menuCol.implicitHeight + 16
    radius: Colors.radiusSmall
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    z: 100

    Column {
      id: menuCol
      anchors.fill: parent
      anchors.margins: 8
      spacing: 2

      ContextMenuItem {
        text: "Reset Size"
        onClicked: {
          root.widgetScale = 1.0;
          savePosition();
          widgetContextMenu.visible = false;
        }
      }

      ContextMenuItem {
        text: "Delete"
        isDestructive: true
        onClicked: {
          DesktopWidgetRegistry.removeWidget(root.screenName, root.widgetId);
          widgetContextMenu.visible = false;
        }
      }
    }
  }

  function savePosition() {
    DesktopWidgetRegistry.updateWidgetData(screenName, widgetId, {
      x: Math.round(root.x),
      y: Math.round(root.y),
      scale: Math.round(root.widgetScale * 100) / 100
    });
  }

  // Grid snap on position change
  onXChanged: {
    if (DesktopWidgetRegistry.editMode && Config.desktopWidgetsGridSnap && dragArea.drag.active) {
      var gridSize = 20;
      x = Math.round(x / gridSize) * gridSize;
    }
  }
  onYChanged: {
    if (DesktopWidgetRegistry.editMode && Config.desktopWidgetsGridSnap && dragArea.drag.active) {
      var gridSize = 20;
      y = Math.round(y / gridSize) * gridSize;
    }
  }

  component ContextMenuItem: Item {
    property string text: ""
    property bool isDestructive: false
    signal clicked()
    width: parent.width
    height: 28

    Rectangle {
      anchors.fill: parent
      radius: 6
      color: itemMa.containsMouse ? Colors.highlight : "transparent"

      Text {
        anchors.centerIn: parent
        text: parent.parent.text
        color: parent.parent.isDestructive ? Colors.error : Colors.text
        font.pixelSize: Colors.fontSizeSmall
      }

      MouseArea {
        id: itemMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.parent.clicked()
      }
    }
  }
}

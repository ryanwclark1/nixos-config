import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PopupWindow {
  id: root

  property var anchorWindow: null
  anchor.window: anchorWindow
  property Item anchorItem: null
  property string preferredEdge: ""
  property var dockRoot: null
  property var appData: null
  property int appIndex: -1
  readonly property string anchorEdge: {
    if (preferredEdge !== "") return preferredEdge;
    if (anchorWindow && anchorWindow.tooltipEdge !== undefined && anchorWindow.tooltipEdge !== "")
      return String(anchorWindow.tooltipEdge);
    return "bottom";
  }

  visible: false
  implicitWidth: 200
  implicitHeight: menuColumn.implicitHeight + 16
  color: "transparent"

  readonly property string appId: appData ? (appData.appId || "") : ""
  readonly property var toplevels: appData ? (appData.toplevels || []) : []
  readonly property bool isRunning: toplevels.length > 0
  readonly property bool isPinned: appData ? (appData.pinned || false) : false
  readonly property bool isGrouped: toplevels.length > 1
  property bool showWorkspaceList: false
  readonly property var desktopActions: dockRoot ? dockRoot.getAppActions(appId) : []
  readonly property real inset: 8

  function _windowX(item) {
    var x = 0;
    for (var it = item; it; it = it.parent) x += it.x;
    return x;
  }

  function _windowY(item) {
    var y = 0;
    for (var it = item; it; it = it.parent) y += it.y;
    return y;
  }

  anchor.rect.x: {
    if (!anchorItem) return 0;
    var x = 0;
    if (anchorEdge === "left")
      x = _windowX(anchorItem) + anchorItem.width + 8;
    else if (anchorEdge === "right")
      x = _windowX(anchorItem) - implicitWidth - 8;
    else
      x = _windowX(anchorItem) + (anchorItem.width - implicitWidth) / 2;
    if (anchorWindow && anchorWindow.width !== undefined) {
      var maxX = Math.max(inset, anchorWindow.width - implicitWidth - inset);
      x = Math.min(Math.max(inset, x), maxX);
    }
    return x;
  }

  anchor.rect.y: {
    if (!anchorItem) return 0;
    var y = 0;
    if (anchorEdge === "top")
      y = _windowY(anchorItem) + anchorItem.height + 8;
    else if (anchorEdge === "bottom")
      y = _windowY(anchorItem) - implicitHeight - 8;
    else
      y = _windowY(anchorItem) + (anchorItem.height - implicitHeight) / 2;
    if (anchorWindow && anchorWindow.height !== undefined) {
      var maxY = Math.max(inset, anchorWindow.height - implicitHeight - inset);
      y = Math.min(Math.max(inset, y), maxY);
    }
    return y;
  }

  function open() {
    visible = true;
  }

  function close() {
    visible = false;
    showWorkspaceList = false;
    appData = null;
    anchorItem = null;
  }

  // Close on click outside
  MouseArea {
    anchors.fill: parent
    onPressed: function(mouse) { mouse.accepted = false; }
  }

  Rectangle {
    id: menuBg
    anchors.fill: parent
    anchors.margins: Colors.spacingXS
    radius: 12
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      id: menuColumn
      anchors.fill: parent
      anchors.margins: Colors.spacingS
      spacing: 2

      // Grouped windows list
      Repeater {
        model: root.isGrouped && !root.showWorkspaceList ? root.toplevels : []

        delegate: MenuItem {
          text: modelData.title || "Window"
          icon: ""
          onClicked: {
            modelData.activate();
            root.close();
          }
        }
      }

      // Separator after window list
      Rectangle {
        visible: root.isGrouped && !root.showWorkspaceList
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: Colors.border
      }

      // Desktop entry actions (e.g. "New Private Window")
      Repeater {
        model: !root.showWorkspaceList ? root.desktopActions : []
        delegate: MenuItem {
          text: modelData.name
          icon: "󰐕"
          onClicked: {
            try { modelData.action.execute(); } catch (e) {
              Quickshell.execDetached(["gtk-launch", root.appId]);
            }
            root.close();
          }
        }
      }

      Rectangle {
        visible: root.desktopActions.length > 0 && !root.showWorkspaceList
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: Colors.border
      }

      // Focus (single window)
      MenuItem {
        visible: root.isRunning && !root.isGrouped && !root.showWorkspaceList
        text: "Focus"
        icon: "󰖲"
        onClicked: {
          if (root.toplevels.length > 0) root.toplevels[0].activate();
          root.close();
        }
      }

      // Pin / Unpin
      MenuItem {
        visible: !root.showWorkspaceList
        text: root.isPinned ? "Unpin" : "Pin to Dock"
        icon: root.isPinned ? "󰤱" : "󰤰"
        onClicked: {
          if (root.dockRoot) root.dockRoot.togglePin(root.appId);
          root.close();
        }
      }

      // Launch new instance
      MenuItem {
        visible: !root.showWorkspaceList
        text: "New Instance"
        icon: "󰐕"
        onClicked: {
          Quickshell.execDetached(["gtk-launch", root.appId]);
          root.close();
        }
      }

      // Move to Workspace
      MenuItem {
        visible: root.isRunning && !root.showWorkspaceList && CompositorAdapter.isHyprland
        text: "Move to Workspace  ›"
        icon: "󰍹"
        onClicked: root.showWorkspaceList = true
      }

      // Workspace picker (inline submenu)
      MenuItem {
        visible: root.showWorkspaceList
        text: "‹ Back"
        icon: "󰁍"
        onClicked: root.showWorkspaceList = false
      }

      Repeater {
        model: root.showWorkspaceList && CompositorAdapter.isHyprland ? 10 : 0
        delegate: MenuItem {
          required property int index
          text: "Workspace " + (index + 1)
          icon: ""
          onClicked: {
            for (var i = 0; i < root.toplevels.length; i++) {
              Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace",
                (index + 1) + ",address:" + root.toplevels[i].address]);
            }
            root.showWorkspaceList = false;
            root.close();
          }
        }
      }

      // Separator
      Rectangle {
        visible: root.isRunning && !root.showWorkspaceList
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: Colors.border
      }

      // Close / Close All
      MenuItem {
        visible: root.isRunning && !root.showWorkspaceList
        text: root.isGrouped ? "Close All (" + root.toplevels.length + ")" : "Close"
        icon: "󰅖"
        isDestructive: true
        onClicked: {
          for (var i = 0; i < root.toplevels.length; i++) {
            root.toplevels[i].close();
          }
          root.close();
        }
      }
    }
  }

  // Reusable menu item
  component MenuItem: Item {
    id: menuItem
    property string text: ""
    property string icon: ""
    property bool isDestructive: false

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    visible: true

    Rectangle {
      anchors.fill: parent
      radius: Colors.radiusXS
      color: "transparent"

      StateLayer {
        id: itemStateLayer
        hovered: itemMouse.containsMouse
        pressed: itemMouse.pressed
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.paddingSmall
        anchors.rightMargin: Colors.paddingSmall
        spacing: Colors.spacingS

        Text {
          text: menuItem.icon
          color: menuItem.isDestructive ? Colors.error : Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeMedium
        }

        Text {
          Layout.fillWidth: true
          text: menuItem.text
          color: menuItem.isDestructive ? Colors.error : Colors.text
          font.pixelSize: Colors.fontSizeMedium
          elide: Text.ElideRight
        }
      }

      MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          itemStateLayer.burst(mouse.x, mouse.y);
          menuItem.clicked();
        }
      }
    }
  }
}

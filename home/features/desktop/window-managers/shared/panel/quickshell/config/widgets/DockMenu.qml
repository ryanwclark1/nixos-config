import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PopupWindow {
  id: root

  property var anchorWindow: null
  anchor.window: anchorWindow
  property var dockRoot: null
  property var appData: null
  property int appIndex: -1

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

  function open() {
    visible = true;
  }

  function close() {
    visible = false;
    showWorkspaceList = false;
    appData = null;
  }

  // Close on click outside
  MouseArea {
    anchors.fill: parent
    onPressed: function(mouse) { mouse.accepted = false; }
  }

  Rectangle {
    id: menuBg
    anchors.fill: parent
    anchors.margins: 4
    radius: 12
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      id: menuColumn
      anchors.fill: parent
      anchors.margins: 8
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
        visible: root.isRunning && !root.showWorkspaceList
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
        model: root.showWorkspaceList ? 10 : 0
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
      radius: 8
      color: itemMouse.containsMouse ? Colors.highlight : "transparent"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
          text: menuItem.icon
          color: menuItem.isDestructive ? Colors.error : Colors.fgMain
          font.family: Colors.fontMono
          font.pixelSize: 14
        }

        Text {
          Layout.fillWidth: true
          text: menuItem.text
          color: menuItem.isDestructive ? Colors.error : Colors.text
          font.pixelSize: 13
          elide: Text.ElideRight
        }
      }

      MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menuItem.clicked()
      }
    }
  }
}

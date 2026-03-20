import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared"

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

  anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY

  function _updateRect() {
    if (!anchorItem || !anchorWindow) return;
    var r = anchorWindow.itemRect(anchorItem);
    var gap = Config.popupGap;
    var pw = root.implicitWidth;
    var ph = root.implicitHeight;
    var edge = anchorEdge;

    if (edge === "left" || edge === "right") {
      anchor.rect.y = r.y + r.height / 2 - ph / 2;
      anchor.rect.x = edge === "left" ? r.x + r.width + gap : r.x - pw - gap;
    } else {
      anchor.rect.x = r.x + r.width / 2 - pw / 2;
      anchor.rect.y = edge === "bottom" ? r.y - ph - gap : r.y + r.height + gap;
    }
  }

  onAnchorItemChanged: _updateRect()
  onAnchorEdgeChanged: _updateRect()
  onImplicitWidthChanged: _updateRect()
  onImplicitHeightChanged: _updateRect()
  onVisibleChanged: {
    if (visible) {
      _updateRect();
    } else {
      FocusGrabManager.releaseGrab("dockMenu");
    }
  }

  visible: false
  implicitWidth: 200
  implicitHeight: Math.max(1, menuColumn.implicitHeight + 16)
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
    FocusGrabManager.requestGrab("dockMenu", function() { root.close(); });
    menuBg.forceActiveFocus();
  }

  function close() {
    FocusGrabManager.releaseGrab("dockMenu");
    visible = false;
    showWorkspaceList = false;
    appData = null;
    anchorItem = null;
  }

  Rectangle {
    id: menuBg
    anchors.fill: parent
    anchors.margins: Appearance.spacingXS
    radius: Appearance.radiusCard
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    focus: root.visible

    onActiveFocusChanged: {
      if (!activeFocus && root.visible)
        root.close();
    }
    Keys.onEscapePressed: root.close()

    ColumnLayout {
      id: menuColumn
      anchors.fill: parent
      anchors.margins: Appearance.spacingS
      spacing: Appearance.spacingXXS

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
        Layout.topMargin: Appearance.spacingXS
        Layout.bottomMargin: Appearance.spacingXS
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
        Layout.topMargin: Appearance.spacingXS
        Layout.bottomMargin: Appearance.spacingXS
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
        visible: root.isRunning && !root.showWorkspaceList && CompositorAdapter.supportsWorkspaceMove
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
        model: root.showWorkspaceList && CompositorAdapter.supportsWorkspaceMove ? 10 : 0
        delegate: MenuItem {
          required property int index
          text: "Workspace " + (index + 1)
          icon: ""
          onClicked: {
            for (var i = 0; i < root.toplevels.length; i++) {
              CompositorAdapter.moveWindowToWorkspace(root.toplevels[i].address, index + 1);
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
        Layout.topMargin: Appearance.spacingXS
        Layout.bottomMargin: Appearance.spacingXS
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

    Rectangle {
      anchors.fill: parent
      radius: Appearance.radiusXS
      color: "transparent"

      StateLayer {
        id: itemStateLayer
        hovered: itemMouse.containsMouse
        pressed: itemMouse.pressed
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.paddingSmall
        anchors.rightMargin: Appearance.paddingSmall
        spacing: Appearance.spacingS

        Text {
          text: menuItem.icon
          color: menuItem.isDestructive ? Colors.error : Colors.text
          font.family: Appearance.fontMono
          font.pixelSize: Appearance.fontSizeMedium
        }

        Text {
          Layout.fillWidth: true
          text: menuItem.text
          color: menuItem.isDestructive ? Colors.error : Colors.text
          font.pixelSize: Appearance.fontSizeMedium
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

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

Item {
  id: root

  property var dockApps: []
  property var dockRoot: null
  property var anchorWindow: null
  property int dragSourceIndex: -1
  property int dragTargetIndex: -1
  readonly property alias background: dockBg

  implicitWidth: dockBg.width
  implicitHeight: dockBg.height

  function reorderApps(fromIdx, toIdx) {
    if (fromIdx === toIdx) return;
    var app = dockApps[fromIdx];
    if (!app || !app.pinned) return;

    // Reorder within pinned apps
    var pinned = Config.dockPinnedApps.slice();
    var normFrom = dockRoot.normalizeAppId(app.appId);
    var srcPinIdx = -1;
    for (var i = 0; i < pinned.length; i++) {
      if (dockRoot.normalizeAppId(pinned[i]) === normFrom) { srcPinIdx = i; break; }
    }
    if (srcPinIdx < 0) return;

    // Find target pinned index
    var targetApp = dockApps[toIdx];
    if (!targetApp || !targetApp.pinned) return;
    var normTo = dockRoot.normalizeAppId(targetApp.appId);
    var dstPinIdx = -1;
    for (var j = 0; j < pinned.length; j++) {
      if (dockRoot.normalizeAppId(pinned[j]) === normTo) { dstPinIdx = j; break; }
    }
    if (dstPinIdx < 0) return;

    var item = pinned.splice(srcPinIdx, 1)[0];
    pinned.splice(dstPinIdx, 0, item);
    Config.dockPinnedApps = pinned;
  }

  Rectangle {
    id: dockBg
    anchors.centerIn: parent
    width: row.implicitWidth + 40
    height: 56
    color: Colors.bgGlass
    radius: 18
    border.color: Colors.border
    border.width: 1
  }

  Row {
    id: row
    anchors.centerIn: dockBg
    spacing: Colors.spacingS

    Repeater {
      model: root.dockApps

      delegate: Item {
        id: appDelegate
        width: Config.dockIconSize + 8
        height: Config.dockIconSize + 16

        required property var modelData
        required property int index

        readonly property string appId: modelData.appId || ""
        readonly property var toplevels: modelData.toplevels || []
        readonly property bool isRunning: toplevels.length > 0
        readonly property bool isPinned: modelData.pinned || false
        readonly property bool isGrouped: toplevels.length > 1
        readonly property string appName: modelData.name || appId
        readonly property string iconSource: root.dockRoot ? root.dockRoot.getAppIcon(appId) : ""
        readonly property bool isFocused: {
          if (!isRunning || typeof ToplevelManager === 'undefined') return false;
          var active = ToplevelManager.activeToplevel;
          if (!active) return false;
          for (var i = 0; i < toplevels.length; i++) {
            if (toplevels[i] === active) return true;
          }
          return false;
        }

        // Bounce animation on new window
        property int prevToplevelCount: 0

        SequentialAnimation {
          id: bounceAnim
          NumberAnimation { target: iconContainer; property: "y"; to: 0; duration: 100; easing.type: Easing.OutQuad }
          NumberAnimation { target: iconContainer; property: "y"; to: 4; duration: 200; easing.type: Easing.OutBounce }
        }

        onToplevelsChanged: {
          if (toplevels.length > prevToplevelCount && prevToplevelCount > 0) bounceAnim.start();
          prevToplevelCount = toplevels.length;
        }
        Component.onCompleted: prevToplevelCount = toplevels.length

        // Drag-and-drop
        DropArea {
          anchors.fill: parent
          keys: ["dock-app"]
          onEntered: function(drag) {
            root.dragTargetIndex = appDelegate.index;
          }
          onExited: {
            if (root.dragTargetIndex === appDelegate.index)
              root.dragTargetIndex = -1;
          }
          onDropped: function(drop) {
            if (drop.source && drop.source !== iconContainer)
              root.reorderApps(root.dragSourceIndex, appDelegate.index);
            root.dragSourceIndex = -1;
            root.dragTargetIndex = -1;
          }
        }

        Item {
          id: iconContainer
          anchors.horizontalCenter: parent.horizontalCenter
          y: 4
          width: Config.dockIconSize
          height: Config.dockIconSize

          property bool dragging: mouseArea.drag.active

          Drag.active: dragging
          Drag.source: iconContainer
          Drag.hotSpot.x: width / 2
          Drag.hotSpot.y: height / 2
          Drag.keys: ["dock-app"]

          onDraggingChanged: {
            if (dragging) root.dragSourceIndex = appDelegate.index;
            else root.dragSourceIndex = -1;
          }

          // Visual shift during drag
          property real shiftX: {
            if (root.dragSourceIndex < 0 || root.dragTargetIndex < 0 || dragging) return 0;
            var src = root.dragSourceIndex;
            var tgt = root.dragTargetIndex;
            if (src < tgt && appDelegate.index > src && appDelegate.index <= tgt)
              return -(Config.dockIconSize + 8);
            if (src > tgt && appDelegate.index >= tgt && appDelegate.index < src)
              return (Config.dockIconSize + 8);
            return 0;
          }

          transform: Translate {
            x: iconContainer.shiftX
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          }

          Rectangle {
            anchors.fill: parent
            radius: Colors.radiusSmall
            color: "transparent"
            scale: mouseArea.containsMouse ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

            StateLayer {
              hovered: mouseArea.containsMouse
              pressed: mouseArea.pressed
            }

            // Prefer image icon from desktop entry; fallback to Nerd Font
            Loader {
              anchors.centerIn: parent
              active: appDelegate.iconSource !== ""
              sourceComponent: Image {
                width: Config.dockIconSize - 8
                height: Config.dockIconSize - 8
                source: appDelegate.iconSource
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectFit
                smooth: true
              }
            }

            // Fallback: first letter
            Text {
              anchors.centerIn: parent
              visible: appDelegate.iconSource === ""
              text: appDelegate.appName.charAt(0).toUpperCase()
              color: Colors.text
              font.pixelSize: Config.dockIconSize * 0.5
              font.weight: Font.Bold
              font.family: Colors.fontMono
            }
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            drag.target: appDelegate.isPinned ? iconContainer : undefined
            drag.axis: Drag.XAxis

            onClicked: function(mouse) {
              if (mouse.button === Qt.RightButton) {
                contextMenu.appData = appDelegate.modelData;
                contextMenu.appIndex = appDelegate.index;
                contextMenu.open();
                return;
              }

              if (mouse.button === Qt.MiddleButton) {
                // Close focused window (or first window) of this app
                if (appDelegate.isRunning) {
                  if (appDelegate.isGrouped) {
                    var active = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
                    var closed = false;
                    for (var i = 0; i < appDelegate.toplevels.length; i++) {
                      if (appDelegate.toplevels[i] === active) {
                        appDelegate.toplevels[i].close(); closed = true; break;
                      }
                    }
                    if (!closed && appDelegate.toplevels.length > 0) appDelegate.toplevels[0].close();
                  } else {
                    if (appDelegate.toplevels.length > 0) appDelegate.toplevels[0].close();
                  }
                }
                return;
              }

              // Left click: focus or launch
              if (appDelegate.isRunning) {
                if (appDelegate.isGrouped) {
                  // Cycle through grouped windows
                  var active = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
                  var idx = -1;
                  for (var i = 0; i < appDelegate.toplevels.length; i++) {
                    if (appDelegate.toplevels[i] === active) { idx = i; break; }
                  }
                  var next = (idx + 1) % appDelegate.toplevels.length;
                  appDelegate.toplevels[next].activate();
                } else {
                  if (appDelegate.toplevels.length > 0) appDelegate.toplevels[0].activate();
                }
              } else {
                Quickshell.execDetached(["gtk-launch", appDelegate.appId]);
              }
            }

            onWheel: function(wheel) {
              if (!appDelegate.isGrouped) return;
              var active = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
              var idx = -1;
              for (var i = 0; i < appDelegate.toplevels.length; i++) {
                if (appDelegate.toplevels[i] === active) { idx = i; break; }
              }
              var count = appDelegate.toplevels.length;
              var next = wheel.angleDelta.y > 0
                ? (idx + 1) % count
                : (idx - 1 + count) % count;
              appDelegate.toplevels[next].activate();
            }

            onReleased: {
              if (iconContainer.Drag.active) iconContainer.Drag.drop();
            }
          }
        }

        // Running indicator dots (up to 3, one per window)
        Row {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottomMargin: 1
          spacing: 3
          visible: appDelegate.isRunning

          Repeater {
            model: Math.min(appDelegate.toplevels.length, 3)
            Rectangle {
              required property int index
              width: 4; height: 4; radius: 2
              color: {
                if (!appDelegate.isFocused) return Colors.fgSecondary;
                var active = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
                if (active && index < appDelegate.toplevels.length && appDelegate.toplevels[index] === active)
                  return Colors.primary;
                return Colors.fgSecondary;
              }
              Behavior on color { ColorAnimation { duration: 160 } }
            }
          }
        }

        // Group count badge
        Rectangle {
          visible: appDelegate.isGrouped
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.topMargin: 2
          anchors.rightMargin: 2
          width: 14; height: 14; radius: 7
          color: Colors.primary

          Text {
            anchors.centerIn: parent
            text: appDelegate.toplevels.length
            color: Colors.background
            font.pixelSize: 8
            font.weight: Font.Bold
          }
        }

        // Tooltip
        BarTooltip {
          text: appDelegate.isGrouped
            ? appDelegate.appName + " (" + appDelegate.toplevels.length + " windows)"
            : (appDelegate.isRunning && appDelegate.toplevels.length > 0 && appDelegate.toplevels[0].title
               ? appDelegate.toplevels[0].title
               : appDelegate.appName)
          anchorItem: appDelegate
          anchorWindow: root.anchorWindow
          hovered: mouseArea.containsMouse && !iconContainer.dragging && !contextMenu.visible
        }
      }
    }
  }

  // Shared context menu
  DockMenu {
    id: contextMenu
    anchorWindow: root.anchorWindow
    dockRoot: root.dockRoot
  }
}

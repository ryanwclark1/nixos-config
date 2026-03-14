import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

Item {
  id: root

  property var dockApps: []
  property var dockRoot: null
  property var anchorWindow: null
  property bool vertical: Config.dockPosition === "left" || Config.dockPosition === "right"
  property int dragSourceIndex: -1
  property int dragTargetIndex: -1
  readonly property alias background: dockBg
  readonly property int iconSlotMain: Config.dockIconSize + 8
  readonly property int iconSlotCross: Config.dockIconSize + 16

  implicitWidth: dockBg.width
  implicitHeight: dockBg.height

  function reorderApps(fromIdx, toIdx) {
    if (fromIdx === toIdx) return;
    var app = dockApps[fromIdx];
    if (!app || !app.pinned) return;

    var pinned = Config.dockPinnedApps.slice();
    var normFrom = dockRoot.normalizeAppId(app.appId);
    var srcPinIdx = -1;
    for (var i = 0; i < pinned.length; i++) {
      if (dockRoot.normalizeAppId(pinned[i]) === normFrom) { srcPinIdx = i; break; }
    }
    if (srcPinIdx < 0) return;

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
    width: root.vertical ? 56 : ((dockLayoutLoader.item ? dockLayoutLoader.item.implicitWidth : 0) + 40)
    height: root.vertical ? ((dockLayoutLoader.item ? dockLayoutLoader.item.implicitHeight : 0) + 40) : 56
    color: Colors.bgGlass
    radius: 18
    border.color: Colors.border
    border.width: 1
  }

  Loader {
    id: dockLayoutLoader
    anchors.centerIn: dockBg
    sourceComponent: root.vertical ? verticalDockLayout : horizontalDockLayout
  }

  Component {
    id: horizontalDockLayout
    Row {
      id: dockLayout
      spacing: Colors.spacingS

      Repeater {
        model: root.dockApps
        delegate: dockItemDelegate
      }
    }
  }

  Component {
    id: verticalDockLayout
    Column {
      id: dockLayout
      spacing: Colors.spacingS

      Repeater {
        model: root.dockApps
        delegate: dockItemDelegate
      }
    }
  }

  Component {
    id: dockItemDelegate
    Item {
      id: appDelegate
      width: root.vertical ? root.iconSlotCross : root.iconSlotMain
      height: root.vertical ? root.iconSlotMain : root.iconSlotCross

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

      property int prevToplevelCount: 0

      SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: iconContainer; property: root.vertical ? "x" : "y"; to: 0; duration: Colors.durationSnap; easing.type: Easing.OutQuad }
        NumberAnimation { target: iconContainer; property: root.vertical ? "x" : "y"; to: 4; duration: Colors.durationNormal; easing.type: Easing.OutBounce }
      }

      onToplevelsChanged: {
        if (toplevels.length > prevToplevelCount && prevToplevelCount > 0) bounceAnim.start();
        prevToplevelCount = toplevels.length;
      }
      Component.onCompleted: prevToplevelCount = toplevels.length

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
        anchors.verticalCenter: parent.verticalCenter
        x: root.vertical ? 4 : 0
        y: root.vertical ? 0 : 4
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

        property real shiftMain: {
          if (root.dragSourceIndex < 0 || root.dragTargetIndex < 0 || dragging) return 0;
          var src = root.dragSourceIndex;
          var tgt = root.dragTargetIndex;
          var step = Config.dockIconSize + 8;
          if (src < tgt && appDelegate.index > src && appDelegate.index <= tgt)
            return -step;
          if (src > tgt && appDelegate.index >= tgt && appDelegate.index < src)
            return step;
          return 0;
        }

        transform: Translate {
          x: root.vertical ? 0 : iconContainer.shiftMain
          y: root.vertical ? iconContainer.shiftMain : 0
          Behavior on x { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
          Behavior on y { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
        }

        Rectangle {
          anchors.fill: parent
          radius: Colors.radiusSmall
          color: "transparent"
          scale: mouseArea.containsMouse ? 1.15 : 1.0
          Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack } }

          StateLayer {
            hovered: mouseArea.containsMouse
            pressed: mouseArea.pressed
          }

          AppIcon {
            anchors.centerIn: parent
            iconName: appDelegate.iconSource
            appName: appDelegate.appName || ""
            iconSize: Config.dockIconSize - 8
            fallbackIcon: "󰀻"
          }
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          drag.target: appDelegate.isPinned ? iconContainer : undefined
          drag.axis: root.vertical ? Drag.YAxis : Drag.XAxis

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              contextMenu.appData = appDelegate.modelData;
              contextMenu.appIndex = appDelegate.index;
              contextMenu.anchorItem = appDelegate;
              contextMenu.open();
              return;
            }

            if (mouse.button === Qt.MiddleButton) {
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
                } else if (appDelegate.toplevels.length > 0) {
                  appDelegate.toplevels[0].close();
                }
              }
              return;
            }

            if (appDelegate.isRunning) {
              if (appDelegate.isGrouped) {
                var activeTop = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
                var idx = -1;
                for (var j = 0; j < appDelegate.toplevels.length; j++) {
                  if (appDelegate.toplevels[j] === activeTop) { idx = j; break; }
                }
                var next = (idx + 1) % appDelegate.toplevels.length;
                appDelegate.toplevels[next].activate();
              } else if (appDelegate.toplevels.length > 0) {
                appDelegate.toplevels[0].activate();
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
            var delta = root.vertical ? wheel.angleDelta.x : wheel.angleDelta.y;
            var next = delta > 0 ? (idx + 1) % count : (idx - 1 + count) % count;
            appDelegate.toplevels[next].activate();
          }

          onReleased: {
            if (iconContainer.Drag.active) iconContainer.Drag.drop();
          }
        }
      }

      Loader {
        active: appDelegate.isRunning
        anchors.bottom: root.vertical ? undefined : parent.bottom
        anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
        anchors.right: root.vertical ? parent.right : undefined
        anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
        anchors.bottomMargin: root.vertical ? 0 : 1
        anchors.rightMargin: root.vertical ? 1 : 0
        sourceComponent: root.vertical ? verticalIndicators : horizontalIndicators
      }

      Component {
        id: horizontalIndicators
        Row {
          spacing: 3
          Repeater {
            model: Math.min(appDelegate.toplevels.length, 3)
            Rectangle {
              required property int index
              width: 4; height: 4; radius: Colors.radiusMicro
              color: {
                if (!appDelegate.isFocused) return Colors.fgSecondary;
                var active = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
                if (active && index < appDelegate.toplevels.length && appDelegate.toplevels[index] === active)
                  return Colors.primary;
                return Colors.fgSecondary;
              }
              Behavior on color { ColorAnimation { duration: Colors.durationFast } }
            }
          }
        }
      }

      Component {
        id: verticalIndicators
        Column {
          spacing: 3
          Repeater {
            model: Math.min(appDelegate.toplevels.length, 3)
            Rectangle {
              required property int index
              width: 4; height: 4; radius: Colors.radiusMicro
              color: {
                if (!appDelegate.isFocused) return Colors.fgSecondary;
                var active = (typeof ToplevelManager !== 'undefined') ? ToplevelManager.activeToplevel : null;
                if (active && index < appDelegate.toplevels.length && appDelegate.toplevels[index] === active)
                  return Colors.primary;
                return Colors.fgSecondary;
              }
              Behavior on color { ColorAnimation { duration: Colors.durationFast } }
            }
          }
        }
      }

      Rectangle {
        visible: appDelegate.isGrouped
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        width: 14; height: 14; radius: width / 2
        color: Colors.primary

        Text {
          anchors.centerIn: parent
          text: appDelegate.toplevels.length
          color: Colors.background
          font.pixelSize: Colors.fontSizeXXS
          font.weight: Font.Bold
        }
      }

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

  DockMenu {
    id: contextMenu
    anchorWindow: root.anchorWindow
    dockRoot: root.dockRoot
  }
}

import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
  id: taskItem
  width: buttonSize; height: buttonSize; radius: Colors.radiusXS
  color: actualFocused ? Colors.highlight : "transparent"
  border.color: actualFocused ? Colors.primary : "transparent"; border.width: 1
  clip: true
  scale: mouseArea.containsMouse ? 1.06 : 1.0
  layer.enabled: mouseArea.containsMouse

  property string appId: ""
  property string appExec: ""
  property string appName: ""
  property bool isFocused: false
  property bool isPinned: false
  property var anchorWindow: null
  property var iconMap: ({})
  property var toplevelRef: null
  property int buttonSize: 32
  property int iconSize: 20
  property bool showRunningIndicator: true
  
  signal pinToggled(var app)

  readonly property bool isRunning: toplevelRef !== null
  readonly property bool niriFocused: {
    if (!CompositorAdapter.isNiri || !NiriService.available) return false;
    var aw = CompositorAdapter.niriActiveWindow;
    if (!aw) return false;
    return CompositorAdapter.windowAppId(aw).toLowerCase() === appId.toLowerCase();
  }
  readonly property bool actualFocused: niriFocused || isFocused
  readonly property string tooltipText: {
    if ((appName || "").trim().length > 0) return appName;
    if ((appId || "").trim().length > 0) return appId;
    if ((appExec || "").trim().length > 0) return appExec;
    return isPinned ? "Pinned app" : "Running app";
  }

  Behavior on color { ColorAnimation { duration: Colors.durationFast } }
  Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

  // Running indicator dot
  Rectangle {
    width: 4; height: 4; radius: Colors.radiusMicro; color: taskItem.actualFocused ? Colors.primary : Colors.textDisabled
    anchors.bottom: parent.bottom; anchors.bottomMargin: 2; anchors.horizontalCenter: parent.horizontalCenter
    visible: showRunningIndicator && isRunning
  }

  SharedWidgets.AppIcon {
    anchors.centerIn: parent
    iconName: taskItem.appId || taskItem.appExec || ""
    appName: taskItem.appName || taskItem.appId || ""
    iconSize: taskItem.iconSize
    iconMap: taskItem.iconMap
    fallbackIcon: "󰀻"
  }

  SharedWidgets.StateLayer {
    id: stateLayer
    hovered: mouseArea.containsMouse
    pressed: mouseArea.pressed
    stateColor: Colors.primary
  }

  MouseArea {
    id: mouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton

    drag.target: isPinned ? null : taskItem
    drag.axis: Drag.XAndYAxis

    onClicked: (mouse) => {
      stateLayer.burst(mouse.x, mouse.y);
      if (mouse.button === Qt.LeftButton) {
        if (isRunning) {
          // On Niri, prefer NiriService.focusWindow for instant IPC focus
          if (CompositorAdapter.isNiri && NiriService.available) {
            var niriWin = NiriService.findWindowByAppId(appId);
            if (niriWin) { CompositorAdapter.focusWindow(niriWin.id); return; }
          }
          if (toplevelRef && toplevelRef.activate) toplevelRef.activate();
        } else if (isPinned && appExec) {
          Quickshell.execDetached(["sh", "-c", appExec]);
        }
      } else if (mouse.button === Qt.RightButton) {
        taskItem.pinToggled({ appId: appId, title: appName, exec: appExec });
      }
    }
  }

  Drag.active: mouseArea.drag.active
  Drag.source: {
    if (isPinned) return null;
    var winId = toplevelRef ? (toplevelRef.id || toplevelRef.address || "") : "";
    return ({ type: "window", windowId: winId, windowAddress: winId, appId: appId });
  }
  Drag.hotSpot.x: width / 2
  Drag.hotSpot.y: height / 2

  states: [
    State {
      when: mouseArea.drag.active
      ParentChange { target: taskItem; parent: anchorWindow.contentItem }
      PropertyChanges { target: taskItem; opacity: 0.8; scale: 0.8 }
    }
  ]

  SharedWidgets.BarTooltip {
    anchorItem: taskItem
    anchorWindow: taskItem.anchorWindow
    hovered: mouseArea.containsMouse
    text: taskItem.tooltipText
  }
}

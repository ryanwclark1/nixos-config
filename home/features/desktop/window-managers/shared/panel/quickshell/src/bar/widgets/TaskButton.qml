import QtQuick
import Quickshell
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

Rectangle {
  id: taskItem
  width: buttonSize; height: buttonSize; radius: Appearance.radiusXS
  color: actualFocused ? Colors.highlight : (taskItem.activeFocus ? Colors.primarySubtle : "transparent")
  border.color: taskItem.activeFocus ? Colors.primary : (actualFocused ? Colors.primary : "transparent"); border.width: 1
  clip: true
  scale: (mouseArea.containsMouse || taskItem.activeFocus) ? 1.06 : 1.0
  layer.enabled: mouseArea.containsMouse || taskItem.activeFocus

  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: taskItem.tooltipText
  Accessible.onPressAction: taskItem._handleTrigger()

  function _handleTrigger() {
    if (isRunning) {
      if (CompositorAdapter.isNiri && NiriService.available) {
        var niriWin = NiriService.findWindowByAppId(appId);
        if (niriWin) { CompositorAdapter.focusWindow(niriWin.id); return; }
      }
      if (toplevelRef && toplevelRef.activate) toplevelRef.activate();
    } else if (isPinned && appExec) {
      Quickshell.execDetached(["sh", "-c", appExec]);
    }
  }

  function _handlePinToggle() {
    taskItem.pinToggled({ appId: appId, title: appName, exec: appExec });
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
      stateLayer.burst(width / 2, height / 2);
      taskItem._handleTrigger();
      event.accepted = true;
    } else if (event.key === Qt.Key_Menu) {
      taskItem._handlePinToggle();
      event.accepted = true;
    }
  }

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
  property real iconScale: 1.0
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

  Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
  Behavior on scale { Anim { duration: Appearance.durationFast } }

  // Running indicator dot
  Rectangle {
    width: 4 * taskItem.iconScale; height: 4 * taskItem.iconScale; radius: Appearance.radiusMicro * taskItem.iconScale; color: taskItem.actualFocused ? Colors.primary : Colors.textDisabled
    anchors.bottom: parent.bottom; anchors.bottomMargin: 2 * taskItem.iconScale; anchors.horizontalCenter: parent.horizontalCenter
    visible: showRunningIndicator && isRunning
  }

  SharedWidgets.AppIcon {
    anchors.centerIn: parent
    iconName: taskItem.appId || taskItem.appExec || ""
    appName: taskItem.appName || taskItem.appId || ""
    iconSize: taskItem.iconSize
    iconMap: taskItem.iconMap
    fallbackIcon: "apps.svg"
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
      taskItem.forceActiveFocus();
      stateLayer.burst(mouse.x, mouse.y);
      if (mouse.button === Qt.LeftButton) {
        taskItem._handleTrigger();
      } else if (mouse.button === Qt.RightButton) {
        taskItem._handlePinToggle();
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
    hoverPoint: Qt.point(mouseArea.mouseX, mouseArea.mouseY)
    text: taskItem.tooltipText
  }
}

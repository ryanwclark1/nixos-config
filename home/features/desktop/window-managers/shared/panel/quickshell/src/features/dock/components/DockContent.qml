import QtQuick
import ".."
import "../../../services"
import "../../../widgets"

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
    color: Colors.cardSurface
    radius: Colors.radiusLarge
    border.color: Colors.border
    border.width: 1

    gradient: Gradient {
      orientation: root.vertical ? Gradient.Horizontal : Gradient.Vertical
      GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
      GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
    }

    // Inner highlight
    InnerHighlight { highlightOpacity: 0.15 }
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
        delegate: DockItem {
          dockRoot: root.dockRoot
          vertical: root.vertical
          iconSlotMain: root.iconSlotMain
          iconSlotCross: root.iconSlotCross
          dragSourceIndex: root.dragSourceIndex
          dragTargetIndex: root.dragTargetIndex
          anchorWindow: root.anchorWindow
          contextMenuVisible: contextMenu.visible
          onDragStarted: (idx) => root.dragSourceIndex = idx
          onDragEnded: root.dragSourceIndex = -1
          onDragTargetChanged: (idx) => root.dragTargetIndex = idx
          onDragTargetCleared: (idx) => { if (root.dragTargetIndex === idx) root.dragTargetIndex = -1 }
          onDropReceived: (fromIdx, toIdx) => { root.reorderApps(fromIdx, toIdx); root.dragSourceIndex = -1; root.dragTargetIndex = -1 }
          onContextMenuRequested: (appData, appIndex, anchorItem) => { contextMenu.appData = appData; contextMenu.appIndex = appIndex; contextMenu.anchorItem = anchorItem; contextMenu.open() }
        }
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
        delegate: DockItem {
          dockRoot: root.dockRoot
          vertical: root.vertical
          iconSlotMain: root.iconSlotMain
          iconSlotCross: root.iconSlotCross
          dragSourceIndex: root.dragSourceIndex
          dragTargetIndex: root.dragTargetIndex
          anchorWindow: root.anchorWindow
          contextMenuVisible: contextMenu.visible
          onDragStarted: (idx) => root.dragSourceIndex = idx
          onDragEnded: root.dragSourceIndex = -1
          onDragTargetChanged: (idx) => root.dragTargetIndex = idx
          onDragTargetCleared: (idx) => { if (root.dragTargetIndex === idx) root.dragTargetIndex = -1 }
          onDropReceived: (fromIdx, toIdx) => { root.reorderApps(fromIdx, toIdx); root.dragSourceIndex = -1; root.dragTargetIndex = -1 }
          onContextMenuRequested: (appData, appIndex, anchorItem) => { contextMenu.appData = appData; contextMenu.appIndex = appIndex; contextMenu.anchorItem = anchorItem; contextMenu.open() }
        }
      }
    }
  }

  DockMenu {
    id: contextMenu
    anchorWindow: root.anchorWindow
    dockRoot: root.dockRoot
  }
}

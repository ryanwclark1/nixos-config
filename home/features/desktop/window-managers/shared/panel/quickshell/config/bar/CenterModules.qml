import QtQuick
import Quickshell
import "../widgets" as SharedWidgets
import "../services"
import "../menu"

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  
  property bool cavaPopupVisible: false
  property string updatesIcon: "󰚰"
  property string updatesCount: "0"
  property bool inhibitorActive: false

  // Map spectrum values to block chars for bar display and popup
  readonly property var _blockChars: ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
  function _valToBlock(v) {
    var idx = Math.min(7, Math.floor(v * 8));
    return _blockChars[Math.max(0, idx)];
  }
  readonly property string fullCavaData: {
    var vals = (SpectrumService && SpectrumService.values) ? SpectrumService.values : [];
    var s = "";
    for (var i = 0; i < vals.length; i++) {
      var ch = _valToBlock(vals[i]);
      if (ch !== undefined) s += ch;
    }
    return s || "";
  }
  readonly property string cavaBarText: {
    var full = root.fullCavaData || "";
    return full.length >= 8 ? full.substring(0, 8) : (full.length > 0 ? full : "▁▂▃▄▅▆▇█");
  }

  // Read cached update counts written by qs-updator (triggered by UpdateWidget)
  SharedWidgets.CommandPoll {
    id: updatePoll
    interval: 600000
    running: root.visible
    command: ["sh", "-c",
      "nix=$(cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates/nixos\" 2>/dev/null || echo 0); "
      + "flat=$(cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates/flatpak\" 2>/dev/null || echo 0); "
      + "total=$(( (nix > 0 ? nix : 0) + (flat > 0 ? flat : 0) )); "
      + "echo $total"
    ]
    parse: function(out) { return parseInt(String(out || "").trim(), 10) || 0 }
    onUpdated: {
      var count = updatePoll.value || 0;
      root.updatesCount = count > 0 ? count.toString() : "0";
      root.updatesIcon = count > 0 ? "󰮯" : "󰚰";
    }
  }

  Row {
    id: mainRow
    spacing: Colors.spacingS
    anchors.verticalCenter: parent.verticalCenter

    SharedWidgets.MediaBar {
      anchorWindow: root.anchorWindow
    }

    // Updates Pill
    SharedWidgets.BarPill {
      id: updatesPill
      visible: root.updatesCount !== "0" && root.updatesCount !== ""
      anchorWindow: root.anchorWindow
      tooltipText: "System updates"

      Row {
        spacing: 6
        Text { text: root.updatesIcon; color: Colors.accent; font.pixelSize: Colors.fontSizeXL; font.family: Colors.fontMono; anchors.verticalCenter: parent.verticalCenter }
        Text { text: root.updatesCount; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
      }
    }

    // Cava spectrum (via SpectrumService)
    Loader { active: root.visible; sourceComponent: SharedWidgets.Ref { service: SpectrumService } }

    SharedWidgets.BarPill {
      id: cavaPill
      normalColor: "transparent"
      anchorWindow: root.anchorWindow
      tooltipText: "Audio visualizer"
      cursorShape: Qt.PointingHandCursor
      clip: true
      onClicked: root.cavaPopupVisible = !root.cavaPopupVisible

      Text {
        id: cavaText
        text: root.cavaBarText
        color: Colors.primary
        font.pixelSize: Colors.fontSizeMedium
      }
    }

    SharedWidgets.CommandPoll {
      id: inhibitorPoll
      interval: 2000
      running: root.visible
      command: ["sh", "-c", "[ -f /tmp/wayland_idle_inhibitor.pid ] && echo true || echo false"]
      parse: function(out) { return String(out || "").trim() === "true" }
      onUpdated: root.inhibitorActive = inhibitorPoll.value
    }

    // Idle Inhibitor Pill
    Rectangle {
      id: inhibitorPill
      width: 32
      height: 28
      color: root.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.2) : Colors.bgWidget
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter
      border.color: root.inhibitorActive ? Colors.primary : "transparent"
      border.width: 1
      scale: inhibitorMouse.containsMouse ? 1.06 : 1.0

      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      SharedWidgets.StateLayer {
        id: inhibitorStateLayer
        hovered: inhibitorMouse.containsMouse
        pressed: inhibitorMouse.pressed
      }

      Text {
        anchors.centerIn: parent
        text: "󰒲"
        color: root.inhibitorActive ? Colors.primary : Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.family: Colors.fontMono
      }

      MouseArea {
        id: inhibitorMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          inhibitorStateLayer.burst(mouse.x, mouse.y);
          Quickshell.execDetached(["qs-inhibitor"]);
          // Force check update slightly later
          inhibitorCheckTimer.restart()
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: inhibitorPill
        anchorWindow: root.anchorWindow
        hovered: inhibitorMouse.containsMouse
        text: root.inhibitorActive ? "Idle inhibitor enabled" : "Idle inhibitor"
      }

      Timer {
        id: inhibitorCheckTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: inhibitorPoll.poll()
      }
    }
  }

  CavaPopup {
    id: cavaPopup
    anchor.window: root.anchorWindow
    anchor.rect.x: {
      if (!cavaPill || !root.anchorWindow) return 0;
      try {
        return cavaPill.mapToItem(null, 0, 0).x + (cavaPill.width / 2) - (width / 2);
      } catch (e) {
        return 0;
      }
    }
    anchor.rect.y: {
      if (!cavaPill || !root.anchorWindow) return root.implicitHeight + 8;
      try {
        return cavaPill.mapToItem(null, 0, cavaPill.height).y + 8;
      } catch (e) {
        return root.implicitHeight + 8;
      }
    }
    visible: root.cavaPopupVisible
    cavaData: root.fullCavaData
    onCloseRequested: root.cavaPopupVisible = false
  }
}

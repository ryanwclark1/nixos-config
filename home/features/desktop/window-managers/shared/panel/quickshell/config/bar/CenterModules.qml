import QtQuick
import Quickshell
import "../widgets" as SharedWidgets
import "../services"

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  
  signal cavaClicked()
  signal dateTimeClicked()
  property alias cavaPill: cavaPill
  property alias dateTimePill: dateTimePill
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

    SystemClock {
      id: centerClock
      precision: Config.timeShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    SharedWidgets.BarPill {
      id: dateTimePill
      anchorWindow: root.anchorWindow
      tooltipText: Qt.formatDateTime(centerClock.date, "dddd, MMMM d yyyy")
      onClicked: root.dateTimeClicked()

      Row {
        spacing: Colors.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1

        Text {
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
          text: Qt.formatDateTime(
            centerClock.date,
            Config.timeUse24Hour
              ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm")
              : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP")
          )
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          visible: Config.timeShowBarDate
          color: Colors.textSecondary
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
          text: {
            if (Config.timeBarDateStyle === "month_day")
              return Qt.formatDateTime(centerClock.date, "MMM d");
            if (Config.timeBarDateStyle === "weekday_month_day")
              return Qt.formatDateTime(centerClock.date, "ddd MMM d");
            return Qt.formatDateTime(centerClock.date, "ddd d");
          }
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

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
        spacing: Colors.spacingXS
        Text { text: root.updatesIcon; color: Colors.accent; font.pixelSize: Colors.fontSizeXL; font.family: Colors.fontMono; anchors.verticalCenter: parent.verticalCenter }
        Text { text: root.updatesCount; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
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
      onClicked: root.cavaClicked()

      Text {
        id: cavaText
        text: root.cavaBarText
        color: Colors.primary
        font.pixelSize: Colors.fontSizeMedium
      }
    }

    SharedWidgets.CommandPoll {
      id: inhibitorPoll
      interval: 5000
      running: root.visible
      command: ["sh", "-c", "[ -f /tmp/wayland_idle_inhibitor.pid ] && echo true || echo false"]
      parse: function(out) { return String(out || "").trim() === "true" }
      onUpdated: root.inhibitorActive = inhibitorPoll.value
    }

    // Idle Inhibitor Pill
    SharedWidgets.BarPill {
      anchorWindow: root.anchorWindow
      normalColor: root.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.2) : Colors.bgWidget
      hoverColor: root.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.35) : Colors.highlightLight
      tooltipText: root.inhibitorActive ? "Idle inhibitor enabled" : "Idle inhibitor"
      anchors.verticalCenter: parent.verticalCenter
      onClicked: {
        Quickshell.execDetached(["qs-inhibitor"]);
        inhibitorCheckTimer.restart();
      }

      Text {
        text: "󰒲"
        color: root.inhibitorActive ? Colors.primary : Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.family: Colors.fontMono
      }

      Timer {
        id: inhibitorCheckTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: inhibitorPoll.triggerPoll()
      }
    }
  }

}

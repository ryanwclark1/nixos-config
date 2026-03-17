import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  Layout.preferredHeight: updatesLayout.implicitHeight + root.pad * 2

  property string nixUpdates: "0"
  property string flatpakUpdates: "0"
  property bool isChecking: false
  property bool lastRunFailed: false
  property string statusText: "Status: idle"
  property string statusDetail: "Press Refresh to check for updates."
  property string lastCheckedText: "Never"
  property string lastError: ""
  property double checkStartedAtMs: 0

  readonly property int totalUpdates: (parseInt(root.nixUpdates, 10) || 0) + (parseInt(root.flatpakUpdates, 10) || 0)

  readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") !== ""
    ? Quickshell.env("XDG_CACHE_HOME") + "/quickshell/updates"
    : Quickshell.env("HOME") + "/.cache/quickshell/updates"

  function sanitizeCount(raw) {
    var parsed = parseInt(String(raw || "0").trim(), 10);
    return isNaN(parsed) || parsed < 0 ? "0" : parsed.toString();
  }

  function formatDuration(ms) {
    var seconds = Math.max(0, Math.round(ms / 100) / 10);
    return seconds.toFixed(1) + "s";
  }

  CommandPoll {
    id: cachePoll
    interval: 3600000
    running: true
    command: ["sh", "-c",
      "nix=$(cat '" + root.cacheDir + "/nixos' 2>/dev/null || echo __missing__); "
      + "fpk=$(cat '" + root.cacheDir + "/flatpak' 2>/dev/null || echo __missing__); "
      + "printf '%s\\n%s\\n' \"$nix\" \"$fpk\""
    ]
    parse: function(out) {
      var lines = (out || "").trim().split("\n");
      return {
        nix: root.sanitizeCount(lines[0] || "0"),
        flatpak: root.sanitizeCount(lines.length >= 2 ? lines[1] : "0"),
        hasCache: (lines[0] || "") !== "__missing__" || (lines.length >= 2 && (lines[1] || "") !== "__missing__")
      };
    }
    onUpdated: {
      root.nixUpdates = cachePoll.value.nix;
      root.flatpakUpdates = cachePoll.value.flatpak;
      if (root.isChecking) return;
      if (root.lastRunFailed) return;
      if (!cachePoll.value.hasCache) {
        root.statusText = "Status: cache not initialized";
        root.statusDetail = "Run Refresh to generate update cache files.";
      } else if (root.totalUpdates === 0) {
        root.statusText = "Status: system is up to date";
        root.statusDetail = "No pending updates in tracked managers.";
      } else {
        root.statusText = "Status: " + root.totalUpdates + " update(s) available";
        root.statusDetail = "NixOS: " + root.nixUpdates + "  Flatpak: " + root.flatpakUpdates;
      }
    }
  }

  Process {
    id: refreshProc
    command: ["qs-updator"]
    onStarted: {
      root.isChecking = true;
      root.lastRunFailed = false;
      root.lastError = "";
      root.checkStartedAtMs = Date.now();
      root.statusText = "Status: checking updates...";
      root.statusDetail = "Running qs-updator";
    }
    onExited: (exitCode, exitStatus) => {
      root.isChecking = false;
      root.lastCheckedText = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss");
      if (exitCode === 0) {
        root.lastRunFailed = false;
        root.statusText = "Status: update check finished";
        root.statusDetail = "Completed in " + root.formatDuration(Date.now() - root.checkStartedAtMs);
        ToastService.showSuccess(
          "Update check complete",
          "Total available updates: " + root.totalUpdates
        );
        cachePoll.triggerPoll();
      } else {
        root.lastRunFailed = true;
        root.statusText = "Status: update check failed";
        var err = (root.lastError || "").trim();
        root.statusDetail = err.length > 0 ? err : "qs-updator exited with code " + exitCode;
        ToastService.showError("Update check failed", root.statusDetail);
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root.lastError = (this.text || "").trim();
        if (root.lastError.length > 0) console.warn("UpdateWidget: qs-updator error:", root.lastError);
      }
    }
  }

  function checkUpdates() {
    if (refreshProc.running) return;
    isChecking = true;
    refreshProc.running = true;
  }

  ColumnLayout {
    id: updatesLayout
    Layout.fillWidth: true
    spacing: Colors.paddingMedium

    RowLayout {
      Layout.fillWidth: true
      spacing: Colors.paddingMedium

      Rectangle {
        width: 42; height: 42; radius: Colors.radiusPill; color: Colors.secondary
        Layout.alignment: Qt.AlignTop
        Text { anchors.centerIn: parent; text: "󰚰"; color: Colors.text; font.pixelSize: Colors.fontSizeXL; font.family: Colors.fontMono }
      }

      Text {
        text: "System Updates"
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.Bold
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
      }

      Rectangle {
        width: 80; height: 32; radius: Colors.radiusXXS
        color: root.isChecking ? Colors.cardSurface : Colors.withAlpha(Colors.primary, 0.18)
        border.color: root.isChecking ? Colors.border : Colors.primary
        border.width: 1
        Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        scale: refreshHover.pressed ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack } }

        Rectangle {
          anchors.fill: parent
          anchors.margins: 1
          radius: parent.radius - 1
          color: "transparent"
          border.color: root.isChecking ? Colors.borderLight : Colors.withAlpha("#ffffff", 0.2)
          border.width: 1
          opacity: refreshHover.containsMouse ? 0.25 : 0.1
        }
        SharedWidgets.StateLayer {
          id: refreshStateLayer
          anchors.fill: parent
          radius: parent.radius
          stateColor: Colors.primary
          visible: !root.isChecking
          hovered: refreshHover.containsMouse
          pressed: refreshHover.pressed
        }
        MouseArea {
          id: refreshHover
          anchors.fill: parent
          hoverEnabled: true
          enabled: !root.isChecking
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            refreshStateLayer.burst(mouse.x, mouse.y);
            root.checkUpdates();
          }
        }
        Text {
          anchors.centerIn: parent
          text: root.isChecking ? "..." : "Refresh"
          color: root.isChecking ? Colors.textDisabled : Colors.primary
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.DemiBold
        }
      }
    }

    Flow {
      Layout.fillWidth: true
      width: parent.width
      spacing: Colors.spacingS

      SharedWidgets.Chip {
        icon: "󱄅"
        iconColor: Colors.primary
        text: "NixOS " + root.nixUpdates
        textColor: Colors.primary
      }

      SharedWidgets.Chip {
        icon: "󰏘"
        iconColor: Colors.accent
        text: "Flatpak " + root.flatpakUpdates
        textColor: Colors.accent
      }
    }

    Text {
      text: root.statusText
      color: root.lastRunFailed ? Colors.error : (root.isChecking ? Colors.info : Colors.textSecondary)
      font.pixelSize: Colors.fontSizeXS
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      maximumLineCount: 2
    }
    Text {
      text: root.statusDetail
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      maximumLineCount: 3
    }
    Text {
      text: "Last checked: " + root.lastCheckedText
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      maximumLineCount: 2
    }
    Text {
      text: "Only nix-based updates are currently supported."
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      maximumLineCount: 2
    }
  }
}

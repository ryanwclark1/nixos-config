pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PrinterService — subscriber-based CUPS printer monitoring singleton.
//
// Usage: add `SharedWidgets.Ref { service: PrinterService }` in any component
// that needs printer data. The service polls lpstat every 30s while any
// subscriber is active. Drop the Ref to stop polling.
//
// Exposes:
//   printers      — array of { name, status, statusText } objects
//   defaultPrinter — name of the system default printer
//   hasPrinters   — convenience bool
//   activeJobs    — total active job count across all printers
//   availabilityKnown — true after the first CUPS web-interface probe completes
//   hasWebInterface  — whether the active CUPS server exposes a reachable web UI
//   webInterfaceUrl  — normalized browser URL for the active CUPS server

QtObject {
  id: root

  // ── Public state ─────────────────────────────────────────────────────────
  property var printers: []
  property string defaultPrinter: ""
  readonly property bool hasPrinters: printers.length > 0
  property int activeJobs: 0
  property bool _webProbeComplete: false
  property bool _webProbeReachable: false
  property string _activeServer: ""
  property string webInterfaceUrl: ""
  readonly property bool availabilityKnown: _webProbeComplete
  readonly property bool hasWebInterface: availabilityKnown && _webProbeReachable && webInterfaceUrl !== ""

  // Subscriber-based lifecycle — increment via Ref { service: PrinterService }
  property int subscriberCount: 0

  // ── Polling ───────────────────────────────────────────────────────────────
  // Combines `lpstat -p -d` (printer list + default) and `lpstat -o | wc -l`
  // (active job count) in a single shell invocation to minimise process spawns.
  property var printerPoll: CommandPoll {
    interval: 30000
    running: root.subscriberCount > 0

    command: [
      "sh", "-c",
      "lpstat -p -d 2>/dev/null; echo '---JOBS---'; lpstat -o 2>/dev/null | wc -l"
    ]

    parse: function(out) {
      var sections = out.split("---JOBS---");
      var printerSection = sections[0] || "";
      var jobCount = parseInt((sections[1] || "0").trim()) || 0;

      var printerList = [];
      var defaultName = "";
      var lines = printerSection.trim().split("\n");

      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();

        // e.g. "printer MyPrinter is idle. enabled since ..."
        if (line.startsWith("printer ")) {
          var match = line.match(/^printer (\S+)\s+(.+)/);
          if (match) {
            var name = match[1];
            var statusText = match[2];
            var disabled  = statusText.indexOf("disabled") !== -1;
            var printing  = statusText.indexOf("printing") !== -1;
            var status    = disabled  ? "disabled"
                          : printing  ? "printing"
                          : "idle";

            printerList.push({ name: name, status: status, statusText: statusText });
          }
        }

        // e.g. "system default destination: MyPrinter"
        if (line.startsWith("system default destination:")) {
          defaultName = line.replace("system default destination:", "").trim();
        }
      }

      return { printers: printerList, defaultPrinter: defaultName, activeJobs: jobCount };
    }

    onUpdated: {
      root.printers      = value.printers      || [];
      root.defaultPrinter = value.defaultPrinter || "";
      root.activeJobs    = value.activeJobs    || 0;
    }
  }

  property Timer webInterfaceTimer: Timer {
    interval: 30000
    running: root.subscriberCount > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root._refreshWebInterfaceState()
  }

  property Process _webInterfaceProbe: Process {
    command: [
      "sh", "-c",
      "server=$(lpstat -H 2>/dev/null | head -n 1 | tr -d '\\r'); "
      + "url=''; "
      + "case \"$server\" in "
      + "  */cups.sock) url='http://localhost:631/' ;; "
      + "  '') url='' ;; "
      + "  *:*) url=\"http://$server/\" ;; "
      + "  *) url=\"http://$server:631/\" ;; "
      + "esac; "
      + "reachable=0; "
      + "if [ -n \"$url\" ] && curl -fsSI --max-time 2 \"$url\" >/dev/null 2>&1; then "
      + "  reachable=1; "
      + "fi; "
      + "printf 'SERVER:%s\\nURL:%s\\nREACHABLE:%s\\n' \"$server\" \"$url\" \"$reachable\""
    ]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        root._applyWebInterfaceProbe(this.text);
      }
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  function setDefault(printerName) {
    Quickshell.execDetached(["lpoptions", "-d", printerName]);
    // Optimistic local update — poll will confirm within 30s
    root.defaultPrinter = printerName;
  }

  function printTestPage(printerName) {
    Quickshell.execDetached([
      "sh", "-c",
      "lp -d \"$1\" /usr/share/cups/data/testprint.ps 2>/dev/null"
      + " || lp -d \"$1\" /usr/share/cups/testfiles/testprint.ps 2>/dev/null",
      "sh", printerName
    ]);
  }

  function cancelAllJobs(printerName) {
    Quickshell.execDetached(["cancel", "-a", printerName]);
    // Optimistically decrement active jobs count
    root.activeJobs = 0;
  }

  function enablePrinter(printerName) {
    Quickshell.execDetached(["cupsenable", printerName]);
    _updatePrinterStatus(printerName, "idle");
  }

  function disablePrinter(printerName) {
    Quickshell.execDetached(["cupsdisable", printerName]);
    _updatePrinterStatus(printerName, "disabled");
  }

  function openWebInterface() {
    if (!root.hasWebInterface)
      return;
    Quickshell.execDetached(["xdg-open", root.webInterfaceUrl]);
  }

  // Internal: optimistic local status mutation before next poll arrives
  function _updatePrinterStatus(printerName, newStatus) {
    var updated = [];
    for (var i = 0; i < root.printers.length; i++) {
      var p = root.printers[i];
      if (p.name === printerName) {
        updated.push({ name: p.name, status: newStatus, statusText: p.statusText });
      } else {
        updated.push(p);
      }
    }
    root.printers = updated;
  }

  // Force an immediate refresh (called when PrinterMenu opens)
  function refresh() {
    printerPoll.triggerPoll();
    _refreshWebInterfaceState();
  }

  function _refreshWebInterfaceState() {
    if (_webInterfaceProbe.running)
      return;
    _webInterfaceProbe.running = true;
  }

  function _applyWebInterfaceProbe(rawText) {
    var text = String(rawText || "");
    var lines = text.split("\n");
    var server = "";
    var url = "";
    var reachable = false;

    for (var i = 0; i < lines.length; ++i) {
      var line = String(lines[i] || "");
      if (line.indexOf("SERVER:") === 0)
        server = line.slice("SERVER:".length).trim();
      else if (line.indexOf("URL:") === 0)
        url = line.slice("URL:".length).trim();
      else if (line.indexOf("REACHABLE:") === 0)
        reachable = line.slice("REACHABLE:".length).trim() === "1";
    }

    root._activeServer = server;
    root.webInterfaceUrl = url;
    root._webProbeReachable = reachable && url !== "";
    root._webProbeComplete = true;
  }
}

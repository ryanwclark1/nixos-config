pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../widgets" as SharedWidgets

// PrinterService — subscriber-based CUPS printer monitoring singleton.
//
// Usage: add `SharedWidgets.Ref { service: PrinterService }` in any component
// that needs printer data. The service polls lpstat every 10s while any
// subscriber is active. Drop the Ref to stop polling.
//
// Exposes:
//   printers      — array of { name, status, statusText } objects
//   defaultPrinter — name of the system default printer
//   hasPrinters   — convenience bool
//   activeJobs    — total active job count across all printers

QtObject {
  id: root

  // ── Public state ─────────────────────────────────────────────────────────
  property var printers: []
  property string defaultPrinter: ""
  readonly property bool hasPrinters: printers.length > 0
  property int activeJobs: 0

  // Subscriber-based lifecycle — increment via Ref { service: PrinterService }
  property int subscriberCount: 0

  // ── Polling ───────────────────────────────────────────────────────────────
  // Combines `lpstat -p -d` (printer list + default) and `lpstat -o | wc -l`
  // (active job count) in a single shell invocation to minimise process spawns.
  property var poll: SharedWidgets.CommandPoll {
    interval: 10000
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

  // ── Actions ───────────────────────────────────────────────────────────────

  function setDefault(printerName) {
    Quickshell.execDetached(["lpoptions", "-d", printerName]);
    // Optimistic local update — poll will confirm within 10s
    root.defaultPrinter = printerName;
  }

  function printTestPage(printerName) {
    Quickshell.execDetached([
      "sh", "-c",
      "lp -d " + printerName + " /usr/share/cups/data/testprint.ps 2>/dev/null"
      + " || lp -d " + printerName + " /usr/share/cups/testfiles/testprint.ps 2>/dev/null"
    ]);
  }

  function cancelAllJobs(printerName) {
    Quickshell.execDetached(["cancel", "-a", printerName]);
    // Optimistically decrement active jobs count
    root.activeJobs = Math.max(0, root.activeJobs - 1);
  }

  function enablePrinter(printerName) {
    Quickshell.execDetached(["cupsenable", printerName]);
    _updatePrinterStatus(printerName, "idle");
  }

  function disablePrinter(printerName) {
    Quickshell.execDetached(["cupsdisable", printerName]);
    _updatePrinterStatus(printerName, "disabled");
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
    poller.poll();
  }
}

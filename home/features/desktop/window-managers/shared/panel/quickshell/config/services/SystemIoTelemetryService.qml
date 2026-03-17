pragma Singleton
import QtQuick
import "../widgets" as SharedWidgets

QtObject {
    id: root

    property int subscriberCount: 0
    property int sampleIntervalMs: 1000
    property int historyLength: 180

    property var interfaces: []
    property var diskDevices: []
    property string selectedInterface: ""
    property string selectedDiskDevice: ""

    property var networkHistoryDown: []
    property var networkHistoryUp: []
    property var diskHistoryRead: []
    property var diskHistoryWrite: []

    property real currentNetworkDown: 0
    property real currentNetworkUp: 0
    property real currentDiskRead: 0
    property real currentDiskWrite: 0
    property real peakNetworkDown: 0
    property real peakNetworkUp: 0
    property real peakDiskRead: 0
    property real peakDiskWrite: 0

    property bool networkHotspot: false
    property bool diskHotspot: false
    property string telemetryStatus: "loading"
    property string telemetryMessage: ""
    property double networkLastSampleMs: 0
    property double diskLastSampleMs: 0
    property double metadataLastRefreshMs: 0
    property bool networkDegraded: false
    property bool diskDegraded: false

    property var _interfaceTotals: ({})

    property real _lastRx: -1
    property real _lastTx: -1
    property real _lastReadSectors: -1
    property real _lastWriteSectors: -1

    function filledHistory() {
        return new Array(historyLength).fill(0);
    }

    function resetHistories() {
        networkHistoryDown = filledHistory();
        networkHistoryUp = filledHistory();
        diskHistoryRead = filledHistory();
        diskHistoryWrite = filledHistory();
        currentNetworkDown = 0;
        currentNetworkUp = 0;
        currentDiskRead = 0;
        currentDiskWrite = 0;
        peakNetworkDown = 0;
        peakNetworkUp = 0;
        peakDiskRead = 0;
        peakDiskWrite = 0;
        networkHotspot = false;
        diskHotspot = false;
        networkLastSampleMs = 0;
        diskLastSampleMs = 0;
        networkDegraded = false;
        diskDegraded = false;
        _lastRx = -1;
        _lastTx = -1;
        _lastReadSectors = -1;
        _lastWriteSectors = -1;
    }

    function pushHistory(history, value) {
        var next = history && history.length ? history.slice() : filledHistory();
        if (next.length >= historyLength)
            next.shift();
        next.push(value);
        while (next.length < historyLength)
            next.unshift(0);
        return next;
    }

    function arrayMax(values) {
        var maxValue = 0;
        for (var i = 0; i < values.length; ++i)
            maxValue = Math.max(maxValue, Number(values[i] || 0));
        return maxValue;
    }

    function setSelectedInterface(name) {
        var next = String(name || "");
        if (selectedInterface === next)
            return;
        selectedInterface = next;
        resetHistories();
        samplePoll.triggerPoll();
    }

    function setSelectedDiskDevice(name) {
        var next = String(name || "");
        if (selectedDiskDevice === next)
            return;
        selectedDiskDevice = next;
        resetHistories();
        samplePoll.triggerPoll();
    }

    function refreshMetadata() {
        metadataPoll.triggerPoll();
    }

    function _fallbackInterface(defaultIface, nextInterfaces) {
        var preferred = String(defaultIface || "");
        if (preferred !== "" && nextInterfaces.indexOf(preferred) !== -1)
            return preferred;

        var busiest = "";
        var busiestValue = -1;
        for (var i = 0; i < nextInterfaces.length; ++i) {
            var iface = String(nextInterfaces[i] || "");
            var bytes = Number((_interfaceTotals || {})[iface] || 0);
            if (bytes > busiestValue) {
                busiest = iface;
                busiestValue = bytes;
            }
        }
        return busiest;
    }

    function _updateTelemetryState() {
        if (selectedInterface === "" && selectedDiskDevice === "") {
            telemetryStatus = "missing";
            telemetryMessage = "No network or disk telemetry source was discovered.";
            return;
        }

        if (networkDegraded || diskDegraded) {
            telemetryStatus = "degraded";
            var issues = [];
            if (networkDegraded && selectedInterface !== "")
                issues.push("network telemetry stale");
            if (diskDegraded && selectedDiskDevice !== "")
                issues.push("disk telemetry stale");
            telemetryMessage = issues.join("; ");
            return;
        }

        telemetryStatus = "ready";
        telemetryMessage = "";
    }

    function _metadataCommand() {
        return [
            "sh",
            "-c",
            "defaultIface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); "
            + "rootSrc=$(findmnt -no SOURCE / 2>/dev/null | sed 's|^/dev/||' | sed 's/\\[.*$//'); "
            + "rootBase=$(printf '%s' \"$rootSrc\" | sed 's/[0-9]\\+$//' | sed 's/p$//'); "
            + "printf 'DEFAULT_IFACE=%s\\n' \"$defaultIface\"; "
            + "printf 'DEFAULT_DISK=%s\\n' \"$rootBase\"; "
            + "for iface in $(ls /sys/class/net 2>/dev/null | grep -v '^lo$'); do "
            + "  rx=$(cat \"/sys/class/net/$iface/statistics/rx_bytes\" 2>/dev/null || echo 0); "
            + "  tx=$(cat \"/sys/class/net/$iface/statistics/tx_bytes\" 2>/dev/null || echo 0); "
            + "  total=$((rx + tx)); "
            + "  printf 'IFACE=%s\\t%s\\n' \"$iface\" \"$total\"; "
            + "done; "
            + "awk 'BEGIN{seen[\"\"]=1} $3 ~ /^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+|md[0-9]+)$/ { if (!seen[$3]++) print \"DISK=\" $3 }' /proc/diskstats 2>/dev/null"
        ];
    }

    function _sampleCommand() {
        return [
            "sh",
            "-c",
            "iface=\"$1\"; disk=\"$2\"; "
            + "rx=0; tx=0; readSec=0; writeSec=0; "
            + "if [ -n \"$iface\" ]; then "
            + "  rx=$(cat \"/sys/class/net/$iface/statistics/rx_bytes\" 2>/dev/null || echo 0); "
            + "  tx=$(cat \"/sys/class/net/$iface/statistics/tx_bytes\" 2>/dev/null || echo 0); "
            + "fi; "
            + "if [ -n \"$disk\" ]; then "
            + "  diskLine=$(awk -v dev=\"$disk\" '$3 == dev {print; exit}' /proc/diskstats 2>/dev/null); "
            + "  if [ -n \"$diskLine\" ]; then "
            + "    readSec=$(printf '%s\\n' \"$diskLine\" | awk '{print $6}'); "
            + "    writeSec=$(printf '%s\\n' \"$diskLine\" | awk '{print $10}'); "
            + "  fi; "
            + "fi; "
            + "printf 'IFACE=%s\\nRX=%s\\nTX=%s\\nDISK=%s\\nREAD_SEC=%s\\nWRITE_SEC=%s\\n' \"$iface\" \"$rx\" \"$tx\" \"$disk\" \"$readSec\" \"$writeSec\"",
            "sh",
            String(selectedInterface || ""),
            String(selectedDiskDevice || "")
        ];
    }

    function _parseKeyValueOutput(out) {
        var lines = String(out || "").trim().split("\n");
        var data = {};
        var ifaces = [];
        var disks = [];
        var interfaceTotals = {};
        for (var i = 0; i < lines.length; ++i) {
            var line = String(lines[i] || "");
            var idx = line.indexOf("=");
            if (idx === -1)
                continue;
            var key = line.substring(0, idx);
            var value = line.substring(idx + 1);
            if (key === "IFACE") {
                var parts = value.split("\t");
                var iface = String(parts[0] || "");
                if (iface !== "") {
                    ifaces.push(iface);
                    interfaceTotals[iface] = Number(parts[1] || 0);
                }
            }
            else if (key === "DISK")
                disks.push(value);
            else
                data[key] = value;
        }
        data.interfaces = ifaces;
        data.disks = disks;
        data.interfaceTotals = interfaceTotals;
        return data;
    }

    function _applyMetadata(snapshot) {
        var nextInterfaces = snapshot.interfaces || [];
        var nextDisks = snapshot.disks || [];

        interfaces = nextInterfaces;
        diskDevices = nextDisks;
        _interfaceTotals = snapshot.interfaceTotals || {};
        metadataLastRefreshMs = Date.now();

        var nextInterface = selectedInterface;
        if (nextInterfaces.indexOf(nextInterface) === -1)
            nextInterface = _fallbackInterface(snapshot.DEFAULT_IFACE, nextInterfaces);

        var nextDisk = selectedDiskDevice;
        if (nextDisks.indexOf(nextDisk) === -1) {
            var preferredDisk = String(snapshot.DEFAULT_DISK || "");
            nextDisk = nextDisks.indexOf(preferredDisk) !== -1 ? preferredDisk : String(nextDisks[0] || preferredDisk || "");
        }

        var changed = nextInterface !== selectedInterface || nextDisk !== selectedDiskDevice;
        selectedInterface = nextInterface;
        selectedDiskDevice = nextDisk;

        if (changed)
            resetHistories();
        _updateTelemetryState();
    }

    property var metadataPoll: SharedWidgets.CommandPoll {
        id: metadataPoll
        interval: 10000
        running: root.subscriberCount > 0
        command: root._metadataCommand()
        parse: function(out) {
            return root._parseKeyValueOutput(out);
        }
        onUpdated: {
            root._applyMetadata(metadataPoll.value || {});
        }
    }

    property var samplePoll: SharedWidgets.CommandPoll {
        id: samplePoll
        interval: Math.max(1000, root.sampleIntervalMs)
        running: root.subscriberCount > 0 && (root.selectedInterface !== "" || root.selectedDiskDevice !== "")
        command: root._sampleCommand()
        parse: function(out) {
            return root._parseKeyValueOutput(out);
        }
        onUpdated: {
            var snapshot = samplePoll.value || {};
            var rx = Number(snapshot.RX || 0);
            var tx = Number(snapshot.TX || 0);
            var readSectors = Number(snapshot.READ_SEC || 0);
            var writeSectors = Number(snapshot.WRITE_SEC || 0);
            var now = Date.now();

            if (root._lastRx >= 0) {
                root.currentNetworkDown = Math.max(0, rx - root._lastRx);
                root.currentNetworkUp = Math.max(0, tx - root._lastTx);
                root.networkHistoryDown = root.pushHistory(root.networkHistoryDown, root.currentNetworkDown);
                root.networkHistoryUp = root.pushHistory(root.networkHistoryUp, root.currentNetworkUp);
                root.peakNetworkDown = root.arrayMax(root.networkHistoryDown);
                root.peakNetworkUp = root.arrayMax(root.networkHistoryUp);
                root.networkHotspot = (root.peakNetworkDown > 0 && root.currentNetworkDown >= root.peakNetworkDown * 0.8)
                    || (root.peakNetworkUp > 0 && root.currentNetworkUp >= root.peakNetworkUp * 0.8);
            }
            if (root.selectedInterface !== "") {
                root.networkLastSampleMs = now;
                root.networkDegraded = false;
            }

            if (root._lastReadSectors >= 0) {
                root.currentDiskRead = Math.max(0, readSectors - root._lastReadSectors) * 512;
                root.currentDiskWrite = Math.max(0, writeSectors - root._lastWriteSectors) * 512;
                root.diskHistoryRead = root.pushHistory(root.diskHistoryRead, root.currentDiskRead);
                root.diskHistoryWrite = root.pushHistory(root.diskHistoryWrite, root.currentDiskWrite);
                root.peakDiskRead = root.arrayMax(root.diskHistoryRead);
                root.peakDiskWrite = root.arrayMax(root.diskHistoryWrite);
                root.diskHotspot = (root.peakDiskRead > 0 && root.currentDiskRead >= root.peakDiskRead * 0.8)
                    || (root.peakDiskWrite > 0 && root.currentDiskWrite >= root.peakDiskWrite * 0.8);
            }
            if (root.selectedDiskDevice !== "") {
                root.diskLastSampleMs = now;
                root.diskDegraded = false;
            }

            root._lastRx = rx;
            root._lastTx = tx;
            root._lastReadSectors = readSectors;
            root._lastWriteSectors = writeSectors;
            root._updateTelemetryState();
        }
    }

    property Timer staleTimer: Timer {
        interval: Math.max(1500, root.sampleIntervalMs * 2)
        repeat: true
        running: root.subscriberCount > 0
        triggeredOnStart: true
        onTriggered: {
            var now = Date.now();
            if (root.selectedInterface !== "" && root.networkLastSampleMs > 0 && now - root.networkLastSampleMs > Math.max(3000, root.sampleIntervalMs * 3))
                root.networkDegraded = true;
            if (root.selectedDiskDevice !== "" && root.diskLastSampleMs > 0 && now - root.diskLastSampleMs > Math.max(3000, root.sampleIntervalMs * 3))
                root.diskDegraded = true;
            root._updateTelemetryState();
        }
    }
}

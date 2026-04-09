pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "."
import "BluetoothCatalog.js" as Catalog

QtObject {
    id: root

    property var allDevices: []
    property var connectedDevices: []
    property var pairedDevices: []
    property var availableDevices: []
    property bool isScanning: false
    property bool monitorAvailable: DependencyService.hasResolvedCommand("qs-bluetooth-monitor")
    property bool monitorHealthy: false
    property bool powered: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
    property string adapterAddress: ""
    property var _entriesByAddress: ({})
    property int _scanTimeoutMs: 30000
    property int _cleanupIntervalMs: 5000
    property int _fallbackSyncIntervalMs: 2000
    property var _lookups: ({
        companyLookup: {},
        serviceLookup: {},
        appearanceLookup: {}
    })
    readonly property string _dataRoot: (Quickshell.env("QS_CONFIG_DIR") || ((Quickshell.env("HOME") || "/home") + "/.config/quickshell")) + "/src/data/bluetooth-numbers"

    function refresh() {
        _syncFromQuickshell();
        _rebuildViews(Date.now());
    }

    function startScan() {
        if (!Bluetooth.defaultAdapter || !powered)
            return;
        Bluetooth.defaultAdapter.discovering = true;
        isScanning = true;
        _scanTimeout.restart();
    }

    function stopScan() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discovering = false;
        isScanning = false;
        _scanTimeout.stop();
    }

    function findLiveDevice(address) {
        var wanted = Catalog.normalizeAddress(address);
        var devices = (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values : [];
        for (var i = 0; i < devices.length; ++i) {
            var dev = devices[i];
            if (Catalog.normalizeAddress(dev && dev.address) === wanted)
                return dev;
        }
        return null;
    }

    function _loadJson(fileView) {
        try {
            var raw = String(fileView.text() || "").trim();
            if (!raw)
                return [];
            var parsed = JSON.parse(raw);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            Logger.w("BluetoothCatalogService", "Failed to parse numbers data:", fileView.path, e);
            return [];
        }
    }

    function _loadLookups() {
        _lookups = {
            companyLookup: Catalog.buildCompanyLookup(_loadJson(_companyIds)),
            serviceLookup: Catalog.buildServiceLookup(_loadJson(_serviceUuids)),
            appearanceLookup: Catalog.buildAppearanceLookup(_loadJson(_gapAppearance))
        };
        _rebuildViews(Date.now());
    }

    function _syncFromQuickshell() {
        var now = Date.now();
        var devices = (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values : [];
        var next = Object.assign({}, _entriesByAddress);
        var seen = {};
        for (var i = 0; i < devices.length; ++i) {
            var dev = devices[i];
            var address = Catalog.normalizeAddress(dev && dev.address);
            if (address.length === 0)
                continue;
            seen[address] = true;
            next[address] = Catalog.mergeEntry(next[address], {
                address: address,
                name: dev && dev.name || "",
                alias: dev && dev.name || "",
                connected: !!(dev && dev.connected),
                paired: !!(dev && dev.paired),
                trusted: !!(dev && dev.trusted),
                blocked: !!(dev && dev.blocked),
                source: "quickshell"
            }, now, "quickshell");
        }
        _entriesByAddress = Catalog.markMissingEntries(next, seen, now, Catalog.ENTRY_TTL_MS);
    }

    function _mergeMonitorSnapshot(msg) {
        var now = Date.now();
        var next = Object.assign({}, _entriesByAddress);
        var seen = {};
        var items = Array.isArray(msg.devices) ? msg.devices : [];
        adapterAddress = String(msg.adapterAddress || "");
        for (var i = 0; i < items.length; ++i) {
            var dev = items[i];
            var address = Catalog.normalizeAddress(dev && dev.address);
            if (address.length === 0)
                continue;
            seen[address] = true;
            next[address] = Catalog.mergeEntry(next[address], dev, now, "bluez");
        }
        _entriesByAddress = Catalog.markMissingEntries(next, seen, now, Catalog.ENTRY_TTL_MS);
        monitorHealthy = true;
    }

    function _rebuildViews(now) {
        var sections = Catalog.sectionedEntries(_entriesByAddress, now, Catalog.ENTRY_TTL_MS);
        function enrich(items) {
            var output = [];
            for (var i = 0; i < items.length; ++i) {
                var enriched = Catalog.enrichEntry(items[i], _lookups, now);
                enriched.subtitle = Catalog.subtitleForEntry(enriched);
                output.push(enriched);
            }
            return output;
        }
        connectedDevices = enrich(sections.connected);
        pairedDevices = enrich(sections.paired);
        availableDevices = enrich(sections.available);
        allDevices = enrich(sections.all);
    }

    function _applyMonitorLine(data) {
        var line = String(data || "").trim();
        if (!line)
            return;
        try {
            var msg = JSON.parse(line);
            if (msg.type !== "snapshot")
                return;
            _mergeMonitorSnapshot(msg);
            _rebuildViews(Date.now());
        } catch (e) {
            Logger.w("BluetoothCatalogService", "Invalid monitor payload:", e);
        }
    }

    readonly property FileView _companyIds: FileView {
        path: root._dataRoot + "/company_ids.json"
        blockLoading: true
        printErrors: false
    }

    readonly property FileView _serviceUuids: FileView {
        path: root._dataRoot + "/service_uuids.json"
        blockLoading: true
        printErrors: false
    }

    readonly property FileView _gapAppearance: FileView {
        path: root._dataRoot + "/gap_appearance.json"
        blockLoading: true
        printErrors: false
    }

    property Process _monitor: Process {
        command: DependencyService.resolveCommand("qs-bluetooth-monitor")
        running: monitorAvailable

        stdout: SplitParser {
            onRead: data => root._applyMonitorLine(data)
        }

        onExited: (exitCode, exitStatus) => {
            root.monitorHealthy = false;
            root._restartMonitor.restart();
        }
    }

    property Timer _restartMonitor: Timer {
        interval: 3000
        repeat: false
        onTriggered: {
            if (root.monitorAvailable && !root._monitor.running)
                root._monitor.running = true;
        }
    }

    property Timer _scanTimeout: Timer {
        interval: root._scanTimeoutMs
        repeat: false
        onTriggered: root.stopScan()
    }

    property Timer _cleanupTimer: Timer {
        interval: root._cleanupIntervalMs
        repeat: true
        running: true
        onTriggered: {
            root._entriesByAddress = Catalog.markMissingEntries(root._entriesByAddress, {}, Date.now(), Catalog.ENTRY_TTL_MS);
            root._rebuildViews(Date.now());
        }
    }

    property Timer _fallbackSyncTimer: Timer {
        interval: root._fallbackSyncIntervalMs
        repeat: true
        running: true
        onTriggered: {
            root._syncFromQuickshell();
            root._rebuildViews(Date.now());
        }
    }

    property Connections _adapterConnections: Connections {
        target: Bluetooth.defaultAdapter
        ignoreUnknownSignals: true

        function onEnabledChanged() {
            if (!root.powered)
                root.stopScan();
        }

        function onDiscoveringChanged() {
            root.isScanning = !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering);
            if (!root.isScanning)
                root._scanTimeout.stop();
        }
    }

    readonly property int _btDeviceCount: (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values.length : 0
    on_BtDeviceCountChanged: refresh()

    onPoweredChanged: {
        if (!powered)
            stopScan();
    }

    Component.onCompleted: {
        _loadLookups();
        refresh();
        isScanning = !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering);
    }
}

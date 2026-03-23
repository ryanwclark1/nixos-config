pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "GpuTelemetryHelpers.js" as GpuTelemetryHelpers

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 2000
    
    // Summary metrics (for the primary/first device)
    property string deviceName: "AMD GPU"
    property string drmCardName: ""
    property string pciAddress: ""
    property real gfxUsage: 0.0
    property real memUsage: 0.0
    property real mediaUsage: 0.0
    property real vramUsageBytes: 0
    property real vramTotalBytes: 0
    property real vramPercent: 0.0
    property real powerWatts: 0
    property real tempEdge: 0
    property real tempJunction: 0
    property real fanRpm: 0
    
    // Full data for multi-GPU setups
    property var devices: []
    
    // Per-process GPU usage
    property var processGpuUsage: ({}) // pid -> { gfx, mem, vram, name }

    readonly property bool available: _probeComplete && _probeProc.exitCode === 0
    property bool _probeComplete: false
    property bool _ready: false
    Component.onCompleted: _ready = true

    property Process _probeProc: Process {
        id: _probeProc
        command: ["sh", "-c", "command -v amdgpu_top >/dev/null 2>&1"]
        running: true
        onExited: root._probeComplete = true
    }

    function refresh() {
        if (!available) return;
        if (!gpuPoll.running) gpuPoll.running = true;
        else gpuPoll.triggerPoll();
    }

    function _resetSelection() {
        root.deviceName = "AMD GPU";
        root.drmCardName = "";
        root.pciAddress = "";
        root.gfxUsage = 0.0;
        root.memUsage = 0.0;
        root.mediaUsage = 0.0;
        root.vramUsageBytes = 0;
        root.vramTotalBytes = 0;
        root.vramPercent = 0.0;
        root.powerWatts = 0;
        root.tempEdge = 0;
        root.tempJunction = 0;
        root.fanRpm = 0;
        root.processGpuUsage = ({});
    }

    property CommandPoll gpuPoll: CommandPoll {
        id: gpuPoll
        interval: Math.max(1000, root.pollIntervalMs)
        running: root._ready && root.subscriberCount > 0 && root.available
        command: ["amdgpu_top", "--json", "-n", "1"]
        
        parse: function(out) {
            try {
                return JSON.parse(out);
            } catch (e) {
                return null;
            }
        }
        
        onUpdated: {
            var data = gpuPoll.value;
            if (!data || !data.devices || data.devices.length === 0) {
                root.devices = [];
                root._resetSelection();
                return;
            }
            
            root.devices = data.devices;
            
            var dev = GpuTelemetryHelpers.findMatchingAmdgpuTopDevice(data.devices, {
                cardName: SystemStatus.gpuCardName,
                pciAddress: SystemStatus.gpuPciAddress,
            });
            if (!dev)
                dev = GpuTelemetryHelpers.selectPreferredAmdgpuTopDevice(data.devices);
            if (!dev) {
                root._resetSelection();
                return;
            }

            var identity = GpuTelemetryHelpers.amdgpuTopDeviceIdentity(dev);
            root.deviceName = dev.Info && dev.Info.DeviceName ? dev.Info.DeviceName : "AMD GPU";
            root.drmCardName = identity.cardName;
            root.pciAddress = identity.pciAddress;
            
            // Activity
            var activity = dev.gpu_activity || ({});
            root.gfxUsage = (activity.GFX ? activity.GFX.value : 0) / 100;
            root.mediaUsage = (activity.MediaEngine ? activity.MediaEngine.value : 0) / 100;
            root.memUsage = (activity.Memory ? activity.Memory.value : 0) / 100;
            
            // VRAM
            var vram = dev.VRAM || ({});
            root.vramUsageBytes = (vram["Total VRAM Usage"] ? vram["Total VRAM Usage"].value : 0) * 1024 * 1024;
            root.vramTotalBytes = (vram["Total VRAM"] ? vram["Total VRAM"].value : 0) * 1024 * 1024;
            root.vramPercent = root.vramTotalBytes > 0 ? (root.vramUsageBytes / root.vramTotalBytes) : 0;
            
            // Sensors
            var sensors = dev.Sensors || ({});
            root.powerWatts = sensors["Average Power"] ? sensors["Average Power"].value : 0;
            root.tempEdge = sensors["Edge Temperature"] ? sensors["Edge Temperature"].value : 0;
            root.tempJunction = sensors["Junction Temperature"] ? sensors["Junction Temperature"].value : 0;
            root.fanRpm = sensors["Fan"] ? sensors["Fan"].value : 0;
            
            // Per-process usage
            var nextProcessUsage = {};
            if (dev.fdinfo) {
                for (var pid in dev.fdinfo) {
                    var info = dev.fdinfo[pid];
                    var usage = GpuTelemetryHelpers.amdgpuFdinfoUsage(info);
                    nextProcessUsage[pid] = {
                        name: info.name || usage.name || pid,
                        gfx: usage.GFX ? usage.GFX.value : 0,
                        vram: (usage.VRAM ? usage.VRAM.value : 0) * 1024 * 1024,
                        media: usage.Media ? usage.Media.value : 0
                    };
                }
            }
            root.processGpuUsage = nextProcessUsage;
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 2000
    
    // Summary metrics (for the primary/first device)
    property string deviceName: "AMD GPU"
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

    readonly property bool available: _probeProc.exitCode === 0
    property bool _ready: false
    Component.onCompleted: _ready = true

    property Process _probeProc: Process {
        id: _probeProc
        command: ["command", "-v", "amdgpu_top"]
        running: true
    }

    function refresh() {
        if (!available) return;
        if (!gpuPoll.running) gpuPoll.running = true;
        else gpuPoll.triggerPoll();
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
            if (!data || !data.devices || data.devices.length === 0) return;
            
            root.devices = data.devices;
            
            // Primary device (usually discrete or first discovered)
            var dev = data.devices[0];
            root.deviceName = dev.Info.DeviceName || "AMD GPU";
            
            // Activity
            if (dev.gpu_activity) {
                root.gfxUsage = (dev.gpu_activity.GFX.value || 0) / 100;
                root.mediaUsage = (dev.gpu_activity.MediaEngine.value || 0) / 100;
                root.memUsage = (dev.gpu_activity.Memory.value || 0) / 100;
            }
            
            // VRAM
            if (dev.VRAM) {
                root.vramUsageBytes = (dev.VRAM["Total VRAM Usage"].value || 0) * 1024 * 1024;
                root.vramTotalBytes = (dev.VRAM["Total VRAM"].value || 0) * 1024 * 1024;
                root.vramPercent = root.vramTotalBytes > 0 ? (root.vramUsageBytes / root.vramTotalBytes) : 0;
            }
            
            // Sensors
            if (dev.Sensors) {
                root.powerWatts = dev.Sensors["Average Power"] ? dev.Sensors["Average Power"].value : 0;
                root.tempEdge = dev.Sensors["Edge Temperature"] ? dev.Sensors["Edge Temperature"].value : 0;
                root.tempJunction = dev.Sensors["Junction Temperature"] ? dev.Sensors["Junction Temperature"].value : 0;
                root.fanRpm = dev.Sensors["Fan"] ? dev.Sensors["Fan"].value : 0;
            }
            
            // Per-process usage
            if (dev.fdinfo) {
                var nextProcessUsage = {};
                for (var pid in dev.fdinfo) {
                    var info = dev.fdinfo[pid];
                    nextProcessUsage[pid] = {
                        name: info.name,
                        gfx: info.usage.GFX.value || 0,
                        vram: (info.usage.VRAM.value || 0) * 1024 * 1024,
                        media: info.usage.Media.value || 0
                    };
                }
                root.processGpuUsage = nextProcessUsage;
            }
        }
    }
}

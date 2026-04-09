#!/usr/bin/env python3

import json
import signal
import sys

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


BLUEZ_BUS = "org.bluez"
OM_IFACE = "org.freedesktop.DBus.ObjectManager"
PROPS_IFACE = "org.freedesktop.DBus.Properties"
ADAPTER_IFACE = "org.bluez.Adapter1"
DEVICE_IFACE = "org.bluez.Device1"


def to_python(value):
    if isinstance(value, dbus.String):
        return str(value)
    if isinstance(value, (dbus.Boolean,)):
        return bool(value)
    if isinstance(value, (dbus.Int16, dbus.Int32, dbus.Int64, dbus.UInt16, dbus.UInt32, dbus.UInt64, dbus.Byte)):
        return int(value)
    if isinstance(value, (dbus.Double,)):
        return float(value)
    if isinstance(value, dbus.Array):
        return [to_python(v) for v in value]
    if isinstance(value, dbus.Dictionary):
        return {to_python(k): to_python(v) for k, v in value.items()}
    if isinstance(value, dbus.ByteArray):
        return [int(v) for v in value]
    return value


class BluetoothMonitor:
    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.loop = GLib.MainLoop()
        self.obj_manager = dbus.Interface(self.bus.get_object(BLUEZ_BUS, "/"), OM_IFACE)
        self.objects = self._load_objects()

        self.bus.add_signal_receiver(
            self.on_interfaces_added,
            dbus_interface=OM_IFACE,
            signal_name="InterfacesAdded",
            bus_name=BLUEZ_BUS,
        )
        self.bus.add_signal_receiver(
            self.on_interfaces_removed,
            dbus_interface=OM_IFACE,
            signal_name="InterfacesRemoved",
            bus_name=BLUEZ_BUS,
        )
        self.bus.add_signal_receiver(
            self.on_properties_changed,
            dbus_interface=PROPS_IFACE,
            signal_name="PropertiesChanged",
            path_keyword="path",
            bus_name=BLUEZ_BUS,
        )

    def _load_objects(self):
        managed = self.obj_manager.GetManagedObjects()
        return {str(path): {str(iface): to_python(props) for iface, props in ifaces.items()} for path, ifaces in managed.items()}

    def adapter_paths(self):
        paths = [path for path, ifaces in self.objects.items() if ADAPTER_IFACE in ifaces]
        return sorted(paths)

    def default_adapter_path(self):
        paths = self.adapter_paths()
        return paths[0] if paths else ""

    def _device_snapshot(self, path, props):
        address = str(props.get("Address", "")).upper()
        manufacturer_data = props.get("ManufacturerData", {}) or {}
        service_data = props.get("ServiceData", {}) or {}
        return {
            "address": address,
            "name": str(props.get("Name", "")),
            "alias": str(props.get("Alias", "")),
            "paired": bool(props.get("Paired", False)),
            "trusted": bool(props.get("Trusted", False)),
            "blocked": bool(props.get("Blocked", False)),
            "connected": bool(props.get("Connected", False)),
            "rssi": int(props["RSSI"]) if "RSSI" in props else None,
            "appearance": int(props["Appearance"]) if "Appearance" in props else None,
            "class": int(props["Class"]) if "Class" in props else None,
            "addressType": str(props.get("AddressType", "")),
            "serviceUuids": [str(item).upper() for item in props.get("UUIDs", [])],
            "manufacturerIds": sorted(int(key) for key in manufacturer_data.keys()),
            "serviceDataKeys": [str(key).upper() for key in service_data.keys()],
            "source": "bluez",
            "path": path,
        }

    def snapshot(self):
        adapter_path = self.default_adapter_path()
        adapter = self.objects.get(adapter_path, {}).get(ADAPTER_IFACE, {}) if adapter_path else {}
        devices = []
        for path, ifaces in self.objects.items():
            if DEVICE_IFACE not in ifaces:
                continue
            if adapter_path and not path.startswith(adapter_path + "/"):
                continue
            devices.append(self._device_snapshot(path, ifaces[DEVICE_IFACE]))
        devices.sort(key=lambda item: (not item["connected"], not item["paired"], item["name"] or item["address"]))
        return {
            "type": "snapshot",
            "adapterPath": adapter_path,
            "adapterAddress": str(adapter.get("Address", "")).upper(),
            "powered": bool(adapter.get("Powered", False)),
            "discovering": bool(adapter.get("Discovering", False)),
            "devices": devices,
        }

    def emit_snapshot(self):
        payload = json.dumps(self.snapshot(), separators=(",", ":"))
        sys.stdout.write(payload + "\n")
        sys.stdout.flush()

    def on_interfaces_added(self, path, interfaces):
        key = str(path)
        current = self.objects.get(key, {})
        for iface, props in interfaces.items():
            current[str(iface)] = to_python(props)
        self.objects[key] = current
        self.emit_snapshot()

    def on_interfaces_removed(self, path, interfaces):
        key = str(path)
        current = self.objects.get(key, {})
        for iface in interfaces:
            current.pop(str(iface), None)
        if current:
            self.objects[key] = current
        else:
            self.objects.pop(key, None)
        self.emit_snapshot()

    def on_properties_changed(self, interface, changed, invalidated, path=None):
        key = str(path or "")
        if key not in self.objects:
            self.objects[key] = {}
        iface_name = str(interface)
        current = dict(self.objects[key].get(iface_name, {}))
        for name, value in changed.items():
            current[str(name)] = to_python(value)
        for name in invalidated:
            current.pop(str(name), None)
        self.objects[key][iface_name] = current
        self.emit_snapshot()

    def run(self):
        self.emit_snapshot()
        self.loop.run()

    def stop(self, *_args):
        if self.loop.is_running():
            self.loop.quit()


def main():
    monitor = BluetoothMonitor()
    signal.signal(signal.SIGINT, monitor.stop)
    signal.signal(signal.SIGTERM, monitor.stop)
    try:
        monitor.run()
    except KeyboardInterrupt:
        monitor.stop()


if __name__ == "__main__":
    main()

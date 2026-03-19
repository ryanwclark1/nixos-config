"""Quickshell polkit authentication agent.

Registers as a polkit agent on the session D-Bus, receives authentication
requests from polkitd, and forwards them to the QML UI via stdout JSON lines.
Reads authentication responses from stdin.

Protocol (newline-delimited JSON):
  stdout -> QML:  {"type":"begin","cookie":"...","action_id":"...","message":"...","icon_name":"...","identities":["unix-user:admin"]}
  stdout -> QML:  {"type":"cancel","cookie":"..."}
  stdin  <- QML:  {"type":"response","cookie":"...","authenticated":true/false}
"""

import json
import os
import signal
import sys
import threading

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

AGENT_OBJECT_PATH = "/org/quickshell/PolkitAgent"
POLKIT_BUS_NAME = "org.freedesktop.PolicyKit1"
POLKIT_AUTHORITY_PATH = "/org/freedesktop/PolicyKit1/Authority"
POLKIT_AUTHORITY_IFACE = "org.freedesktop.PolicyKit1.Authority"
POLKIT_AGENT_IFACE = "org.freedesktop.PolicyKit1.AuthenticationAgent"

# Pending cookies awaiting QML response
_pending = {}  # cookie -> threading.Event
_results = {}  # cookie -> bool


def write_json(obj):
    """Write a JSON line to stdout (thread-safe)."""
    line = json.dumps(obj, separators=(",", ":"))
    try:
        sys.stdout.write(line + "\n")
        sys.stdout.flush()
    except (BrokenPipeError, OSError):
        pass


class PolkitAgent(dbus.service.Object):
    """D-Bus object implementing the polkit AuthenticationAgent interface."""

    def __init__(self, bus, loop):
        super().__init__(bus, AGENT_OBJECT_PATH)
        self._loop = loop

    @dbus.service.method(
        POLKIT_AGENT_IFACE,
        in_signature="sssssa(sa{sv})",
        out_signature="",
    )
    def BeginAuthentication(
        self, action_id, message, icon_name, details, cookie, identities
    ):
        """Called by polkitd when authentication is needed."""
        id_list = []
        for kind, identity in identities:
            if kind == "unix-user":
                uid = identity.get("uid", None)
                if uid is not None:
                    try:
                        import pwd
                        name = pwd.getpwuid(int(uid)).pw_name
                    except (KeyError, ValueError):
                        name = str(uid)
                    id_list.append(f"unix-user:{name}")
            elif kind == "unix-group":
                gid = identity.get("gid", None)
                if gid is not None:
                    id_list.append(f"unix-group:{gid}")

        write_json({
            "type": "begin",
            "cookie": str(cookie),
            "action_id": str(action_id),
            "message": str(message),
            "icon_name": str(icon_name),
            "identities": id_list,
        })

        # Block until QML responds (polkitd expects synchronous reply)
        event = threading.Event()
        _pending[str(cookie)] = event
        event.wait()

        authenticated = _results.pop(str(cookie), False)
        _pending.pop(str(cookie), None)

        if not authenticated:
            raise dbus.DBusException(
                "org.freedesktop.PolicyKit1.Error.Failed",
                "Authentication was cancelled or failed",
            )

    @dbus.service.method(
        POLKIT_AGENT_IFACE,
        in_signature="s",
        out_signature="",
    )
    def CancelAuthentication(self, cookie):
        """Called by polkitd to cancel a pending authentication."""
        cookie_str = str(cookie)
        write_json({"type": "cancel", "cookie": cookie_str})

        # Unblock any waiting BeginAuthentication call
        _results[cookie_str] = False
        event = _pending.get(cookie_str)
        if event:
            event.set()


def stdin_reader():
    """Read JSON responses from QML on stdin."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            print(f"polkit-agent: invalid JSON: {line}", file=sys.stderr)
            continue

        if msg.get("type") == "response":
            cookie = msg.get("cookie", "")
            authenticated = msg.get("authenticated", False)
            _results[cookie] = authenticated
            event = _pending.get(cookie)
            if event:
                event.set()


def register_agent(bus):
    """Register this process as a polkit authentication agent."""
    session_id = os.environ.get("XDG_SESSION_ID", "")

    authority = bus.get_object(POLKIT_BUS_NAME, POLKIT_AUTHORITY_PATH)
    authority_iface = dbus.Interface(authority, POLKIT_AUTHORITY_IFACE)

    subject = ("unix-session", {"session-id": session_id})
    authority_iface.RegisterAuthenticationAgent(
        subject, os.environ.get("LANG", "en_US.UTF-8"), AGENT_OBJECT_PATH
    )
    print("polkit-agent: registered for session", session_id, file=sys.stderr)


def unregister_agent(bus):
    """Unregister the polkit authentication agent."""
    session_id = os.environ.get("XDG_SESSION_ID", "")
    try:
        authority = bus.get_object(POLKIT_BUS_NAME, POLKIT_AUTHORITY_PATH)
        authority_iface = dbus.Interface(authority, POLKIT_AUTHORITY_IFACE)
        subject = ("unix-session", {"session-id": session_id})
        authority_iface.UnregisterAuthenticationAgent(subject, AGENT_OBJECT_PATH)
        print("polkit-agent: unregistered", file=sys.stderr)
    except dbus.DBusException:
        pass


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()
    loop = GLib.MainLoop()

    _agent = PolkitAgent(bus, loop)  # noqa: F841 — prevent GC

    register_agent(bus)

    # Read stdin in a background thread
    reader = threading.Thread(target=stdin_reader, daemon=True)
    reader.start()

    def shutdown(_sig=None, _frame=None):
        unregister_agent(bus)
        loop.quit()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    write_json({"type": "ready"})

    try:
        loop.run()
    except KeyboardInterrupt:
        shutdown()


if __name__ == "__main__":
    main()

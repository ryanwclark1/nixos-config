import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

Scope {
    id: root

    // Niri: overview state lives in the compositor, synced via event stream.
    // Hyprland: overview state is purely local.
    property bool _localVisible: false
    readonly property bool isVisible: CompositorAdapter.isNiri ? NiriService.inOverview : _localVisible

    // Niri IPC timeout: if toggleOverview doesn't close within 1.5s, force locally
    property bool _escapeRequested: false
    Timer {
        id: escapeTimeout
        interval: 1500
        onTriggered: {
            if (root.isVisible && root._escapeRequested) {
                console.warn("Overview: compositor did not close overview within timeout, forcing local close");
                root.forceClose();
            }
            root._escapeRequested = false;
        }
    }

    function requestClose() {
        if (CompositorAdapter.isNiri) {
            _escapeRequested = true;
            escapeTimeout.restart();
            CompositorAdapter.toggleOverview();
        } else {
            _localVisible = false;
        }
    }

    function forceClose() {
        escapeTimeout.stop();
        _escapeRequested = false;
        if (CompositorAdapter.isNiri)
            NiriService.inOverview = false;
        else
            _localVisible = false;
    }

    onIsVisibleChanged: {
        if (!isVisible) {
            escapeTimeout.stop();
            _escapeRequested = false;
        }
    }

    // Safety-net Escape: works even if focus falls to an unexpected item
    Shortcut {
        enabled: root.isVisible
        sequence: "Escape"
        onActivated: root.requestClose()
    }

    IpcHandler {
        target: "Overview"
        function toggle() {
            if (CompositorAdapter.isNiri)
                CompositorAdapter.toggleOverview();
            else
                root._localVisible = !root._localVisible;
        }
        function show() {
            if (!root.isVisible) toggle();
        }
        function hide() {
            if (root.isVisible) root.requestClose();
        }
        function forceClose() {
            root.forceClose();
        }
    }

    // Hyprland per-screen windows
    Variants {
        model: CompositorAdapter.isHyprland ? Quickshell.screens : []

        delegate: Component {
            LazyLoader {
                active: root.isVisible
                required property ShellScreen modelData

                OverviewWindow {
                    screen: modelData
                    isVisible: root.isVisible
                    onCloseRequested: root.requestClose()

                    OverviewHyprland {
                        anchors.fill: parent
                        onCloseRequested: root.requestClose()
                    }
                }
            }
        }
    }

    // Niri per-screen windows
    Variants {
        model: CompositorAdapter.isNiri ? Quickshell.screens : []

        delegate: Component {
            LazyLoader {
                active: root.isVisible
                required property ShellScreen modelData

                OverviewWindow {
                    id: niriWindow
                    screen: modelData
                    isVisible: root.isVisible
                    onCloseRequested: root.requestClose()

                    OverviewNiri {
                        anchors.fill: parent
                        screenName: modelData.name || ""
                        windowWidth: niriWindow.width
                        onCloseRequested: root.requestClose()
                    }
                }
            }
        }
    }
}

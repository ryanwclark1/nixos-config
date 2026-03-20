import QtQuick
import Quickshell
import Quickshell.Io
import "../services"
import "../features/launcher"

QtObject {
    id: root

    // ── Required references ────────────────────
    required property var shellRoot
    required property var launcher
    required property var osk
    required property var regionSelector
    required property var polkitAgent
    required property var overview       // may be null if compositor lacks overview
    required property var altTabSwitcher // Loader wrapping AltTabSwitcher

    // ── IPC endpoint ───────────────────────────
    property IpcHandler _handler: IpcHandler {
        target: "Shell"

        // Generic surface operations — preferred for new callers:
        //   quickshell ipc call Shell toggleSurface audioMenu
        //   quickshell ipc call Shell toggleSurface audioMenu focused
        function toggleSurface(surfaceId: string, screenName: string) {
            root._surfaceOp("toggle", surfaceId, screenName);
        }
        function openSurface(surfaceId: string, screenName: string) {
            root._surfaceOp("open", surfaceId, screenName);
        }
        function isSurfaceOpen(surfaceId: string): bool {
            return root.shellRoot.isSurfaceOpen(surfaceId);
        }
        function closeAllSurfaces() {
            root.shellRoot.closeAllSurfaces();
        }
        function closeAll() {
            root.shellRoot.closeAllSurfaces();
        }
        // Emergency escape: closes all surfaces, forces launcher closed,
        // and forces overview closed locally (bypasses Niri IPC).
        // Bind this to a compositor hotkey as a last resort:
        //   quickshell ipc call Shell panicClose
        function panicClose() {
            root.shellRoot.closeAllSurfaces();
            root.launcher.close();
            root.osk.close();
            root.regionSelector.dismiss();
            root.polkitAgent.cancel();
            if (root.overview)
                root.overview.forceClose();
            if (root.altTabSwitcher.item && root.altTabSwitcher.item.hide)
                root.altTabSwitcher.item.hide();
        }
        function reloadConfig() {
            Config.load();
        }
        function showAltTab() {
            if (root.altTabSwitcher.item && root.altTabSwitcher.item.show)
                root.altTabSwitcher.item.show();
        }
    }

    // ── Screen-targeted dispatch (Phase 1.3) ───
    // Resolves screenName to a context object and delegates to SurfaceService.
    // screenName can be:
    //   - omitted / ""    → no context (current behavior)
    //   - "focused"       → resolve to the currently focused screen
    //   - a screen name   → target that specific screen
    function _surfaceOp(op, surfaceId, screenName) {
        var context = undefined;
        if (screenName && screenName !== "") {
            var resolvedScreen = screenName;
            if (screenName === "focused") {
                resolvedScreen = CompositorAdapter.focusedScreenName || "";
            }
            if (resolvedScreen !== "") {
                context = { screenName: resolvedScreen };
            }
        }
        if (op === "toggle")
            root.shellRoot.toggleSurface(surfaceId, context);
        else
            root.shellRoot.openSurface(surfaceId, context);
    }
}

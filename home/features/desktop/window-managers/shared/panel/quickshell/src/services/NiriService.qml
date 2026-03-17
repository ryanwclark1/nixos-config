pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Full Niri IPC client providing reactive, event-driven state for workspaces,
// windows, outputs, overview, and keyboard layouts.  Connects to $NIRI_SOCKET
// via two persistent Unix sockets: one for the EventStream and one for sending
// actions/requests.  Eliminates polling for all Niri state.
//
// Integration: CompositorAdapter delegates to this service when isNiri is true.
// Consumers should prefer CompositorAdapter's capability-flagged API.
QtObject {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") || ""
    readonly property bool available: socketPath !== ""

    // ── Workspace state ─────────────────────────────
    property var workspaces: ({})          // id → workspace object
    property var allWorkspaces: []         // sorted array
    property int focusedWorkspaceIndex: 0
    property string focusedWorkspaceId: ""
    property var currentOutputWorkspaces: []
    property string currentOutput: ""

    // ── Window state ────────────────────────────────
    property var windows: []               // sorted by layout position
    property var mruWindowIds: []          // most-recently-used order
    property var activeWindow: null        // currently focused window

    // ── Output state ────────────────────────────────
    property var outputs: ({})             // name → output object
    property var displayScales: ({})       // name → scale

    // ── Overview ────────────────────────────────────
    property bool inOverview: false

    // ── Keyboard layouts ────────────────────────────
    property int currentKeyboardLayoutIndex: 0
    property var keyboardLayoutNames: []

    // ── Config load status ──────────────────────────
    property bool configLoaded: false
    property bool configLoadFailed: false
    property string configError: ""

    // ── Signals ─────────────────────────────────────
    signal windowUrgentChanged()
    signal configLoadFinished(bool ok, string error)
    signal workspacesUpdated()
    signal windowsUpdated()

    // ── Batching for window updates ─────────────────
    property bool _windowsDirty: false
    property var _pendingWindows: []

    // ── Event stream socket ─────────────────────────
    property NiriSocket _eventSocket: NiriSocket {
        path: root.socketPath
        connected: root.available

        onConnectionStateChanged: {
            if (socketConnected) {
                send('"EventStream"')
                root._fetchOutputs()
            }
        }

        parser: SplitParser {
            onRead: line => {
                try {
                    const event = JSON.parse(line)
                    root._handleEvent(event)
                } catch (e) {
                    console.warn("[NiriService] Failed to parse event:", e)
                }
            }
        }
    }

    // ── Request socket (for sending actions) ────────
    property NiriSocket _requestSocket: NiriSocket {
        path: root.socketPath
        connected: root.available
    }

    // ── Output fetcher (one-shot via Process) ───────
    property Process _fetchOutputsProc: Process {
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text)
                    root.outputs = data
                    root._updateDisplayScales()
                    if (root.windows.length > 0)
                        root.windows = root._sortWindowsByLayout(root.windows)
                } catch (e) {
                    console.warn("[NiriService] Failed to parse outputs:", e)
                }
            }
        }
    }

    property Timer _fetchOutputsDebounce: Timer {
        interval: 200
        onTriggered: {
            if (root.available)
                root._fetchOutputsProc.running = true
        }
    }

    property Timer _windowsUpdateTimer: Timer {
        interval: 50
        repeat: false
        onTriggered: {
            if (root._windowsDirty) {
                root.windows = root._sortWindowsByLayout(root._pendingWindows)
                root._windowsDirty = false
                root.windowsUpdated()
            }
        }
    }

    Component.onCompleted: {
        if (available) _fetchOutputs()
    }

    // ═══════════════════════════════════════════════
    //  Public API — Actions
    // ═══════════════════════════════════════════════

    function send(request) {
        if (!available || !_requestSocket.socketConnected)
            return false
        _requestSocket.send(request)
        return true
    }

    // ── Workspace navigation ────────────────────────
    function focusWorkspace(index) {
        const targetIndex = parseInt(index, 10)
        if (!isNaN(targetIndex))
            _optimisticallyFocusWorkspace(targetIndex)
        return send({ "Action": { "FocusWorkspace": { "reference": { "Index": index } } } })
    }
    function focusWorkspaceRelative(step) {
        const source = currentOutputWorkspaces.length > 0 ? currentOutputWorkspaces : allWorkspaces
        if (!source || source.length === 0)
            return false

        let focusedPos = source.findIndex(ws => !!ws.is_focused)
        if (focusedPos < 0 && focusedWorkspaceId !== "")
            focusedPos = source.findIndex(ws => String(ws.id) === String(focusedWorkspaceId))
        if (focusedPos < 0)
            focusedPos = 0

        const targetPos = Math.max(0, Math.min(source.length - 1, focusedPos + step))
        const target = source[targetPos]
        if (!target)
            return false

        const targetIndex = target.idx !== undefined ? target.idx : parseInt(target.id, 10)
        if (isNaN(targetIndex))
            return false
        return focusWorkspace(targetIndex)
    }
    function focusWorkspaceUp() {
        return send({ "Action": { "FocusWorkspaceUp": {} } })
    }
    function focusWorkspaceDown() {
        return send({ "Action": { "FocusWorkspaceDown": {} } })
    }
    function focusWorkspacePrevious() {
        return send({ "Action": { "FocusWorkspacePrevious": {} } })
    }

    // ── Window focus ────────────────────────────────
    function focusWindow(windowId) {
        return send({ "Action": { "FocusWindow": { "id": windowId } } })
    }
    function focusColumnLeft() {
        return send({ "Action": { "FocusColumnLeft": {} } })
    }
    function focusColumnRight() {
        return send({ "Action": { "FocusColumnRight": {} } })
    }
    function focusColumnFirst() {
        return send({ "Action": { "FocusColumnFirst": {} } })
    }
    function focusColumnLast() {
        return send({ "Action": { "FocusColumnLast": {} } })
    }
    function focusWindowUp() {
        return send({ "Action": { "FocusWindowUp": {} } })
    }
    function focusWindowDown() {
        return send({ "Action": { "FocusWindowDown": {} } })
    }

    // ── Window actions ──────────────────────────────
    function closeWindow(windowId) {
        return send({ "Action": { "CloseWindow": { "id": windowId } } })
    }
    function fullscreenWindow() {
        return send({ "Action": { "FullscreenWindow": {} } })
    }
    function toggleWindowFloating() {
        return send({ "Action": { "ToggleWindowFloating": {} } })
    }
    function maximizeColumn() {
        return send({ "Action": { "MaximizeColumn": {} } })
    }
    function centerColumn() {
        return send({ "Action": { "CenterColumn": {} } })
    }

    // ── Window movement ─────────────────────────────
    function moveColumnLeft() {
        return send({ "Action": { "MoveColumnLeft": {} } })
    }
    function moveColumnRight() {
        return send({ "Action": { "MoveColumnRight": {} } })
    }
    function moveColumnToFirst() {
        return send({ "Action": { "MoveColumnToFirst": {} } })
    }
    function moveColumnToLast() {
        return send({ "Action": { "MoveColumnToLast": {} } })
    }
    function moveColumnToWorkspace(index) {
        return send({ "Action": { "MoveColumnToWorkspace": { "reference": { "Index": index } } } })
    }
    function moveWindowUp() {
        return send({ "Action": { "MoveWindowUp": {} } })
    }
    function moveWindowDown() {
        return send({ "Action": { "MoveWindowDown": {} } })
    }
    function moveWindowToWorkspace(windowId, workspaceIndex, focus) {
        send({ "Action": { "FocusWindow": { "id": windowId } } })
        return send({
            "Action": {
                "MoveWindowToWorkspace": {
                    "window_id": null,
                    "reference": { "Index": workspaceIndex },
                    "focus": focus === undefined ? false : focus
                }
            }
        })
    }

    // ── Column operations ───────────────────────────
    function consumeWindowIntoColumn() {
        return send({ "Action": { "ConsumeWindowIntoColumn": {} } })
    }
    function expelWindowFromColumn() {
        return send({ "Action": { "ExpelWindowFromColumn": {} } })
    }
    function consumeOrExpelWindowLeft() {
        return send({ "Action": { "ConsumeOrExpelWindowLeft": {} } })
    }
    function consumeOrExpelWindowRight() {
        return send({ "Action": { "ConsumeOrExpelWindowRight": {} } })
    }

    // ── Sizing ──────────────────────────────────────
    function setColumnWidth(change) {
        return send({ "Action": { "SetColumnWidth": change } })
    }
    function setWindowHeight(change) {
        return send({ "Action": { "SetWindowHeight": change } })
    }
    function switchPresetColumnWidth() {
        return send({ "Action": { "SwitchPresetColumnWidth": {} } })
    }

    // ── Overview ────────────────────────────────────
    function toggleOverview() {
        return send({ "Action": { "ToggleOverview": {} } })
    }

    // ── Monitor focus ───────────────────────────────
    function focusMonitorLeft() {
        return send({ "Action": { "FocusMonitorLeft": {} } })
    }
    function focusMonitorRight() {
        return send({ "Action": { "FocusMonitorRight": {} } })
    }

    // ── Move to monitor ─────────────────────────────
    function moveWindowToMonitorLeft() {
        return send({ "Action": { "MoveWindowToMonitorLeft": {} } })
    }
    function moveWindowToMonitorRight() {
        return send({ "Action": { "MoveWindowToMonitorRight": {} } })
    }
    function moveColumnToMonitorLeft() {
        return send({ "Action": { "MoveColumnToMonitorLeft": {} } })
    }
    function moveColumnToMonitorRight() {
        return send({ "Action": { "MoveColumnToMonitorRight": {} } })
    }

    // ── Workspace management ────────────────────────
    function moveWorkspaceUp() {
        return send({ "Action": { "MoveWorkspaceUp": {} } })
    }
    function moveWorkspaceDown() {
        return send({ "Action": { "MoveWorkspaceDown": {} } })
    }

    // ── Screenshots ─────────────────────────────────
    function screenshot() {
        return send({ "Action": { "Screenshot": {} } })
    }
    function screenshotScreen() {
        return send({ "Action": { "ScreenshotScreen": {} } })
    }
    function screenshotWindow() {
        return send({ "Action": { "ScreenshotWindow": {} } })
    }

    // ── Spawn ───────────────────────────────────────
    function spawn(args) {
        return send({ "Action": { "Spawn": { "command": args } } })
    }

    // ── Keyboard ────────────────────────────────────
    function switchLayout() {
        return send({ "Action": { "SwitchLayout": { "layout": "Next" } } })
    }

    // ── Power ───────────────────────────────────────
    function powerOffMonitors() {
        return send({ "Action": { "PowerOffMonitors": {} } })
    }
    function quit() {
        return send({ "Action": { "Quit": { "skip_confirmation": true } } })
    }

    // ═══════════════════════════════════════════════
    //  Public API — Queries
    // ═══════════════════════════════════════════════

    function getCurrentKeyboardLayoutName() {
        if (currentKeyboardLayoutIndex >= 0
            && currentKeyboardLayoutIndex < keyboardLayoutNames.length)
            return keyboardLayoutNames[currentKeyboardLayoutIndex]
        return ""
    }

    function findWindowByAppId(pattern) {
        const p = (pattern || "").toLowerCase()
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].app_id && windows[i].app_id.toLowerCase().indexOf(p) !== -1)
                return windows[i]
        }
        return null
    }

    function findWindowByTitle(pattern) {
        const p = (pattern || "").toLowerCase()
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].title && windows[i].title.toLowerCase().indexOf(p) !== -1)
                return windows[i]
        }
        return null
    }

    // ═══════════════════════════════════════════════
    //  Internal — Event Dispatch
    // ═══════════════════════════════════════════════

    function _fetchOutputs() {
        if (!available) return
        _fetchOutputsDebounce.restart()
    }

    function _updateDisplayScales() {
        if (!outputs || Object.keys(outputs).length === 0) return
        const scales = {}
        for (const name in outputs) {
            const o = outputs[name]
            if (o.logical && o.logical.scale !== undefined)
                scales[name] = o.logical.scale
        }
        displayScales = scales
    }

    function _sortWindowsByLayout(windowList) {
        const enriched = windowList.map(w => {
            const ws = workspaces[w.workspace_id]
            if (!ws) return { window: w, outputX: 999999, outputY: 999999, wsIdx: 999999, col: 999999, row: 999999 }

            const outputInfo = outputs[ws.output]
            const outputX = (outputInfo && outputInfo.logical) ? outputInfo.logical.x : 999999
            const outputY = (outputInfo && outputInfo.logical) ? outputInfo.logical.y : 999999

            const pos = w.layout?.pos_in_scrolling_layout
            const col = (pos && pos.length >= 2) ? pos[0] : 999999
            const row = (pos && pos.length >= 2) ? pos[1] : 999999

            return { window: w, outputX, outputY, wsIdx: ws.idx, col, row }
        })

        enriched.sort((a, b) => {
            if (a.outputX !== b.outputX) return a.outputX - b.outputX
            if (a.outputY !== b.outputY) return a.outputY - b.outputY
            if (a.wsIdx !== b.wsIdx) return a.wsIdx - b.wsIdx
            if (a.col !== b.col) return a.col - b.col
            if (a.row !== b.row) return a.row - b.row
            return a.window.id - b.window.id
        })

        return enriched.map(e => e.window)
    }

    function _scheduleWindowsUpdate(newList) {
        _pendingWindows = newList
        _windowsDirty = true
        if (!_windowsUpdateTimer.running)
            _windowsUpdateTimer.restart()
    }

    function _handleEvent(event) {
        const type = Object.keys(event)[0]

        switch (type) {
        case "WorkspacesChanged":
            _onWorkspacesChanged(event.WorkspacesChanged); break
        case "WorkspaceActivated":
            _onWorkspaceActivated(event.WorkspaceActivated); break
        case "WorkspaceActiveWindowChanged":
            _onWorkspaceActiveWindowChanged(event.WorkspaceActiveWindowChanged); break
        case "WorkspaceUrgencyChanged":
            _onWorkspaceUrgencyChanged(event.WorkspaceUrgencyChanged); break
        case "WindowsChanged":
            _onWindowsChanged(event.WindowsChanged); break
        case "WindowOpenedOrChanged":
            _onWindowOpenedOrChanged(event.WindowOpenedOrChanged); break
        case "WindowClosed":
            _onWindowClosed(event.WindowClosed); break
        case "WindowFocusChanged":
            _onWindowFocusChanged(event.WindowFocusChanged); break
        case "WindowLayoutsChanged":
            _onWindowLayoutsChanged(event.WindowLayoutsChanged); break
        case "OutputsChanged":
            _onOutputsChanged(event.OutputsChanged); break
        case "OverviewOpenedOrClosed":
            inOverview = event.OverviewOpenedOrClosed.is_open; break
        case "ConfigLoaded":
            _onConfigLoaded(event.ConfigLoaded); break
        case "KeyboardLayoutsChanged":
            _onKeyboardLayoutsChanged(event.KeyboardLayoutsChanged); break
        case "KeyboardLayoutSwitched":
            currentKeyboardLayoutIndex = event.KeyboardLayoutSwitched.idx; break
        }
    }

    // ── Workspace events ────────────────────────────

    function _onWorkspacesChanged(data) {
        const newWs = {}
        for (const ws of data.workspaces) {
            const old = root.workspaces[ws.id]
            newWs[ws.id] = ws
            if (old && old.active_window_id !== undefined)
                newWs[ws.id].active_window_id = old.active_window_id
        }
        root.workspaces = newWs
        _rebuildWorkspaceArrays(newWs)
    }

    function _onWorkspaceActivated(data) {
        const ws = root.workspaces[data.id]
        if (!ws) return
        const output = ws.output

        const updated = {}
        let changed = false
        for (const id in root.workspaces) {
            const w = root.workspaces[id]
            const gotActivated = (w.id === data.id)
            const needsUpdate = (w.output === output) || (data.focused && gotActivated)

            if (!needsUpdate) { updated[id] = w; continue }

            const copy = _shallowCopy(w)
            if (w.output === output) copy.is_active = gotActivated
            if (data.focused) copy.is_focused = gotActivated
            updated[id] = copy
            changed = true
        }
        if (!changed) return
        root.workspaces = updated
        _rebuildWorkspaceArrays(updated)
    }

    function _onWorkspaceActiveWindowChanged(data) {
        const ws = root.workspaces[data.workspace_id]
        if (ws) {
            const copy = _shallowCopy(ws)
            copy.active_window_id = data.active_window_id
            const updated = _shallowCopy(root.workspaces)
            updated[data.workspace_id] = copy
            root.workspaces = updated
        }

        // Update focus state on windows
        const updatedWindows = []
        let hasChanges = false
        let newActive = null

        for (var i = 0; i < windows.length; i++) {
            const w = windows[i]
            let shouldBeFocused
            if (data.active_window_id !== null && data.active_window_id !== undefined)
                shouldBeFocused = (w.id == data.active_window_id)
            else
                shouldBeFocused = w.workspace_id == data.workspace_id ? false : w.is_focused

            if (w.is_focused === shouldBeFocused) {
                updatedWindows.push(w)
                if (shouldBeFocused) newActive = w
            } else {
                const copy = _shallowCopy(w)
                copy.is_focused = shouldBeFocused
                updatedWindows.push(copy)
                if (shouldBeFocused) newActive = copy
                hasChanges = true
            }
        }
        if (hasChanges) windows = updatedWindows
        if (activeWindow !== newActive) activeWindow = newActive
    }

    function _onWorkspaceUrgencyChanged(data) {
        const ws = root.workspaces[data.id]
        if (!ws) return
        const copy = _shallowCopy(ws)
        copy.is_urgent = data.urgent
        const updated = _shallowCopy(root.workspaces)
        updated[data.id] = copy
        root.workspaces = updated
        allWorkspaces = Object.values(updated).sort((a, b) => a.idx - b.idx)
        windowUrgentChanged()
    }

    // ── Window events ───────────────────────────────

    function _onWindowsChanged(data) {
        _scheduleWindowsUpdate(data.windows)
    }

    function _onWindowOpenedOrChanged(data) {
        if (!data.window) return
        const w = data.window
        const currentList = _windowsDirty ? _pendingWindows : windows
        const idx = currentList.findIndex(x => x.id === w.id)
        let updated
        if (idx >= 0) {
            updated = [...currentList]
            updated[idx] = w
        } else {
            updated = [...currentList, w]
        }
        _scheduleWindowsUpdate(updated)
    }

    function _onWindowClosed(data) {
        const currentList = _windowsDirty ? _pendingWindows : windows
        _scheduleWindowsUpdate(currentList.filter(w => w.id !== data.id))
        if (mruWindowIds.length > 0)
            mruWindowIds = mruWindowIds.filter(id => id !== data.id)
    }

    function _onWindowFocusChanged(data) {
        const focusedId = data.id

        // Update MRU list
        if (focusedId !== null && focusedId !== undefined) {
            const newOrder = mruWindowIds.filter(id => id !== focusedId)
            newOrder.unshift(focusedId)
            mruWindowIds = newOrder
        }

        // Update focus flags on windows
        const updatedWindows = []
        let hasChanges = false
        let focusedWindow = null

        for (var i = 0; i < windows.length; i++) {
            const w = windows[i]
            const shouldBeFocused = (w.id === focusedId)
            if (w.is_focused === shouldBeFocused) {
                updatedWindows.push(w)
                if (shouldBeFocused) focusedWindow = w
            } else {
                const copy = _shallowCopy(w)
                copy.is_focused = shouldBeFocused
                if (shouldBeFocused) focusedWindow = copy
                updatedWindows.push(copy)
                hasChanges = true
            }
        }
        if (hasChanges) windows = updatedWindows
        if (activeWindow !== focusedWindow) activeWindow = focusedWindow

        // Also track on workspace
        if (focusedWindow) {
            const ws = root.workspaces[focusedWindow.workspace_id]
            if (ws && ws.active_window_id !== focusedId) {
                const wsCopy = _shallowCopy(ws)
                wsCopy.active_window_id = focusedId
                const updated = _shallowCopy(root.workspaces)
                updated[focusedWindow.workspace_id] = wsCopy
                root.workspaces = updated
            }
        }
    }

    function _onWindowLayoutsChanged(data) {
        if (!data.changes) return
        const currentList = _windowsDirty ? _pendingWindows : windows
        const updated = [...currentList]
        let hasChanges = false

        for (const change of data.changes) {
            const windowId = change[0]
            const layoutData = change[1]
            const idx = updated.findIndex(w => w.id === windowId)
            if (idx < 0) continue
            const copy = _shallowCopy(updated[idx])
            copy.layout = layoutData
            updated[idx] = copy
            hasChanges = true
        }
        if (hasChanges) _scheduleWindowsUpdate(updated)
    }

    // ── Output events ───────────────────────────────

    function _onOutputsChanged(data) {
        if (!data.outputs) return
        outputs = data.outputs
        _updateDisplayScales()
        windows = _sortWindowsByLayout(windows)
    }

    // ── Config events ───────────────────────────────

    function _onConfigLoaded(data) {
        const failed = data && data.failed
        configLoaded = !failed
        configLoadFailed = !!failed
        configError = (failed && data.error) ? data.error : ""
        if (!failed) _fetchOutputs()
        configLoadFinished(!failed, configError)
    }

    // ── Keyboard events ─────────────────────────────

    function _onKeyboardLayoutsChanged(data) {
        keyboardLayoutNames = data.keyboard_layouts.names
        currentKeyboardLayoutIndex = data.keyboard_layouts.current_idx
    }

    // ── Helpers ─────────────────────────────────────

    function _rebuildWorkspaceArrays(wsMap) {
        const sorted = Object.values(wsMap).sort((a, b) => a.idx - b.idx)
        allWorkspaces = sorted

        const focusedIdx = sorted.findIndex(w => w.is_focused)
        if (focusedIdx >= 0) {
            focusedWorkspaceIndex = focusedIdx
            focusedWorkspaceId = sorted[focusedIdx].id
            currentOutput = sorted[focusedIdx].output || ""
        } else {
            focusedWorkspaceIndex = 0
            focusedWorkspaceId = ""
        }

        _updateCurrentOutputWorkspaces()
        workspacesUpdated()
    }

    function _updateCurrentOutputWorkspaces() {
        if (!currentOutput) {
            currentOutputWorkspaces = allWorkspaces
            return
        }
        currentOutputWorkspaces = allWorkspaces.filter(w => w.output === currentOutput)
    }

    function _optimisticallyFocusWorkspace(targetIndex) {
        const target = allWorkspaces.find(ws => ws && ws.idx === targetIndex)
        if (!target)
            return

        const targetOutput = String(target.output || currentOutput || "")
        const updated = {}
        let changed = false

        for (const id in root.workspaces) {
            const workspace = root.workspaces[id]
            if (!workspace) {
                updated[id] = workspace
                continue
            }

            const shouldFocus = workspace.idx === targetIndex
            let shouldBeActive = !!workspace.is_active
            const workspaceOutput = String(workspace.output || "")

            if (targetOutput !== "" && workspaceOutput === targetOutput)
                shouldBeActive = shouldFocus
            else if (targetOutput === "" && (workspace.is_focused || shouldFocus))
                shouldBeActive = shouldFocus

            if (workspace.is_focused === shouldFocus && workspace.is_active === shouldBeActive) {
                updated[id] = workspace
                continue
            }

            const copy = _shallowCopy(workspace)
            copy.is_focused = shouldFocus
            copy.is_active = shouldBeActive
            updated[id] = copy
            changed = true
        }

        if (!changed)
            return

        root.workspaces = updated
        _rebuildWorkspaceArrays(updated)
    }

    function _shallowCopy(obj) {
        const copy = {}
        for (var prop in obj)
            copy[prop] = obj[prop]
        return copy
    }
}

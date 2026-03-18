import QtQuick
import Quickshell
import Quickshell.Io
import "../../../services"
import ".."

Item {
    id: root
    anchors.fill: parent

    readonly property string screenName: parent ? (parent.screen ? parent.screen.name : "") : ""
    property string widgetSearchQuery: ""
    property bool widgetPickerOpen: false
    readonly property var screenRef: parent && parent.screen ? parent.screen : null
    readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
    readonly property real safeDragMinX: edgeMargins.left + 8 - x
    readonly property real safeDragMinY: edgeMargins.top + 8 - y
    readonly property real safeSpawnX: Math.max(100, edgeMargins.left + 24 - x)
    readonly property real safeSpawnY: Math.max(100, edgeMargins.top + 24 - y)
    readonly property var availableDesktopWidgets: DesktopWidgetRegistry.search(widgetSearchQuery)

    visible: Config.desktopWidgetsEnabled || DesktopWidgetRegistry.editMode

    // Get widgets for this screen from config
    property var screenWidgets: DesktopWidgetRegistry.getWidgetsForScreen(screenName)
    onScreenNameChanged: screenWidgets = DesktopWidgetRegistry.getWidgetsForScreen(screenName)

    // Refresh when config changes
    Connections {
        target: Config
        function onDesktopWidgetsMonitorWidgetsChanged() {
            root.screenWidgets = DesktopWidgetRegistry.getWidgetsForScreen(root.screenName);
        }
    }

    IpcHandler {
        target: "DesktopWidgets"
        function toggleEditMode() {
            DesktopWidgetRegistry.editMode = !DesktopWidgetRegistry.editMode;
        }
    }

    // Grid overlay (only in edit mode with grid snap)
    Canvas {
        anchors.fill: parent
        visible: DesktopWidgetRegistry.editMode && Config.desktopWidgetsGridSnap
        opacity: 0.08
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = Colors.text;
            ctx.lineWidth = 1;
            var gridSize = 20;
            for (var x = 0; x < width; x += gridSize) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
                ctx.stroke();
            }
            for (var y = 0; y < height; y += gridSize) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
        }
    }

    // Widget instances
    Repeater {
        model: root.screenWidgets

        delegate: DraggableDesktopWidget {
            required property var modelData
            required property int index

            widgetId: modelData.id || ""
            widgetType: modelData.type || ""
            readonly property var widgetMeta: DesktopWidgetRegistry.metadataForWidgetType(widgetType)
            screenName: root.screenName
            minimumX: root.safeDragMinX
            minimumY: root.safeDragMinY
            maximumX: root.parent ? Math.max(root.safeDragMinX, root.parent.width - root.edgeMargins.right - 8 - root.x - width) : x
            maximumY: root.parent ? Math.max(root.safeDragMinY, root.parent.height - root.edgeMargins.bottom - 8 - root.y - height) : y
            x: modelData.x || 0
            y: modelData.y || 0
            widgetScale: modelData.scale || 1.0

            // Load the appropriate widget component based on type
            Loader {
                id: widgetLoader
                active: true
                source: widgetMeta && widgetMeta.componentSource ? widgetMeta.componentSource : ""
                sourceComponent: source === "" ? placeholderComponent : undefined
                onStatusChanged: {
                    if (status !== Loader.Ready || !item)
                        return;
                    var plugin = widgetMeta && widgetMeta.source === "plugin" ? DesktopWidgetRegistry.pluginForWidgetType(widgetType) : null;
                    if (!plugin)
                        return;
                    var api = PluginService.getPluginAPI(plugin.id);
                    if (api && item.hasOwnProperty("pluginApi"))
                        item.pluginApi = api;
                    if (item.hasOwnProperty("pluginManifest"))
                        item.pluginManifest = plugin;
                    if (item.hasOwnProperty("pluginService"))
                        item.pluginService = PluginService;
                }
            }
        }
    }

    DesktopEditBar {
        editMode: DesktopWidgetRegistry.editMode
        gridSnap: Config.desktopWidgetsGridSnap
        edgeMargins: root.edgeMargins
        onAddWidgetRequested: {
            root.widgetSearchQuery = "";
            root.widgetPickerOpen = true;
        }
        onToggleGridSnap: Config.desktopWidgetsGridSnap = !Config.desktopWidgetsGridSnap
        onExitEditMode: DesktopWidgetRegistry.editMode = false
    }

    DesktopWidgetPicker {
        anchors.fill: parent
        z: 20
        pickerOpen: root.widgetPickerOpen
        availableWidgets: root.availableDesktopWidgets
        searchQuery: root.widgetSearchQuery
        screenName: root.screenName
        spawnX: root.safeSpawnX
        spawnY: root.safeSpawnY
        onClosed: root.widgetPickerOpen = false
        onSearchChanged: (query) => root.widgetSearchQuery = query
    }

    Component {
        id: placeholderComponent
        Rectangle {
            width: 120
            height: 60
            radius: Colors.radiusSmall
            color: Colors.cardSurface
            border.color: Colors.border
            Text {
                anchors.centerIn: parent
                text: "Unknown Widget"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeSmall
            }
        }
    }
}

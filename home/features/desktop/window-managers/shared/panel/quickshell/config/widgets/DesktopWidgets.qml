import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root
    anchors.fill: parent

    property string screenName: parent ? (parent.screen ? parent.screen.name : "") : ""
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

    // Edit mode controls panel
    Rectangle {
        visible: DesktopWidgetRegistry.editMode
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: edgeMargins.bottom + 20
        width: editRow.implicitWidth + 40
        height: 48
        radius: 24
        color: Colors.bgGlass
        border.color: Colors.primary
        border.width: 2

        RowLayout {
            id: editRow
            anchors.centerIn: parent
            spacing: Colors.spacingL

            // Add Widget button
            Item {
                Layout.preferredWidth: addRow.implicitWidth
                Layout.preferredHeight: 32

                RowLayout {
                    id: addRow
                    anchors.centerIn: parent
                    spacing: Colors.spacingSM

                    Text {
                        text: "󰐕"
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeLarge
                    }
                    Text {
                        text: "Add Widget"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.widgetSearchQuery = "";
                        root.widgetPickerOpen = true;
                    }
                }
            }

            // Separator
            Rectangle {
                width: 1
                height: 24
                color: Colors.border
            }

            // Grid Snap toggle
            Rectangle {
                Layout.preferredWidth: snapRow.implicitWidth + 16
                Layout.preferredHeight: 28
                radius: Colors.radiusMedium
                color: Config.desktopWidgetsGridSnap ? Colors.withAlpha(Colors.primary, 0.2) : "transparent"
                border.color: Config.desktopWidgetsGridSnap ? Colors.primary : Colors.border
                border.width: 1

                RowLayout {
                    id: snapRow
                    anchors.centerIn: parent
                    spacing: Colors.spacingXS
                    Text {
                        text: "󰕰"
                        color: Colors.text
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                    }
                    Text {
                        text: "Grid"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.desktopWidgetsGridSnap = !Config.desktopWidgetsGridSnap
                }
            }

            // Separator
            Rectangle {
                width: 1
                height: 24
                color: Colors.border
            }

            // Exit Edit Mode
            Rectangle {
                Layout.preferredWidth: exitRow.implicitWidth + 16
                Layout.preferredHeight: 28
                radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.error, 0.15)
                border.color: Colors.error
                border.width: 1

                RowLayout {
                    id: exitRow
                    anchors.centerIn: parent
                    spacing: Colors.spacingXS
                    Text {
                        text: "󰅖"
                        color: Colors.error
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                    }
                    Text {
                        text: "Done"
                        color: Colors.error
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: DesktopWidgetRegistry.editMode = false
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.widgetPickerOpen
        color: Qt.rgba(0, 0, 0, 0.45)
        z: 20

        MouseArea {
            anchors.fill: parent
            onClicked: root.widgetPickerOpen = false
        }

        Rectangle {
            width: Math.min(640, parent.width - 80)
            height: Math.min(560, parent.height - 80)
            anchors.centerIn: parent
            radius: Colors.radiusLarge
            color: Colors.popupSurface
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingLarge
                spacing: Colors.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        Layout.fillWidth: true
                        text: "Add Desktop Widget"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeXL
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        implicitWidth: closePickerLabel.implicitWidth + Colors.spacingM * 2
                        implicitHeight: 32
                        radius: Colors.radiusMedium
                        color: Colors.withAlpha(Colors.surface, 0.4)
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            id: closePickerLabel
                            anchors.centerIn: parent
                            text: "Close"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.widgetPickerOpen = false
                        }
                    }
                }

                SearchBar {
                    Layout.fillWidth: true
                    placeholder: "Search desktop widgets"
                    text: root.widgetSearchQuery
                    onTextChanged: root.widgetSearchQuery = text
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: widgetPickerColumn.implicitHeight

                    Column {
                        id: widgetPickerColumn
                        width: parent.width
                        spacing: Colors.spacingS

                        Repeater {
                            model: root.availableDesktopWidgets

                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: desktopWidgetInfo.implicitHeight + Colors.spacingM * 2
                                radius: Colors.radiusSmall
                                color: desktopWidgetAddArea.containsMouse ? Colors.highlight : Colors.withAlpha(Colors.surface, 0.4)
                                border.color: desktopWidgetAddArea.containsMouse ? Colors.primary : Colors.border
                                border.width: 1

                                RowLayout {
                                    id: desktopWidgetInfo
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingM
                                    spacing: Colors.spacingM

                                    Text {
                                        text: modelData.icon || "󰖲"
                                        color: Colors.primary
                                        font.family: Colors.fontMono
                                        font.pixelSize: Colors.fontSizeLarge
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingXXS

                                        Text {
                                            text: modelData.name
                                            color: Colors.text
                                            font.pixelSize: Colors.fontSizeMedium
                                            font.weight: Font.Medium
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }

                                        Text {
                                            text: String(modelData.source || "") === "plugin" ? "Plugin widget" : "Built-in widget"
                                            color: Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeXS
                                        }
                                    }
                                }

                                MouseArea {
                                    id: desktopWidgetAddArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        DesktopWidgetRegistry.addWidgetAt(root.screenName, modelData.id, root.safeSpawnX, root.safeSpawnY);
                                        root.widgetPickerOpen = false;
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.availableDesktopWidgets.length === 0
                            text: "No desktop widgets match \"" + root.widgetSearchQuery + "\"."
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    Component {
        id: placeholderComponent
        Rectangle {
            width: 120
            height: 60
            radius: Colors.radiusSmall
            color: Colors.withAlpha(Colors.surface, 0.5)
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

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../services"
import "../../../../services/ShellUtils.js" as ShellUtils
import "../../../../shared"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property bool _destroyed: false
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property string _pluginDiagnosticsExportText: ""
    property string _pluginDiagnosticsSavePath: ""
    property bool pluginPaneOpen: false
    property string pluginPaneMode: ""
    property string selectedPluginId: ""
    property string pluginPaneError: ""

    readonly property var selectedPlugin: PluginService.pluginById(selectedPluginId)
    readonly property bool selectedPluginHasSettings: selectedPluginId !== "" && PluginService.pluginSupportsSettings(selectedPluginId)
    readonly property bool selectedPluginCanWriteSettings: selectedPluginId !== "" && PluginService.pluginCanWriteSettings(selectedPluginId)
    readonly property bool selectedPluginHasControlCenterDetail: selectedPluginId !== "" && PluginService.pluginSupportsControlCenterDetail(selectedPluginId)
    readonly property int pluginCount: (PluginService.plugins || []).length
    readonly property int enabledPluginCount: (PluginService.plugins || []).filter(function (p) {
        return !!(p && p.enabled);
    }).length
    readonly property int invalidManifestCount: root.pluginErrorEntries().length

    Component.onDestruction: _destroyed = true

    onPluginPaneOpenChanged: {
        if (!pluginPaneOpen) {
            pluginPaneMode = "";
            selectedPluginId = "";
            pluginPaneError = "";
            if (pluginPaneOverlay.pluginPaneLoader)
                pluginPaneOverlay.pluginPaneLoader.source = "";
            return;
        }
        Qt.callLater(function() { if (_destroyed) return; loadPluginPane(); });
    }

    function diagnosticsTimestamp() {
        var now = new Date();
        function pad(n) {
            var value = String(n);
            return value.length < 2 ? ("0" + value) : value;
        }
        return now.getUTCFullYear() + pad(now.getUTCMonth() + 1) + pad(now.getUTCDate()) + "T" + pad(now.getUTCHours()) + pad(now.getUTCMinutes()) + pad(now.getUTCSeconds()) + "Z";
    }

    function diagnosticsOutputDir() {
        var home = Quickshell.env("HOME") || "/home";
        return home + "/.local/state/quickshell/plugin-diagnostics";
    }

    function pluginDiagnosticsOutputPath() {
        return diagnosticsOutputDir() + "/plugin-diagnostics-" + diagnosticsTimestamp() + ".json";
    }

    function pluginErrorEntries() {
        var map = PluginService.pluginErrors || ({});
        var entries = [];
        for (var key in map) {
            var raw = map[key];
            var code = "";
            var message = "";
            if (raw && typeof raw === "object") {
                code = String(raw.code || "");
                message = String(raw.message || "");
            } else {
                message = String(raw || "");
            }
            entries.push({
                id: key,
                code: code,
                error: message
            });
        }
        entries.sort(function (a, b) {
            return String(a.id).localeCompare(String(b.id));
        });
        return entries;
    }

    function pluginStatusSummary() {
        var map = PluginService.pluginStatuses || ({});
        var summary = {
            active: 0,
            enabled: 0,
            degraded: 0,
            failed: 0,
            disabled: 0,
            validated: 0,
            discovered: 0,
            unknown: 0
        };
        for (var key in map) {
            var state = String(map[key] && map[key].state ? map[key].state : "unknown");
            if (summary[state] === undefined)
                summary.unknown += 1;
            else
                summary[state] += 1;
        }
        return summary;
    }

    function statusSeverity(state) {
        return PluginRuntimeCatalog.stateSeverity(String(state || ""));
    }

    function statusDescription(state) {
        return PluginRuntimeCatalog.stateDescription(String(state || ""));
    }

    function pluginDiagnosticsPayload() {
        var plugins = (PluginService.plugins || []).slice();
        plugins.sort(function (a, b) {
            return String(a.id || "").localeCompare(String(b.id || ""));
        });

        var pluginRows = [];
        for (var i = 0; i < plugins.length; i++) {
            var plugin = plugins[i] || ({});
            var pluginId = String(plugin.id || "");
            var runtime = PluginService.pluginStatuses && pluginId !== "" ? PluginService.pluginStatuses[pluginId] : null;
            var state = runtime && runtime.state ? String(runtime.state) : (plugin.enabled ? "enabled" : "disabled");
            var code = runtime && runtime.code ? String(runtime.code) : "";
            var message = runtime && runtime.message ? String(runtime.message) : "";
            var updatedAt = runtime && runtime.updatedAt ? String(runtime.updatedAt) : "";
            pluginRows.push({
                id: pluginId,
                name: String(plugin.name || ""),
                version: String(plugin.version || ""),
                type: String(plugin.type || ""),
                enabled: !!plugin.enabled,
                author: String(plugin.author || ""),
                permissions: Array.isArray(plugin.permissions) ? plugin.permissions.slice() : [],
                entryPoints: plugin.entryPoints && typeof plugin.entryPoints === "object" ? Object.assign({}, plugin.entryPoints) : ({}),
                runtime: {
                    state: state,
                    stateLabel: PluginRuntimeCatalog.stateLabel(state),
                    stateSeverity: root.statusSeverity(state),
                    code: code,
                    codeLabel: code !== "" ? PluginRuntimeCatalog.errorLabel(code) : "",
                    codeSeverity: code !== "" ? PluginRuntimeCatalog.errorSeverity(code) : "muted",
                    message: message,
                    updatedAt: updatedAt
                }
            });
        }

        return {
            schemaVersion: 1,
            generatedAt: (new Date()).toISOString(),
            summary: {
                installed: (PluginService.plugins || []).length,
                enabled: (PluginService.plugins || []).filter(function (p) {
                    return !!(p && p.enabled);
                }).length,
                invalidManifests: root.pluginErrorEntries().length,
                statuses: root.pluginStatusSummary()
            },
            plugins: pluginRows,
            manifestErrors: root.pluginErrorEntries()
        };
    }

    function copyPluginDiagnostics() {
        _pluginDiagnosticsExportText = JSON.stringify(root.pluginDiagnosticsPayload(), null, 2);
        if (pluginDiagnosticsCopyProc.running)
            return;
        pluginDiagnosticsCopyProc.command = ["sh", "-c", "if command -v wl-copy >/dev/null 2>&1; then " + "cat | wl-copy; " + "elif command -v xclip >/dev/null 2>&1; then " + "cat | xclip -selection clipboard; " + "else exit 127; fi"];
        pluginDiagnosticsCopyProc.running = true;
    }

    function savePluginDiagnostics() {
        _pluginDiagnosticsExportText = JSON.stringify(root.pluginDiagnosticsPayload(), null, 2);
        _pluginDiagnosticsSavePath = root.pluginDiagnosticsOutputPath();
        if (pluginDiagnosticsSaveProc.running)
            return;
        pluginDiagnosticsSaveProc.command = ["sh", "-c", "mkdir -p \"$1\" && cat > \"$2\"", "sh", root.diagnosticsOutputDir(), _pluginDiagnosticsSavePath];
        pluginDiagnosticsSaveProc.running = true;
    }

    function severityColor(severity) {
        var sev = String(severity || "");
        if (sev === "ok")
            return Colors.success;
        if (sev === "warn")
            return Colors.warning;
        if (sev === "error")
            return Colors.error;
        return Colors.textSecondary;
    }

    function severityBgColor(severity) {
        var base = severityColor(severity);
        if (String(severity || "") === "muted")
            return Colors.textWash;
        return Colors.withAlpha(base, 0.16);
    }

    function pluginTypeIcon(typeName) {
        if (typeName === "bar-widget")
            return "󰖯";
        if (typeName === "desktop-widget")
            return "󰖲";
        if (typeName === "launcher-provider")
            return "󰀻";
        if (typeName === "control-center-widget")
            return "󰕮";
        if (typeName === "daemon")
            return "󰒓";
        return "󰏗";
    }

    function pluginTypeLabel(typeName) {
        if (typeName === "bar-widget")
            return "Bar";
        if (typeName === "desktop-widget")
            return "Desktop";
        if (typeName === "launcher-provider")
            return "Launcher";
        if (typeName === "control-center-widget")
            return "Control Center";
        if (typeName === "daemon")
            return "Daemon";
        return "Multi";
    }

    function pluginTypeAccent(typeName) {
        if (typeName === "bar-widget")
            return Colors.accent;
        if (typeName === "desktop-widget")
            return Colors.primary;
        if (typeName === "control-center-widget")
            return Colors.success;
        return Colors.warning;
    }

    function openPluginPane(pluginId, paneMode) {
        selectedPluginId = String(pluginId || "");
        pluginPaneMode = String(paneMode || "");
        pluginPaneError = "";
        pluginPaneOpen = true;
        Qt.callLater(function() { if (_destroyed) return; loadPluginPane(); });
    }

    function closePluginPane() {
        pluginPaneOpen = false;
    }

    function pluginPaneTitle() {
        if (!selectedPlugin)
            return "Plugin";
        if (pluginPaneMode === "settings")
            return String(selectedPlugin.name || selectedPlugin.id) + " Settings";
        if (pluginPaneMode === "detail")
            return String(selectedPlugin.name || selectedPlugin.id) + " Detail";
        return String(selectedPlugin.name || selectedPlugin.id);
    }

    function loadPluginPane() {
        var loader = pluginPaneOverlay.pluginPaneLoader;
        if (!loader)
            return;
        loader.source = "";
        pluginPaneError = "";
        if (!pluginPaneOpen || selectedPluginId === "" || !selectedPlugin)
            return;

        var src = "";
        if (pluginPaneMode === "settings") {
            if (!selectedPluginHasSettings) {
                pluginPaneError = "This plugin does not expose a settings entry point.";
                return;
            }
            if (!selectedPluginCanWriteSettings) {
                pluginPaneError = "This plugin does not have settings_write permission.";
                return;
            }
            src = PluginService.pluginSettingsSource(selectedPluginId);
        } else if (pluginPaneMode === "detail") {
            if (!selectedPluginHasControlCenterDetail) {
                pluginPaneError = "This plugin does not expose a Control Center detail pane.";
                return;
            }
            src = PluginService.pluginControlCenterDetailSource(selectedPluginId);
        }

        if (src === "") {
            pluginPaneError = "Plugin entry point is missing.";
            return;
        }

        var api = PluginService.getPluginAPI(selectedPluginId);
        loader.setSource(src, {
            pluginApi: api,
            pluginManifest: selectedPlugin,
            pluginService: PluginService
        });
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Plugins"
        iconName: "apps.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Plugin Overview"
            description: "Installed count, runtime health, and manifest integrity before you drill into the catalog."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "apps.svg",
                            label: "Installed",
                            value: root.pluginCount + " plugin" + (root.pluginCount === 1 ? "" : "s")
                        },
                        {
                            icon: "󰄬",
                            label: "Enabled",
                            value: root.enabledPluginCount + " active"
                        },
                        {
                            icon: "󰀪",
                            label: "Manifest Errors",
                            value: root.invalidManifestCount + " issue" + (root.invalidManifestCount === 1 ? "" : "s")
                        },
                        {
                            icon: "󰒓",
                            label: "Runtime",
                            value: root.pluginStatusSummary().degraded > 0 || root.pluginStatusSummary().failed > 0
                                ? (root.pluginStatusSummary().degraded + root.pluginStatusSummary().failed) + " attention"
                                : "Healthy"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Colors.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Plugin Catalog"
            description: "Discover installed plugins, inspect runtime state, and open plugin settings or detail panes."

            SettingsCard {
                title: "Plugin Manager"
                iconName: "apps.svg"
                description: "Discover and toggle installed bar and desktop widget plugins."

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingM

                    ColumnLayout {
                        spacing: Colors.spacingXXS
                        width: root.compactMode ? parent.width : Math.max(0, parent.width - scanPluginsButton.implicitWidth - copyDiagnosticsButton.implicitWidth - saveDiagnosticsButton.implicitWidth - (Colors.spacingM * 3))

                        Text {
                            text: PluginService.plugins.length + " plugin" + (PluginService.plugins.length !== 1 ? "s" : "") + " found"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        Text {
                            text: PluginService.plugins.filter(function (p) {
                                return p.enabled;
                            }).length + " enabled"
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                        }

                        Text {
                            visible: Object.keys(PluginService.pluginErrors || ({})).length > 0
                            text: Object.keys(PluginService.pluginErrors || ({})).length + " invalid plugin manifest" + (Object.keys(PluginService.pluginErrors || ({})).length !== 1 ? "s" : "")
                            color: Colors.warning
                            font.pixelSize: Colors.fontSizeSmall
                        }
                    }

                    SettingsActionButton {
                        id: scanPluginsButton
                        label: "Scan"
                        iconName: "arrow-clockwise.svg"
                        compact: true
                        onClicked: PluginService.scanPlugins()
                    }

                    SettingsActionButton {
                        id: copyDiagnosticsButton
                        label: "Copy Diagnostics"
                        iconName: "󰨓"
                        compact: true
                        onClicked: root.copyPluginDiagnostics()
                    }

                    SettingsActionButton {
                        id: saveDiagnosticsButton
                        label: "Save Diagnostics"
                        iconName: "save.svg"
                        compact: true
                        onClicked: root.savePluginDiagnostics()
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Rectangle {
                        implicitWidth: activeCount.implicitWidth + 12
                        height: 20
                        radius: Colors.radiusSmall
                        color: Colors.withAlpha(Colors.success, 0.16)
                        Text {
                            id: activeCount
                            anchors.centerIn: parent
                            text: "active " + root.pluginStatusSummary().active
                            color: Colors.success
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        implicitWidth: degradedCount.implicitWidth + 12
                        height: 20
                        radius: Colors.radiusSmall
                        color: Colors.warningLight
                        Text {
                            id: degradedCount
                            anchors.centerIn: parent
                            text: "degraded " + root.pluginStatusSummary().degraded
                            color: Colors.warning
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        implicitWidth: failedCount.implicitWidth + 12
                        height: 20
                        radius: Colors.radiusSmall
                        color: Colors.withAlpha(Colors.error, 0.16)
                        Text {
                            id: failedCount
                            anchors.centerIn: parent
                            text: "failed " + root.pluginStatusSummary().failed
                            color: Colors.error
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        implicitWidth: disabledCount.implicitWidth + 12
                        height: 20
                        radius: Colors.radiusSmall
                        color: Colors.borderLight
                        Text {
                            id: disabledCount
                            anchors.centerIn: parent
                            text: "disabled " + root.pluginStatusSummary().disabled
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }
                }

                ColumnLayout {
                    visible: PluginService.plugins.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: Colors.spacingXL
                    spacing: Colors.spacingM

                    Text {
                        text: "󰏗"
                        color: Colors.textDisabled
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeHuge
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "No plugins found"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeLarge
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Add a folder with manifest.json to get started"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeSmall
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Repeater {
                    model: PluginService.plugins

                    delegate: SettingsListRow {
                        active: modelData.enabled
                        radius: Colors.radiusMedium
                        contentInset: Colors.spacingM
                        rowSpacing: root.compactMode ? Colors.spacingS : Colors.spacingM
                        minimumHeight: root.compactMode ? 92 : 66

                        Rectangle {
                            width: root.compactMode ? 32 : 38
                            height: root.compactMode ? 32 : 38
                            radius: Colors.radiusSmall
                            color: modelData.enabled ? Colors.primarySubtle : Colors.textFaint
                            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.pluginTypeIcon(modelData.type)
                                color: modelData.enabled ? Colors.primary : Colors.textDisabled
                                font.family: Colors.fontMono
                                font.pixelSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL
                                Behavior on color {
                                    enabled: !Colors.isTransitioning
                                    CAnim {}
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Colors.spacingS

                                Text {
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    width: parent.width
                                    elide: Text.ElideRight
                                    wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Colors.spacingS

                                Rectangle {
                                    implicitWidth: verLabel.implicitWidth + 10
                                    height: 18
                                    radius: height / 2
                                    color: Colors.textWash
                                    Text {
                                        id: verLabel
                                        anchors.centerIn: parent
                                        text: "v" + modelData.version
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.family: Colors.fontMono
                                    }
                                }

                                Rectangle {
                                    implicitWidth: typeLabel.implicitWidth + 10
                                    height: 18
                                    radius: height / 2
                                    color: Qt.rgba(root.pluginTypeAccent(modelData.type).r, root.pluginTypeAccent(modelData.type).g, root.pluginTypeAccent(modelData.type).b, 0.14)
                                    Text {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: root.pluginTypeLabel(modelData.type)
                                        color: root.pluginTypeAccent(modelData.type)
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    implicitWidth: statusLabel.implicitWidth + 10
                                    height: 18
                                    radius: height / 2
                                    color: {
                                        var status = PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] ? PluginService.pluginStatuses[modelData.id].state : "";
                                        var severity = root.statusSeverity(status !== "" ? status : (modelData.enabled ? "enabled" : "disabled"));
                                        return root.severityBgColor(severity);
                                    }
                                    Text {
                                        id: statusLabel
                                        anchors.centerIn: parent
                                        text: {
                                            var status = PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] ? PluginService.pluginStatuses[modelData.id].state : "";
                                            return PluginRuntimeCatalog.stateLabel(status !== "" ? status : (modelData.enabled ? "enabled" : "disabled"));
                                        }
                                        color: {
                                            var status = PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] ? PluginService.pluginStatuses[modelData.id].state : "";
                                            var severity = root.statusSeverity(status !== "" ? status : (modelData.enabled ? "enabled" : "disabled"));
                                            return root.severityColor(severity);
                                        }
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Text {
                                visible: modelData.description.length > 0
                                text: modelData.description
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeSmall
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                text: "by " + modelData.author
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                            }

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Colors.spacingS

                                SettingsActionButton {
                                    visible: PluginService.pluginSupportsControlCenterDetail(modelData.id)
                                    compact: true
                                    iconName: "󰍐"
                                    label: "Detail"
                                    onClicked: root.openPluginPane(modelData.id, "detail")
                                }

                                SettingsActionButton {
                                    visible: PluginService.pluginSupportsSettings(modelData.id)
                                    compact: true
                                    iconName: "settings.svg"
                                    label: "Settings"
                                    onClicked: root.openPluginPane(modelData.id, "settings")
                                }
                            }

                            Text {
                                visible: PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] && String(PluginService.pluginStatuses[modelData.id].message || "") !== ""
                                text: (PluginService.pluginStatuses[modelData.id].code ? ("[" + PluginRuntimeCatalog.errorLabel(PluginService.pluginStatuses[modelData.id].code) + "] ") : "") + String(PluginService.pluginStatuses[modelData.id].message || "")
                                color: Colors.warning
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                visible: PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] && String(PluginService.pluginStatuses[modelData.id].code || "") !== "" && String(PluginRuntimeCatalog.errorDescription(PluginService.pluginStatuses[modelData.id].code) || "") !== ""
                                text: PluginRuntimeCatalog.errorDescription(PluginService.pluginStatuses[modelData.id].code)
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                visible: PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] && String(PluginService.pluginStatuses[modelData.id].updatedAt || "") !== ""
                                text: "updated " + String(PluginService.pluginStatuses[modelData.id].updatedAt || "")
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                visible: {
                                    var status = PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] ? PluginService.pluginStatuses[modelData.id].state : (modelData.enabled ? "enabled" : "disabled");
                                    return String(root.statusDescription(status) || "") !== "";
                                }
                                text: {
                                    var status = PluginService.pluginStatuses && PluginService.pluginStatuses[modelData.id] ? PluginService.pluginStatuses[modelData.id].state : (modelData.enabled ? "enabled" : "disabled");
                                    return root.statusDescription(status);
                                }
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        SharedWidgets.ToggleSwitch {
                            checked: modelData.enabled
                            Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                            onToggled: {
                                if (modelData.enabled)
                                    PluginService.disablePlugin(modelData.id);
                                else
                                    PluginService.enablePlugin(modelData.id);
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: root.pluginErrorEntries().length > 0
                    Layout.fillWidth: true
                    spacing: Colors.spacingS
                    Layout.topMargin: Colors.spacingM

                    Text {
                        text: "Invalid plugin manifests"
                        color: Colors.warning
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: root.pluginErrorEntries()

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            radius: Colors.radiusSmall
                            color: Colors.withAlpha(Colors.warning, 0.10)
                            border.color: Colors.withAlpha(Colors.warning, 0.35)
                            border.width: 1
                            implicitHeight: issueText.implicitHeight + 14

                            Text {
                                id: issueText
                                anchors.fill: parent
                                anchors.margins: 7
                                text: modelData.id + ": " + (modelData.code !== "" ? ("[" + modelData.code + "] ") : "") + modelData.error
                                color: Colors.warning
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Installation & Diagnostics"
            description: "Reference information for plugin packaging and the diagnostics export that backs the shell tooling."

            SettingsCard {
                title: "Installation"
                iconName: "info.svg"
                description: "Plugin format and discovery location."

                SettingsInfoCallout {
                    iconName: "apps.svg"
                    title: "Plugin directory"
                    body: "~/.config/quickshell/plugins/"

                    Text {
                        text: "Each plugin is a folder containing a manifest.json and one or more QML entry points."
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Manifest fields: id, name, description, author, version, type, permissions, entryPoints { barWidget|desktopWidget|launcherProvider|daemon|settings }"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Reference schema: src/plugins/manifest.schema.json"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    PluginPaneOverlay {
        id: pluginPaneOverlay
        anchors.fill: parent
        visible: root.pluginPaneOpen
        open: root.pluginPaneOpen
        compactMode: root.compactMode
        selectedPlugin: root.selectedPlugin
        selectedPluginHasSettings: root.selectedPluginHasSettings
        selectedPluginCanWriteSettings: root.selectedPluginCanWriteSettings
        pluginPaneMode: root.pluginPaneMode
        pluginPaneError: root.pluginPaneError
        pluginPaneTitle: root.pluginPaneTitle()
        pluginTypeIcon: root.selectedPlugin ? root.pluginTypeIcon(root.selectedPlugin.type) : "󰏗"
        pluginTypeLabel: root.selectedPlugin ? root.pluginTypeLabel(root.selectedPlugin.type) : ""
        onCloseRequested: root.closePluginPane()
        onPluginPaneErrorUpdated: (value) => { root.pluginPaneError = value; }
    }

    Process {
        id: pluginDiagnosticsCopyProc
        running: false
        stdinEnabled: true
        onStarted: {
            pluginDiagnosticsCopyProc.write(_pluginDiagnosticsExportText);
            pluginDiagnosticsCopyProc.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                ToastService.showSuccess("Copied", "Plugin diagnostics copied to clipboard.");
            else
                ToastService.showError("Copy failed", "No clipboard utility found (wl-copy/xclip).");
        }
    }

    Process {
        id: pluginDiagnosticsSaveProc
        running: false
        stdinEnabled: true
        onStarted: {
            pluginDiagnosticsSaveProc.write(_pluginDiagnosticsExportText);
            pluginDiagnosticsSaveProc.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                ToastService.showSuccess("Saved", "Plugin diagnostics saved to " + _pluginDiagnosticsSavePath);
            else
                ToastService.showError("Save failed", "Unable to write plugin diagnostics.");
        }
    }
}

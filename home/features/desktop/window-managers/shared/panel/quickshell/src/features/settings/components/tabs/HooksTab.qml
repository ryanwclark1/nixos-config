import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../services"
import "../../../../services/ShellUtils.js" as SU
import "../../../../services/IconHelpers.js" as IconHelpers
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    readonly property var groupedCategories: _groupedCategories()
    readonly property int hookCount: HookService.hookCatalog.length
    readonly property int categoryCount: root.groupedCategories.length
    readonly property int configuredHookCount: {
        var count = 0;
        var catalog = HookService.hookCatalog || [];
        for (var i = 0; i < catalog.length; i++) {
            if (_hookHasScript(catalog[i].name))
                count += 1;
        }
        return count;
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Hooks"
        iconName: "code.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Hook Overview"
            description: "Execution state, catalog size, and how many hook points currently have scripts wired up."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "code.svg",
                            label: "Hooks",
                            value: Config.hooksEnabled ? "Enabled" : "Disabled"
                        },
                        {
                            icon: "document.svg",
                            label: "Catalog",
                            value: root.hookCount + " available"
                        },
                        {
                            icon: "save.svg",
                            label: "Configured",
                            value: root.configuredHookCount + " script" + (root.configuredHookCount === 1 ? "" : "s")
                        },
                        {
                            icon: "code.svg",
                            label: "Categories",
                            value: root.categoryCount + " groups"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(140, Math.floor((parent.width - Appearance.spacingM * 3) / 4))
                        implicitHeight: metricColumn.implicitHeight + Appearance.spacingM * 2
                        radius: Appearance.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            spacing: Appearance.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Appearance.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Hook System"
            description: "Enable the hook runner globally and jump to the filesystem location where shell hooks are stored."

            SettingsCard {
                title: "Hook System"
                iconName: "code.svg"
                description: "Run scripts when system events occur. Place executable scripts in ~/.config/quickshell/hooks/ or set custom paths below."

                SettingsToggleRow {
                    label: "Enable Hooks"
                    icon: "code.svg"
                    configKey: "hooksEnabled"
                }

                SettingsListRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingXXS

                        Text {
                            Layout.fillWidth: true
                            text: "Open Hooks Directory"
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Open ~/.config/quickshell/hooks in your file manager or terminal."
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    RowLayout {
                        spacing: Appearance.spacingS

                        SettingsActionButton {
                            label: "Open"
                            iconName: "folder.svg"
                            compact: true
                            onClicked: {
                                Quickshell.execDetached(["xdg-open", HookService.hookDir]);
                                ToastService.showSuccess("Opening Directory", "Hooks folder opening in file manager");
                            }
                        }

                        SettingsActionButton {
                            label: "Terminal"
                            iconName: "terminal.svg"
                            compact: true
                            onClicked: {
                                Quickshell.execDetached(SU.terminalCommand("cd " + SU.shellQuote(HookService.hookDir) + " && exec bash"));
                                ToastService.showSuccess("Opening Terminal", "Hooks folder opening in terminal");
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Color Export"
            description: "Export shell colors to files and propagate to downstream apps when the palette changes."

            SettingsCard {
                title: "Color Export"
                iconName: "color-palette.svg"
                description: "Write the active color palette to ~/.local/state/quickshell/ as JSON and shell variables. Fires the colors-changed hook."

                SettingsToggleRow {
                    label: "Enable Color Export"
                    icon: "color-palette.svg"
                    configKey: "colorExportEnabled"
                }

                SettingsToggleRow {
                    label: "Ghostty Colors"
                    icon: "sparkle.svg"
                    configKey: "colorExportGhostty"
                    description: "Write ghostty config fragment (add config-file = ~/.local/state/quickshell/ghostty-colors to ghostty config)"
                }

                SettingsToggleRow {
                    label: "Kitty Remote Colors"
                    icon: "terminal.svg"
                    configKey: "colorExportKitty"
                    description: "Send colors to running kitty instances via remote control"
                }

                SettingsToggleRow {
                    label: "GTK Dark/Light Scheme"
                    icon: "play.svg"
                    configKey: "colorExportGtkScheme"
                    description: "Toggle gsettings color-scheme based on light/dark theme"
                }
            }
        }

        SettingsSectionGroup {
            title: "Hook Catalog"
            description: "Available hook entry points grouped by category, with per-hook template generation."

            Repeater {
                model: root.groupedCategories

                delegate: SettingsCard {
                    required property var modelData
                    title: modelData.category
                    iconName: _categoryIcon(modelData.category)
                    description: modelData.hooks.length + " hook" + (modelData.hooks.length !== 1 ? "s" : "") + " available"

                    Repeater {
                        model: modelData.hooks

                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: Appearance.radiusXS
                                    color: _hookHasScript(modelData.name) ? Colors.success : Colors.textDisabled
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.name
                                        color: Colors.text
                                        font.pixelSize: Appearance.fontSizeMedium
                                        font.weight: Font.Medium
                                        font.family: Appearance.fontMono
                                    }

                                    Text {
                                        text: modelData.description + (modelData.valueDescription ? " (" + modelData.valueDescription + ")" : "")
                                        color: Colors.textDisabled
                                        font.pixelSize: Appearance.fontSizeXS
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                SharedWidgets.SvgIcon {
                                    source: "save.svg"
                                    color: Colors.textSecondary
                                    size: Appearance.fontSizeLarge

                                    MouseArea {
                                        id: createTemplateMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: _createTemplate(modelData.name, modelData.valueDescription)
                                    }

                                    SharedWidgets.Tooltip {
                                        text: "Create template script"
                                        hoverPoint: Qt.point(createTemplateMouse.mouseX, createTemplateMouse.mouseY)
                                        shown: createTemplateMouse.containsMouse
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function _groupedCategories() {
        var catalog = HookService.hookCatalog;
        var groups = {};
        var order = [];
        for (var i = 0; i < catalog.length; i++) {
            var h = catalog[i];
            if (!groups[h.category]) {
                groups[h.category] = [];
                order.push(h.category);
            }
            groups[h.category].push(h);
        }
        var result = [];
        for (var j = 0; j < order.length; j++) {
            result.push({
                category: order[j],
                hooks: groups[order[j]]
            });
        }
        return result;
    }

    function _categoryIcon(cat) {
        return IconHelpers.hookCategoryIcon(cat);
    }

    function _hookHasScript(hookName) {
        var paths = Config.hookPaths || {};
        return !!paths[hookName];
    }

    function _createTemplate(hookName, valueDesc) {
        if (!/^[a-zA-Z0-9_-]+$/.test(hookName)) {
            ToastService.showError("Invalid Hook", "Hook name contains invalid characters");
            return;
        }
        var safeDesc = (valueDesc || "value").replace(/['"\\]/g, "");
        var path = HookService.hookDir + "/" + hookName;
        _templateProc.command = ["sh", "-c", "cat > \"$1\" && chmod +x \"$1\"", "sh", path];
        root._pendingTemplateContent = "#!/bin/sh\n# Hook: " + hookName + "\n# $1 = hook name, $2 = " + safeDesc + "\n\necho \"Hook fired: $1 = $2\" >> /tmp/quickshell-hooks.log\n";
        root._pendingTemplatePath = path;
        _templateProc.running = true;
    }

    property string _pendingTemplateContent: ""
    property string _pendingTemplatePath: ""

    Process {
        id: _templateProc
        running: false
        stdinEnabled: true
        onStarted: {
            write(root._pendingTemplateContent);
            stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                ToastService.showSuccess("Hook Created", "Template created at " + root._pendingTemplatePath);
            else
                ToastService.showError("Hook Error", "Failed to create template script");
            root._pendingTemplateContent = "";
            root._pendingTemplatePath = "";
        }
    }
}

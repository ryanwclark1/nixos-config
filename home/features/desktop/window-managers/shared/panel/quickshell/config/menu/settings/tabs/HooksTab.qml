import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Hooks"
        iconName: "󱁨"

        SettingsCard {
            title: "Hook System"
            iconName: "󱁨"
            description: "Run scripts when system events occur. Place executable scripts in ~/.config/quickshell/hooks/ or set custom paths below."

            SettingsToggleRow {
                label: "Enable Hooks"
                icon: "󱁨"
                configKey: "hooksEnabled"
            }

            SettingsListRow {
                label: "Open Hooks Directory"

                Text {
                    Layout.fillWidth: true
                    text: "Open ~/.config/quickshell/hooks in the default file manager."
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                SettingsActionButton {
                    label: "Open"
                    iconName: "󰉋"
                    compact: true
                    onClicked: Quickshell.execDetached(["xdg-open", HookService.hookDir])
                }
            }
        }

        Repeater {
            model: _groupedCategories()

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
                        spacing: Colors.spacingXXS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: _hookHasScript(modelData.name) ? Colors.success : Colors.textDisabled
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.Medium
                                    font.family: Colors.fontMono
                                }

                                Text {
                                    text: modelData.description + (modelData.valueDescription ? " (" + modelData.valueDescription + ")" : "")
                                    color: Colors.textDisabled
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: "󰆓"
                                color: Colors.textSecondary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: _createTemplate(modelData.name, modelData.valueDescription)

                                    BarTooltip {
                                        anchorItem: parent
                                        hovered: parent.containsMouse
                                        text: "Create template script"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Import BarTooltip for template button tooltip
    component BarTooltip: Text {
        property var anchorItem: null
        property bool hovered: false
        property string text: ""
        visible: false // Simplified: tooltip handled by hover state above
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
            result.push({ category: order[j], hooks: groups[order[j]] });
        }
        return result;
    }

    function _categoryIcon(cat) {
        if (cat === "Appearance") return "󰏘";
        if (cat === "Power") return "󰌪";
        if (cat === "Audio") return "󰕾";
        if (cat === "Display") return "󰍹";
        if (cat === "Notifications") return "󰂚";
        if (cat === "Media") return "󰝚";
        if (cat === "Compositor") return "󱗼";
        return "󱁨";
    }

    function _hookHasScript(hookName) {
        var paths = Config.hookPaths || {};
        return !!paths[hookName];
    }

    function _createTemplate(hookName, valueDesc) {
        // Validate hookName: only alphanumeric, hyphen, underscore allowed
        if (!/^[a-zA-Z0-9_-]+$/.test(hookName)) {
            ToastService.showError("Invalid Hook", "Hook name contains invalid characters");
            return;
        }
        var safeDesc = (valueDesc || "value").replace(/['"\\]/g, "");
        var path = HookService.hookDir + "/" + hookName;
        // Use stdin to avoid shell injection — content is piped, not interpolated
        _templateProc.command = ["sh", "-c", "cat > '" + path + "' && chmod +x '" + path + "'"];
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

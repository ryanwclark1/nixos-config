import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property var keybindsList: []
    property string keybindsFilter: ""

    function normalizeModifierLabel(mod) {
        var value = String(mod || "").trim();
        if (!value)
            return "";
        var lower = value.toLowerCase();
        if (lower === "mod" || lower === "super" || lower === "meta" || lower === "$mainmod")
            return "Super";
        if (lower === "ctrl" || lower === "control")
            return "Ctrl";
        if (lower === "alt" || lower === "mod1")
            return "Alt";
        if (lower === "shift")
            return "Shift";
        return value;
    }

    function formatModifierList(mods) {
        var normalized = [];
        for (var i = 0; i < mods.length; i++) {
            var label = normalizeModifierLabel(mods[i]);
            if (label && normalized.indexOf(label) === -1)
                normalized.push(label);
        }
        return normalized.join(" + ");
    }

    function formatHyprModifiers(bind) {
        if (bind.modString) {
            var rawMods = [];
            if (Array.isArray(bind.modString))
                rawMods = bind.modString;
            else
                rawMods = String(bind.modString).split(/[+\s]+/);
            var modString = formatModifierList(rawMods);
            if (modString)
                return modString;
        }

        var modmask = Number(bind.modmask || 0);
        var decoded = [];
        if (modmask & 64)
            decoded.push("Super");
        if (modmask & 4)
            decoded.push("Ctrl");
        if (modmask & 8)
            decoded.push("Alt");
        if (modmask & 1)
            decoded.push("Shift");
        return decoded.join(" + ");
    }

    Process {
        id: hyprBindsProc
        command: CompositorAdapter.hotkeysCommand()
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = JSON.parse(this.text || "[]");
                    var result = [];
                    for (var i = 0; i < raw.length; i++) {
                        var b = raw[i];
                        result.push({
                            mods: root.formatHyprModifiers(b),
                            key: b["key"] || "",
                            dispatcher: b.dispatcher || "",
                            arg: b.arg || ""
                        });
                    }
                    root.keybindsList = result;
                } catch (e) {
                    Logger.e("HotkeysTab", "Failed to parse compositor binds:", e);
                }
            }
        }
    }

    // Niri: load from NiriBinds service (parsed from config.kdl)
    function loadNiriBinds() {
        var result = [];
        var categories = NiriBinds.binds.children || [];
        for (var i = 0; i < categories.length; i++) {
            var cat = categories[i];
            var catName = cat.name || "";
            var groups = cat.children || [];
                for (var g = 0; g < groups.length; g++) {
                    var binds = groups[g].keybinds || [];
                    for (var k = 0; k < binds.length; k++) {
                        var b = binds[k];
                        var modStr = root.formatModifierList(b.mods || []);
                        result.push({
                            mods: modStr,
                            key: b["key"] || "",
                        dispatcher: catName,
                        arg: b.comment || ""
                    });
                }
            }
        }
        root.keybindsList = result;
    }

    Connections {
        target: NiriBinds
        enabled: CompositorAdapter.isNiri
        function onBindsChanged() { root.loadNiriBinds(); }
    }

    Component.onCompleted: {
        if (CompositorAdapter.isNiri) {
            loadNiriBinds();
        } else if (!hyprBindsProc.running) {
            hyprBindsProc.running = true;
        }
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Keybindings"
        iconName: "󱕴"

        SettingsCard {
            title: "Search"
            iconName: "search-visual.svg"
            description: "Filter active compositor binds by key, modifier, dispatcher, or arguments."

            SettingsTextInputRow {
                id: keybindsSearchField
                Layout.fillWidth: true
                placeholderText: "Search keybindings..."
                leadingIcon: "search-visual.svg"
                onTextEdited: value => root.keybindsFilter = value.toLowerCase()
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Refresh"
                iconName: "arrow-clockwise.svg"
                onClicked: {
                    root.keybindsList = [];
                    if (CompositorAdapter.isNiri) NiriBinds.reload();
                    else hyprBindsProc.running = true;
                }
            }
        }

        SettingsCard {
            title: "Bindings"
            iconName: "keyboard.svg"
            description: CompositorAdapter.isNiri ? "Niri keybindings from config.kdl." : "Current compositor keymap snapshot."

            Text {
                visible: root.keybindsList.length === 0
                text: "Loading keybindings…"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeMedium
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacingLG
            }

            Repeater {
                model: ScriptModel {
                    values: {
                        var filter = root.keybindsFilter;
                        var list = root.keybindsList;
                        if (!filter)
                            return [...list];
                        return list.filter(function (b) {
                            var haystack = (b.mods + " " + b["key"] + " " + b.dispatcher + " " + b.arg).toLowerCase();
                            return haystack.indexOf(filter) !== -1;
                        });
                    }
                }

                delegate: SettingsListRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.tightSpacing ? 4 : 6

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Appearance.spacingS

                            Rectangle {
                                id: chordBadge
                                implicitWidth: Math.min(parent.width, chordText.implicitWidth + 16)
                                height: 26
                                radius: Appearance.radiusXXS
                                color: Colors.highlight
                                border.color: Colors.primary
                                border.width: 1

                                Text {
                                    id: chordText
                                    anchors.centerIn: parent
                                    text: {
                                        var parts = [];
                                        if (modelData.mods)
                                            parts.push(modelData.mods);
                                        if (modelData["key"])
                                            parts.push(modelData["key"]);
                                        return parts.join(" + ");
                                    }
                                    width: Math.max(0, parent.width - 12)
                                    color: Colors.primary
                                    font.family: Appearance.fontMono
                                    font.pixelSize: Appearance.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: modelData.dispatcher
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.DemiBold
                                width: (root.compactMode || chordBadge.width > parent.width * 0.45)
                                    ? parent.width
                                    : Math.max(0, parent.width - chordBadge.width - Appearance.spacingS)
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: modelData.arg || "—"
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            font.family: modelData.arg ? Appearance.fontMono : ""
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }
    }
}

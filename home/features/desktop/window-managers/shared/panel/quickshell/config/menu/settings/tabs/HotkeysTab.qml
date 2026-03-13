import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property var keybindsList: []
    property string keybindsFilter: ""

    Process {
        id: hyprBindsProc
        command: CompositorAdapter.supportsHotkeysListing ? ["hyprctl", "binds", "-j"] : ["sh", "-c", "echo '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = JSON.parse(this.text || "[]");
                    var result = [];
                    for (var i = 0; i < raw.length; i++) {
                        var b = raw[i];
                        var mods = (b.modmask !== undefined && b.modmask !== 0) ? b.modString || "" : "";
                        result.push({
                            mods: mods,
                            key: b["key"] || "",
                            dispatcher: b.dispatcher || "",
                            arg: b.arg || ""
                        });
                    }
                    root.keybindsList = result;
                } catch (e) {
                    console.error("Failed to parse hyprctl binds: " + e);
                }
            }
        }
    }

    Component.onCompleted: {
        if (!hyprBindsProc.running)
            hyprBindsProc.running = true;
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Keybindings"
        iconName: "󱕴"

        SettingsCard {
            title: "Search"
            iconName: "󰍉"
            description: "Filter active Hyprland binds by key, modifier, dispatcher, or arguments."

            SettingsTextInputRow {
                id: keybindsSearchField
                Layout.fillWidth: true
                placeholderText: "Search keybindings..."
                leadingIcon: "󰍉"
                onTextEdited: value => root.keybindsFilter = value.toLowerCase()
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Refresh"
                iconName: "󰑐"
                onClicked: {
                    root.keybindsList = [];
                    hyprBindsProc.running = true;
                }
            }
        }

        SettingsCard {
            title: "Bindings"
            iconName: "󰌌"
            description: "Current compositor keymap snapshot."

            Text {
                visible: root.keybindsList.length === 0
                text: "Loading keybindings…"
                color: Colors.fgDim
                font.pixelSize: Colors.fontSizeMedium
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }

            Repeater {
                model: {
                    var filter = root.keybindsFilter;
                    var list = root.keybindsList;
                    if (!filter)
                        return list;
                    return list.filter(function (b) {
                        var haystack = (b.mods + " " + b["key"] + " " + b.dispatcher + " " + b.arg).toLowerCase();
                        return haystack.indexOf(filter) !== -1;
                    });
                }

                delegate: SettingsListRow {
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.tightSpacing ? 4 : 6

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Colors.spacingS

                            Rectangle {
                                implicitWidth: chordText.implicitWidth + 16
                                height: 26
                                radius: 6
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
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                text: modelData.dispatcher
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.DemiBold
                                width: Math.max(0, parent.width - chordText.implicitWidth - Colors.spacingS - 16)
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: modelData.arg || "—"
                            color: Colors.fgSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            font.family: modelData.arg ? Colors.fontMono : ""
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }
    }
}

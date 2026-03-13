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
        command: CompositorAdapter.hotkeysCommand()
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
                    console.error("Failed to parse compositor binds: " + e);
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
            description: "Filter active compositor binds by key, modifier, dispatcher, or arguments."

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
                                id: chordBadge
                                implicitWidth: Math.min(parent.width, chordText.implicitWidth + 16)
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
                                    width: Math.max(0, parent.width - 12)
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: modelData.dispatcher
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.DemiBold
                                width: (root.compactMode || chordBadge.width > parent.width * 0.45)
                                    ? parent.width
                                    : Math.max(0, parent.width - chordBadge.width - Colors.spacingS)
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

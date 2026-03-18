import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services"
import "../../shared"

Item {
    id: root
    property string searchQuery: ""
    property var keybinds: []

    Component.onCompleted: _loadKeybinds()

    function _loadKeybinds() {
        keybindProcess.running = true;
    }

    Process {
        id: keybindProcess
        command: ["qs-keybinds"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.keybinds = JSON.parse(data);
                } catch (e) {
                    console.warn("Cheatsheet: failed to parse keybinds:", e);
                }
            }
        }
    }

    // Flickable with flow of keybinding section cards
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: gridLayout.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: gridLayout
            width: parent.width
            spacing: Colors.spacingLG

            Repeater {
                model: root.keybinds

                delegate: Rectangle {
                    id: sectionCard
                    required property var modelData
                    required property int index

                    property var filteredBinds: {
                        if (!modelData || !modelData.binds) return [];
                        if (root.searchQuery === "") return modelData.binds;
                        var q = root.searchQuery.toLowerCase();
                        return modelData.binds.filter(function(b) {
                            return (b.keys && b.keys.toLowerCase().includes(q))
                                || (b.desc && b.desc.toLowerCase().includes(q));
                        });
                    }

                    visible: filteredBinds.length > 0
                    width: Math.min(360, gridLayout.width / Math.max(1, Math.floor(gridLayout.width / 360)) - Colors.spacingLG)
                    height: sectionCol.implicitHeight + Colors.paddingLarge * 2
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1
                    radius: Colors.radiusMedium

                    InnerHighlight { highlightOpacity: 0.08 }

                    ColumnLayout {
                        id: sectionCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Colors.paddingLarge
                        spacing: Colors.spacingS

                        // Section title
                        Text {
                            text: modelData.section || "General"
                            color: Colors.primary
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.Black
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: Colors.letterSpacingWide
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.border
                            opacity: 0.5
                        }

                        // Keybind rows
                        Repeater {
                            model: sectionCard.filteredBinds
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: Colors.spacingM

                                // Key chord display
                                Row {
                                    spacing: 2
                                    Repeater {
                                        model: (modelData.keys || "").split("+")
                                        delegate: Rectangle {
                                            required property string modelData
                                            width: keyLabel.implicitWidth + 12
                                            height: 24
                                            radius: Colors.radiusXS
                                            color: Colors.primaryFaint
                                            border.color: Colors.primarySubtle
                                            border.width: 1

                                            Text {
                                                id: keyLabel
                                                anchors.centerIn: parent
                                                text: modelData.trim()
                                                color: Colors.primary
                                                font.pixelSize: Colors.fontSizeXS
                                                font.weight: Font.Bold
                                                font.family: Colors.fontMono
                                            }
                                        }
                                    }
                                }

                                // Description
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc || ""
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        Scrollbar { flickable: flickable }
        OverscrollGlow { flickable: flickable }
    }

    // Empty state
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.keybinds.length === 0 || (root.searchQuery !== "" && !_hasVisibleSections())
        spacing: Colors.spacingM
        opacity: 0.6

        function _hasVisibleSections() {
            for (var i = 0; i < root.keybinds.length; i++) {
                var section = root.keybinds[i];
                if (!section.binds) continue;
                var q = root.searchQuery.toLowerCase();
                for (var j = 0; j < section.binds.length; j++) {
                    var b = section.binds[j];
                    if ((b.keys && b.keys.toLowerCase().includes(q))
                        || (b.desc && b.desc.toLowerCase().includes(q)))
                        return true;
                }
            }
            return false;
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u{f030f}"
            color: Colors.textDisabled
            font.pixelSize: 64
            font.family: Colors.fontMono
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.searchQuery === "" ? "Loading keybindings..." : "No matches"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeLarge
            font.weight: Font.Medium
        }
    }
}

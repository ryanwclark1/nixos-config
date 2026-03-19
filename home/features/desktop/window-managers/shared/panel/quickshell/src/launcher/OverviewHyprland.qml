import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

ColumnLayout {
    id: content
    spacing: Colors.spacingLG

    signal closeRequested()

    Text {
        text: "Workspace Overview"
        color: Colors.text
        font.pixelSize: Colors.fontSizeIcon
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
    }

    ListView {
        id: workspaceList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: Hyprland.workspaces
        orientation: ListView.Horizontal
        spacing: Colors.spacingLG
        clip: true

        delegate: Rectangle {
            id: workspaceRect
            property var workspaceData: modelData

            width: 360
            height: workspaceList.height
            color: Colors.withAlpha(Colors.surface, 0.4)
            radius: Colors.radiusLarge
            border.color: workspaceData.active ? Colors.primary : Colors.border
            border.width: workspaceData.active ? 2 : 1

            gradient: SharedWidgets.SurfaceGradient {}

            SharedWidgets.InnerHighlight {
                hoveredOpacity: 0.25
                hovered: workspaceData.active
            }

            DropArea {
                anchors.fill: parent
                onDropped: drop => {
                    if (drop.source && drop.source.windowAddress) {
                        CompositorAdapter.moveWindowToWorkspace(drop.source.windowAddress, workspaceData.id);
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingMedium
                spacing: Colors.paddingSmall

                TextInput {
                    id: wsTitle
                    text: "Workspace " + workspaceData.name
                    color: workspaceData.active ? Colors.primary : Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    selectByMouse: true
                    onVisibleChanged: if (!visible && activeFocus)
                        focus = false

                    onEditingFinished: {
                        var newName = text.replace("Workspace ", "").trim();
                        if (newName !== workspaceData.name && newName !== "") {
                            CompositorAdapter.renameWorkspace(workspaceData.id, newName);
                        }
                        focus = false;
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    contentWidth: flow.implicitWidth
                    contentHeight: flow.implicitHeight

                    Flow {
                        id: flow
                        width: parent.width
                        spacing: Colors.paddingSmall

                        Repeater {
                            model: workspaceRect.workspaceData.toplevels

                            delegate: Rectangle {
                                id: windowCard
                                width: 155
                                height: 120
                                color: hoverArea.containsMouse ? Colors.primarySubtle : Colors.highlightLight
                                radius: Colors.radiusSmall
                                border.color: hoverArea.containsMouse ? Colors.primary : Colors.border
                                border.width: 1
                                Behavior on border.color {
                                    enabled: !Colors.isTransitioning
                                    CAnim {}
                                }
                                clip: true

                                SharedWidgets.InnerHighlight {
                                    hoveredOpacity: 0.3
                                    hovered: hoverArea.containsMouse
                                }

                                property string windowAddress: modelData.address

                                Drag.active: dragArea.drag.active
                                Drag.source: windowCard
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    spacing: 5

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: Colors.surface
                                        radius: Colors.radiusXS
                                        clip: true

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: modelData.wayland
                                            live: true
                                        }

                                        // Close Button
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: Colors.radiusCard
                                            color: Colors.error
                                            opacity: hoverArea.containsMouse ? 0.9 : 0.0
                                            visible: opacity > 0
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: Colors.spacingXS
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Colors.durationFast
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅖"
                                                color: Colors.text
                                                font.family: Colors.fontMono
                                                font.pixelSize: Colors.fontSizeMedium
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    CompositorAdapter.closeWindow(modelData.address);
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.title
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeXS
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        content.closeRequested();
                                        CompositorAdapter.focusWindow(modelData.address);
                                    }
                                }

                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    drag.target: windowCard
                                    drag.axis: Drag.XAndYAxis
                                    onReleased: windowCard.Drag.drop()

                                    // Pass clicks through to hoverArea
                                    onClicked: hoverArea.clicked(mouse)
                                }

                                // Reset position after drag
                                onXChanged: if (!dragArea.drag.active)
                                    x = 0
                                onYChanged: if (!dragArea.drag.active)
                                    y = 0
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        text: "Drag windows to move them between workspaces. Press Escape to close."
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeMedium
        Layout.alignment: Qt.AlignHCenter
    }
}

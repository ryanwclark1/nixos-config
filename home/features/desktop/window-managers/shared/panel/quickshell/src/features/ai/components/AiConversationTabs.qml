import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

// Horizontal tab bar showing all AI conversations with add/delete/rename controls.
// All interactions go directly to the AiService singleton.
RowLayout {
    id: root
    spacing: Colors.spacingS

    // Scrollable tab strip
    Item {
        Layout.fillWidth: true
        height: 38
        clip: true

        Flickable {
            id: tabFlickable
            anchors.fill: parent
            contentWidth: tabRow.implicitWidth + 32
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Row {
                id: tabRow
                spacing: Colors.spacingS
                height: parent.height
                leftPadding: Colors.spacingS
                rightPadding: Colors.spacingS
                topPadding: 3

                Repeater {
                    model: AiService.conversations

                    delegate: Item {
                        id: tabDelegate
                        required property var modelData
                        required property int index
                        property bool isActive: modelData.id === AiService.activeConversationId
                        property bool isEditing: false

                        width: isEditing ? tabEditInput.width + 16 : Math.min(tabLabelText.contentWidth + (isActive ? 44 : 38), 160)
                        height: 32

                        Behavior on width {
                            NumberAnimation {
                                duration: Colors.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        // Auto-scroll to make the active tab visible
                        onIsActiveChanged: {
                            if (isActive) {
                                if (x < tabFlickable.contentX) {
                                    tabFlickable.contentX = x - 16;
                                } else if (x + width > tabFlickable.contentX + tabFlickable.width) {
                                    tabFlickable.contentX = x + width - tabFlickable.width + 16;
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Colors.radiusSmall
                            color: isActive ? Colors.withAlpha(Colors.primary, 0.15) : (tabMouse.containsMouse ? Colors.withAlpha(Colors.text, 0.05) : "transparent")
                            border.color: isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.withAlpha(Colors.text, 0.25) : Colors.border)
                            border.width: isActive ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                            Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

                            SharedWidgets.StateLayer {
                                id: tabStateLayer
                                hovered: tabMouse.containsMouse
                                pressed: tabMouse.pressed
                            }
                        }

                        // Active indicator underline
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 1.5
                            width: isActive ? parent.width - 20 : 0
                            height: 2
                            radius: Colors.radiusXXXS
                            color: Colors.primary
                            opacity: isActive ? 1 : 0
                            visible: width > 0

                            Behavior on width {
                                NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: Colors.durationFast }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingS
                            anchors.rightMargin: 6
                            spacing: Colors.spacingXS

                            // Streaming activity dot
                            Rectangle {
                                width: 6
                                height: 6
                                radius: Colors.radiusXS
                                color: Colors.primary
                                visible: isActive && AiService.isStreaming
                                Layout.alignment: Qt.AlignVCenter

                                OpacityAnimator on opacity {
                                    from: 0.3
                                    to: 1.0
                                    duration: 600
                                    running: isActive && AiService.isStreaming
                                    loops: Animation.Infinite
                                }
                            }

                            Text {
                                id: tabLabelText
                                Layout.fillWidth: true
                                text: modelData.title
                                color: isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.text : Colors.textSecondary)
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: isActive ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                visible: !tabDelegate.isEditing
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        TextInput {
                            id: tabEditInput
                            anchors.left: parent.left
                            anchors.leftMargin: Colors.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(60, contentWidth + 4)
                            text: modelData.title
                            color: Colors.primary
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            visible: tabDelegate.isEditing
                            selectByMouse: true
                            onVisibleChanged: if (visible) {
                                selectAll();
                                forceActiveFocus();
                            }
                            Keys.onReturnPressed: {
                                AiService.renameConversation(modelData.id, text);
                                tabDelegate.isEditing = false;
                            }
                            Keys.onEscapePressed: tabDelegate.isEditing = false
                            onEditingFinished: {
                                AiService.renameConversation(modelData.id, text);
                                tabDelegate.isEditing = false;
                            }
                        }

                        Rectangle {
                            id: deleteTabBtn
                            width: 16
                            height: 16
                            radius: width / 2
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"
                            opacity: (tabMouse.containsMouse || tabDelegate.isActive) && AiService.conversations.length > 1 ? 1 : 0
                            visible: AiService.conversations.length > 1
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Colors.durationFast
                                }
                            }

                            SharedWidgets.StateLayer {
                                id: deleteTabStateLayer
                                hovered: deleteTabMouse.containsMouse
                                pressed: deleteTabMouse.pressed
                                stateColor: Colors.error
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: deleteTabMouse.containsMouse ? "white" : Colors.textDisabled
                                font.family: Colors.fontMono
                                font.pixelSize: 10
                            }
                            MouseArea {
                                id: deleteTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    deleteTabStateLayer.burst(mouse.x, mouse.y);
                                    mouse.accepted = true;
                                    AiService.deleteConversation(modelData.id);
                                }
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                tabStateLayer.burst(mouse.x, mouse.y);
                                if (mouse.button === Qt.RightButton) {
                                    tabDelegate.isEditing = true;
                                    return;
                                }
                                if (!tabDelegate.isEditing)
                                    AiService.setActiveConversation(modelData.id);
                            }
                            onDoubleClicked: tabDelegate.isEditing = true
                        }

                        SharedWidgets.BarTooltip {
                            text: modelData.title
                            hovered: tabMouse.containsMouse && tabLabelText.truncated
                            anchorItem: tabDelegate
                        }
                    }
                }
            }
        }
    }

    // "+" new conversation button
    Rectangle {
        width: 32
        height: 32
        radius: Colors.radiusSmall
        color: addConvMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.1) : Colors.bgWidget
        border.color: addConvMouse.containsMouse ? Colors.primary : Colors.border
        border.width: 1
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: Colors.spacingXS

        Text {
            anchors.centerIn: parent
            text: "+"
            color: addConvMouse.containsMouse ? Colors.primary : Colors.textSecondary
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.Light
        }
        SharedWidgets.StateLayer {
            id: addConvStateLayer
            hovered: addConvMouse.containsMouse
            pressed: addConvMouse.pressed
        }
        MouseArea {
            id: addConvMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                addConvStateLayer.burst(mouse.x, mouse.y);
                AiService.newConversation();
            }
        }
    }
}

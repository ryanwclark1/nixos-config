import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

Scope {
  id: root

  property bool isVisible: NiriService.inOverview

  // Group windows by workspace
  readonly property var workspaceWindows: {
    var result = {};
    var allWs = NiriService.allWorkspaces;
    for (var i = 0; i < allWs.length; i++)
      result[allWs[i].id] = [];
    var wins = NiriService.windows;
    for (var w = 0; w < wins.length; w++) {
      var wsId = wins[w].workspace_id;
      if (!result[wsId]) result[wsId] = [];
      result[wsId].push(wins[w]);
    }
    return result;
  }

  property string searchQuery: ""

  onIsVisibleChanged: {
    if (!isVisible) searchQuery = "";
  }

  IpcHandler {
    target: "Overview"
    function toggle() {
      CompositorAdapter.toggleOverview();
    }
    function show() {
      if (!root.isVisible) CompositorAdapter.toggleOverview();
    }
    function hide() {
      if (root.isVisible) CompositorAdapter.toggleOverview();
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      LazyLoader {
        active: root.isVisible
        required property ShellScreen modelData

        PanelWindow {
          id: overviewWindow
          screen: modelData
          visible: root.isVisible

          anchors {
            top: true; left: true; right: true; bottom: true
          }
          color: "transparent"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.namespace: "quickshell-overview"
          WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
          exclusiveZone: -1

          onVisibleChanged: if (visible) mainRect.forceActiveFocus()

          Rectangle {
            id: mainRect
            anchors.fill: parent
            color: Colors.bgGlass
            focus: true

            opacity: 0.0
            Component.onCompleted: { opacity = 1.0; forceActiveFocus(); }
            Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.InOutQuad } }

            MouseArea {
              anchors.fill: parent
              onClicked: CompositorAdapter.toggleOverview()
            }

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape) {
                CompositorAdapter.toggleOverview();
                event.accepted = true;
              }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 40
              spacing: Colors.spacingLG

              // Search bar
              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(400, parent.width * 0.5)
                Layout.preferredHeight: 44
                radius: Colors.radiusPill
                color: Colors.surface
                border.color: searchInput.activeFocus ? Colors.primary : Colors.border
                border.width: searchInput.activeFocus ? 2 : 1

                Row {
                  anchors.centerIn: parent
                  spacing: Colors.spacingS

                  Text {
                    text: ""
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeLarge
                    font.family: Colors.fontMono
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  TextInput {
                    id: searchInput
                    width: Math.min(320, overviewWindow.width * 0.4)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    clip: true
                    onTextChanged: root.searchQuery = text.toLowerCase()
                    anchors.verticalCenter: parent.verticalCenter

                    Keys.onEscapePressed: {
                      if (text !== "") {
                        text = "";
                      } else {
                        CompositorAdapter.toggleOverview();
                      }
                    }

                    Text {
                      visible: !searchInput.text
                      text: "Search windows..."
                      color: Colors.textDisabled
                      font.pixelSize: Colors.fontSizeMedium
                    }
                  }
                }
              }

              // Workspace columns
              Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: wsRow.width
                contentHeight: height
                clip: true
                flickableDirection: Flickable.HorizontalFlick

                Row {
                  id: wsRow
                  spacing: Colors.spacingXL
                  height: parent.height

                  Repeater {
                    model: NiriService.allWorkspaces

                    delegate: Rectangle {
                      id: wsColumn
                      readonly property var ws: modelData
                      readonly property int wsIndex: index
                      readonly property bool isFocused: ws.is_focused

                      // Staggered entry animation
                      opacity: 0
                      transform: Translate { id: wsSlide; y: 20; Behavior on y { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } } }
                      Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

                      Timer {
                        running: true; interval: wsColumn.wsIndex * 60
                        onTriggered: { wsColumn.opacity = 1; wsSlide.y = 0; }
                      }
                      readonly property var wsWindows: {
                        var all = root.workspaceWindows[ws.id] || [];
                        if (root.searchQuery === "") return all;
                        return all.filter(function(w) {
                          return (w.title || "").toLowerCase().indexOf(root.searchQuery) !== -1
                                 || (w.app_id || "").toLowerCase().indexOf(root.searchQuery) !== -1;
                        });
                      }

                      width: Math.max(280, Math.min(400, overviewWindow.width / Math.max(NiriService.allWorkspaces.length, 1) - Colors.spacingXL))
                      height: parent.height
                      radius: Colors.radiusLarge
                      color: Colors.surface
                      border.color: isFocused ? Colors.primary : Colors.border
                      border.width: isFocused ? 2 : 1

                      ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Colors.paddingMedium
                        spacing: Colors.spacingM

                        // Workspace header
                        Text {
                          text: ws.name || ("Workspace " + (ws.idx || ws.id))
                          color: wsColumn.isFocused ? Colors.primary : Colors.text
                          font.pixelSize: Colors.fontSizeXL
                          font.weight: Font.Bold
                          Layout.alignment: Qt.AlignHCenter
                        }

                        // Window count
                        Text {
                          text: wsColumn.wsWindows.length + " window" + (wsColumn.wsWindows.length !== 1 ? "s" : "")
                          color: Colors.textSecondary
                          font.pixelSize: Colors.fontSizeXS
                          Layout.alignment: Qt.AlignHCenter
                        }

                        // Window list
                        Flickable {
                          Layout.fillWidth: true
                          Layout.fillHeight: true
                          contentHeight: windowCol.height
                          clip: true
                          flickableDirection: Flickable.VerticalFlick

                          SharedWidgets.OverscrollGlow {
                            flickable: parent
                            glowColor: Colors.primary
                          }

                          Column {
                            id: windowCol
                            width: parent.width
                            spacing: Colors.spacingS

                            Repeater {
                              model: wsColumn.wsWindows

                              delegate: Rectangle {
                                id: windowCard
                                width: windowCol.width
                                height: 56
                                radius: Colors.radiusSmall
                                color: modelData.is_focused
                                       ? Colors.withAlpha(Colors.primary, 0.15)
                                       : (cardMouse.containsMouse ? Colors.highlightLight : "transparent")
                                border.color: modelData.is_focused ? Colors.primary : "transparent"
                                border.width: modelData.is_focused ? 1 : 0

                                // Card-level mouse area (z-bottom so close button stays clickable)
                                MouseArea {
                                  id: cardMouse
                                  anchors.fill: parent
                                  hoverEnabled: true
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: {
                                    CompositorAdapter.focusWindow(modelData.id);
                                    CompositorAdapter.toggleOverview();
                                  }
                                }

                                Row {
                                  anchors.fill: parent
                                  anchors.margins: Colors.spacingS
                                  spacing: Colors.spacingM

                                  SharedWidgets.AppIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    iconName: modelData.app_id || ""
                                    appName: modelData.title || modelData.app_id || ""
                                    iconSize: 32
                                  }

                                  Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 32 - Colors.spacingM * 2 - closeBtn.width
                                    spacing: 2

                                    Text {
                                      width: parent.width
                                      text: modelData.title || "Untitled"
                                      color: Colors.text
                                      font.pixelSize: Colors.fontSizeSmall
                                      elide: Text.ElideRight
                                    }

                                    Text {
                                      width: parent.width
                                      text: modelData.app_id || ""
                                      color: Colors.textSecondary
                                      font.pixelSize: Colors.fontSizeXS
                                      elide: Text.ElideRight
                                    }
                                  }
                                }

                                // Close button (above cardMouse in z-stack)
                                Text {
                                  id: closeBtn
                                  anchors.right: parent.right
                                  anchors.top: parent.top
                                  anchors.margins: Colors.spacingS
                                  text: "󰅙"
                                  color: closeMouse.containsMouse ? Colors.error : Colors.textSecondary
                                  font.pixelSize: Colors.fontSizeLarge
                                  font.family: Colors.fontMono
                                  visible: cardMouse.containsMouse

                                  MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CompositorAdapter.closeWindow(modelData.id)
                                  }
                                }
                              }
                            }

                            // Empty state
                            Text {
                              visible: wsColumn.wsWindows.length === 0
                              text: root.searchQuery ? "No matches" : "Empty"
                              color: Colors.textDisabled
                              font.pixelSize: Colors.fontSizeSmall
                              anchors.horizontalCenter: parent.horizontalCenter
                              topPadding: Colors.spacingXL
                            }
                          }
                        }
                      }

                      // Click empty area to switch workspace
                      MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                          CompositorAdapter.focusWorkspace(ws.idx || ws.id);
                          CompositorAdapter.toggleOverview();
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

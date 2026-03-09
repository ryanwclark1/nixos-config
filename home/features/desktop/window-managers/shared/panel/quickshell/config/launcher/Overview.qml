import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland._Ipc
import Quickshell.Wayland._Screencopy
import Quickshell.Widgets
import Quickshell.Wayland

Scope {
	id: root

	property bool isVisible: false

	IpcHandler {
		target: "Overview"
		function toggle() {
			root.isVisible = !root.isVisible;
		}
		function show() {
			root.isVisible = true;
		}
		function hide() {
			root.isVisible = false;
		}
	}

	// Hotkey to dismiss when clicking outside or pressing Escape
	// If HyprlandFocusGrab works, we can grab focus, but we'll start with a simple overlay.
	
	Repeater {
		model: Quickshell.screens

		delegate: LazyLoader {
			active: root.isVisible

			PanelWindow {
				id: overviewWindow
				screen: modelData

				anchors {
					top: true
					left: true
					right: true
					bottom: true
				}
				color: "transparent"
				WlrLayershell.layer: WlrLayer.Overlay
				WlrLayershell.namespace: "quickshell"
				WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
				
				// Take up the whole screen to capture clicks outside
				exclusiveZone: -1

				Rectangle {
					anchors.fill: parent
					color: "#a6101014"
					
					opacity: root.isVisible ? 1.0 : 0.0
					Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

					MouseArea {
						anchors.fill: parent
						onClicked: root.isVisible = false
					}

					GridView {
						id: grid
						anchors.centerIn: parent
						width: Math.min(parent.width * 0.8, cellWidth * 3)
						height: Math.min(parent.height * 0.8, cellHeight * Math.ceil(count / 3))
						
						cellWidth: 320
						cellHeight: 240
						
						model: Hyprland.toplevels
						
						focus: true
						currentIndex: 0
						
						Keys.onEscapePressed: root.isVisible = false
						Keys.onReturnPressed: {
							if (currentIndex >= 0 && currentIndex < count) {
								let addr = Hyprland.toplevels[currentIndex].address;
								if (addr) {
									root.isVisible = false;
									Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + addr]);
								}
							}
						}
						
						// Filter out special workspaces or quickshell itself if needed
						// We'll show all normal windows for now
						
						delegate: Rectangle {
							width: 300
							height: 220
							color: "#33ffffff"
							radius: 12
							
							property bool isSelected: grid.currentIndex === index
							border.color: isSelected ? "#4caf50" : (hoverArea.containsMouse ? "#ffffff" : "#44ffffff")
							border.width: isSelected || hoverArea.containsMouse ? 3 : 1
							
							// Animation on hover or selection
							scale: isSelected || hoverArea.containsMouse ? 1.05 : 1.0
							Behavior on scale { NumberAnimation { duration: 150 } }

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 10
								spacing: 10

								Rectangle {
									Layout.fillWidth: true
									Layout.fillHeight: true
									color: "transparent"
									clip: true
									radius: 8
									
									ScreencopyView {
										anchors.fill: parent
										captureSource: modelData.wayland
										live: true
									}
								}

								RowLayout {
									Layout.fillWidth: true
									spacing: 8
									
									Image {
										// We could load an icon based on class name, but title is fine for now
										source: "" 
										Layout.preferredWidth: 24
										Layout.preferredHeight: 24
										visible: false
									}
									
									Text {
										text: modelData.title
										color: "white"
										font.pointSize: 10
										font.bold: true
										elide: Text.ElideRight
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
									}
								}
							}

							MouseArea {
								id: hoverArea
								anchors.fill: parent
								hoverEnabled: true
								onClicked: {
									grid.currentIndex = index;
									root.isVisible = false;
									Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]);
								}
							}
						}
					}
					
					// Instruction text
					Text {
						anchors.bottom: parent.bottom
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.margins: 40
						text: "Use Arrow Keys + Enter to select, or click outside/Escape to cancel"
						color: "#88ffffff"
						font.pointSize: 12
					}
				}
				
				// Global Escape handler fallback if grid loses focus
				Item {
					anchors.fill: parent
					focus: false
				}
			}
		}
	}
}

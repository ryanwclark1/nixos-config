import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import Quickshell.Widgets
import Quickshell.Wayland
import "../services" // Import Colors

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

	Repeater {
		model: Quickshell.screens

		delegate: LazyLoader {
			active: root.isVisible

			PanelWindow {
				id: overviewWindow
				screen: modelData
				visible: root.isVisible

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
				
				exclusiveZone: -1

				Rectangle {
					id: mainRect
					anchors.fill: parent
					color: Colors.bgGlass
					
					opacity: 0.0
					Component.onCompleted: opacity = 1.0
					Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

					MouseArea {
						anchors.fill: parent
						onClicked: root.isVisible = false
					}

					ColumnLayout {
						anchors.fill: parent
						anchors.margins: 40
						spacing: 20

						Text {
							text: "Workspace Overview"
							color: Colors.text
							font.pixelSize: 32
							font.weight: Font.Bold
							Layout.alignment: Qt.AlignHCenter
						}

						ListView {
							id: workspaceList
							Layout.fillWidth: true
							Layout.fillHeight: true
							model: Hyprland.workspaces
							orientation: ListView.Horizontal
							spacing: 20
							clip: true
							
							delegate: Rectangle {
								id: workspaceRect
								property var workspaceData: modelData
								
								width: 360
								height: workspaceList.height
								color: Colors.surface
								radius: Colors.radiusLarge
								border.color: workspaceData.active ? Colors.primary : Colors.border
								border.width: workspaceData.active ? 2 : 1
								
								DropArea {
									anchors.fill: parent
									onDropped: (drop) => {
										if (drop.source && drop.source.windowAddress) {
											Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", workspaceData.id + ",address:" + drop.source.windowAddress]);
										}
									}
								}

								ColumnLayout {
									anchors.fill: parent
									anchors.margins: Colors.paddingMedium
									spacing: 10

									TextInput {
										id: wsTitle
										text: "Workspace " + workspaceData.name
										color: workspaceData.active ? Colors.primary : Colors.text
										font.pixelSize: 18
										font.weight: Font.Bold
										Layout.alignment: Qt.AlignHCenter
										selectByMouse: true
										
										onEditingFinished: {
											var newName = text.replace("Workspace ", "").trim();
											if (newName !== workspaceData.name && newName !== "") {
												Quickshell.execDetached(["hyprctl", "dispatch", "renameworkspace", workspaceData.id + " " + newName]);
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
											spacing: 10
											
											Repeater {
												model: Hyprland.toplevels
												
												delegate: Rectangle {
													id: windowCard
													visible: modelData.workspace && modelData.workspace.id === workspaceRect.workspaceData.id
													width: visible ? 155 : 0
													height: visible ? 120 : 0
													color: Colors.highlightLight
													radius: Colors.radiusSmall
													border.color: hoverArea.containsMouse ? Colors.text : Colors.border
													border.width: 1
													clip: true
													
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
															radius: 4
															clip: true
															
															ScreencopyView {
																anchors.fill: parent
																captureSource: modelData.wayland
																live: true
															}
															
															// Close Button
															Rectangle {
																width: 24; height: 24; radius: 12
																color: Colors.error
																opacity: hoverArea.containsMouse ? 0.9 : 0.0
																anchors.top: parent.top; anchors.right: parent.right
																anchors.margins: 4
																Behavior on opacity { NumberAnimation { duration: 150 } }
																
																Text {
																	anchors.centerIn: parent
																	text: "󰅖"
																	color: Colors.text
																	font.family: Colors.fontMono
																	font.pixelSize: 14
																}
																
																MouseArea {
																	anchors.fill: parent
																	hoverEnabled: true
																	onClicked: {
																		Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + modelData.address]);
																	}
																}
															}
														}
														
														Text {
															text: modelData.title
															color: Colors.text
															font.pixelSize: 10
															elide: Text.ElideRight
															Layout.fillWidth: true
															horizontalAlignment: Text.AlignHCenter
														}
													}
													
													MouseArea {
														id: hoverArea
														anchors.fill: parent
														hoverEnabled: true
														onClicked: {
															root.isVisible = false;
															Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]);
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
													onXChanged: if (!dragArea.drag.active) x = 0
													onYChanged: if (!dragArea.drag.active) y = 0
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
							font.pixelSize: 14
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}
				
				Keys.onEscapePressed: root.isVisible = false
				Component.onCompleted: forceActiveFocus()
				onVisibleChanged: if(visible) forceActiveFocus()
			}
		}
	}
}

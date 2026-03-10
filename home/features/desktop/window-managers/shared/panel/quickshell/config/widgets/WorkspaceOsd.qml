import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland._Ipc
import Quickshell.Widgets
import Quickshell.Wayland
import "../services"

Scope {
	id: root
	property bool shouldShowOsd: false
	property string workspaceName: ""
	property bool isSpecial: false
	property bool initialized: false
	
	Timer {
		id: hideTimer
		interval: 1500
		onTriggered: root.shouldShowOsd = false
	}
	
	Connections {
		target: Hyprland
		
		function onFocusedWorkspaceChanged() {
			if (Hyprland.focusedWorkspace) {
				root.workspaceName = Hyprland.focusedWorkspace.name;
				root.isSpecial = root.workspaceName.startsWith("special");
				if (root.isSpecial) {
					root.workspaceName = root.workspaceName.replace("special:", "Special: ");
				}
				
				// Don't show OSD on initial load
				if (!root.initialized) {
					root.initialized = true;
					return;
				}
				root.shouldShowOsd = true;
				hideTimer.restart();
			}
		}
	}

	Repeater {
		model: Quickshell.screens

		delegate: LazyLoader {
			active: root.shouldShowOsd && (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === modelData.name : true)

			PanelWindow {
				id: osdWindow
				screen: modelData

				// PanelWindow anchoring doesn't support centerIn; place it manually instead.
				anchors.top: true
				margins.top: screen.height / 2 - implicitHeight / 2
				anchors.left: true
				margins.left: screen.width / 2 - implicitWidth / 2
				
				exclusiveZone: 0

				implicitWidth: 200
				implicitHeight: 200
				color: "transparent"

				mask: Region {
					item: content
				}


				Rectangle {
					id: content
					anchors.fill: parent
					radius: 20
					color: Colors.withAlpha(Colors.background, 0.6)
					border.color: Colors.border
					border.width: 1
					
					opacity: root.shouldShowOsd ? 1.0 : 0.0
					Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

					ColumnLayout {
						anchors.centerIn: parent
						spacing: 20

						IconImage {
							Layout.alignment: Qt.AlignHCenter
							implicitSize: 64
							source: Quickshell.iconPath(root.isSpecial ? "view-pin-symbolic" : "desktop-symbolic") || ""
						}

						Text {
							Layout.alignment: Qt.AlignHCenter
							text: root.workspaceName
							color: Colors.text
							font.pointSize: 24
							font.bold: true
						}
					}
				}
			}
		}
	}
}

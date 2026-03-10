import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Wayland
import "../services"

Scope {
	id: root
	property bool shouldShowOsd: false
	
	property string trackTitle: ""
	property string trackArtist: ""
	property string trackArtUrl: ""
	property bool isPlaying: false
	
	Timer {
		id: hideTimer
		interval: 3000
		onTriggered: root.shouldShowOsd = false
	}
	
	Instantiator {
		model: Mpris.players
		delegate: Connections {
			target: modelData
			
			function onTrackTitleChanged() {
				if (modelData.isPlaying) {
					root.trackTitle = modelData.trackTitle;
					root.trackArtist = modelData.trackArtist;
					root.trackArtUrl = modelData.trackArtUrl;
					root.isPlaying = modelData.isPlaying;
					root.shouldShowOsd = true;
					hideTimer.restart();
				}
			}
			
			function onPlaybackStateChanged() {
				root.trackTitle = modelData.trackTitle;
				root.trackArtist = modelData.trackArtist;
				root.trackArtUrl = modelData.trackArtUrl;
				root.isPlaying = modelData.isPlaying;
				root.shouldShowOsd = true;
				hideTimer.restart();
			}
		}
	}

	Repeater {
		model: Quickshell.screens

		delegate: LazyLoader {
			active: root.shouldShowOsd

			PanelWindow {
				id: osdWindow
				screen: modelData

				anchors.top: true
				margins.top: screen.height / 10
				exclusiveZone: 0

				implicitWidth: 350
				implicitHeight: 80
				color: "transparent"
				WlrLayershell.layer: WlrLayer.Overlay
				WlrLayershell.namespace: "quickshell"

				mask: Region {
					item: content
				}

				Rectangle {
					id: content
					anchors.fill: parent
					radius: 12
					color: Colors.bgGlass
					border.color: Colors.border
					border.width: 1

					opacity: root.shouldShowOsd ? 1.0 : 0.0
					Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

					RowLayout {
						anchors.fill: parent
						anchors.margins: Colors.paddingSmall
						spacing: 12

						Image {
							Layout.preferredWidth: 60
							Layout.preferredHeight: 60
							source: root.trackArtUrl !== "" ? root.trackArtUrl : ""
							fillMode: Image.PreserveAspectCrop
							visible: root.trackArtUrl !== ""
							
							Rectangle {
								anchors.fill: parent
								color: "transparent"
								border.color: Colors.border
								border.width: 1
								radius: 6
							}
						}

						ColumnLayout {
							Layout.fillWidth: true
							spacing: 4

							Text {
								text: root.trackTitle !== "" ? root.trackTitle : "No Media"
								color: Colors.text
								font.pointSize: 12
								font.bold: true
								elide: Text.ElideRight
								Layout.fillWidth: true
							}

							Text {
								text: root.trackArtist !== "" ? root.trackArtist : "Unknown Artist"
								color: Colors.textSecondary
								font.pointSize: 10
								elide: Text.ElideRight
								Layout.fillWidth: true
							}
						}
						
						IconImage {
							Layout.preferredWidth: 24
							Layout.preferredHeight: 24
							source: Quickshell.iconPath(root.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic") || ""
						}
					}
				}
			}
		}
	}
}

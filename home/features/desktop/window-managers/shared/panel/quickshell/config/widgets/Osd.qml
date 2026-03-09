import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root

	// Bind the pipewire node so its volume will be tracked
	PwObjectTracker {
		objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
	}

	Connections {
		target: Pipewire.defaultAudioSink !== null ? Pipewire.defaultAudioSink.audio : null

		function onVolumeChanged() {
			root.osdType = "volume";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}

		function onMutedChanged() {
			root.osdType = "volume";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}

	Connections {
		target: Pipewire.defaultAudioSource !== null ? Pipewire.defaultAudioSource.audio : null

		function onMutedChanged() {
			root.osdType = "mic";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}

		function onVolumeChanged() {
			root.osdType = "mic";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}

	IpcHandler {
		target: "Osd"
		function showCapslock(state: string) {
			root.capslockState = (state === "on");
			root.osdType = "capslock";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}

		function showBrightness(percent: string) {
			var val = parseFloat(percent);
			if (isNaN(val)) val = 0;
			root.brightnessValue = val / 100.0;
			root.osdType = "brightness";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}

	property bool shouldShowOsd: false
	property string osdType: "volume"
	property bool capslockState: false
	property real brightnessValue: 0.0

	Timer {
		id: hideTimer
		interval: 2000
		onTriggered: root.shouldShowOsd = false
	}

	// Iterate over all screens to show the OSD everywhere
	Repeater {
		model: Quickshell.screens

		delegate: LazyLoader {
			active: root.shouldShowOsd

			PanelWindow {
				id: osdWindow
				screen: modelData

				anchors.bottom: true
				margins.bottom: screen.height / 5
				exclusiveZone: 0

				implicitWidth: 400
				implicitHeight: 50
				color: "transparent"

				mask: Region {}


				Rectangle {
					anchors.fill: parent
					radius: height / 2
					color: "#a6101014"
					border.color: "#33ffffff"
					border.width: 1

					// Fade animation
					opacity: root.shouldShowOsd ? 1.0 : 0.0
					Behavior on opacity {
						NumberAnimation {
							duration: 200
							easing.type: Easing.InOutQuad
						}
					}
					RowLayout {
						anchors {
							fill: parent
							leftMargin: 15
							rightMargin: 15
						}
						spacing: 12

						IconImage {
							implicitSize: 24
							source: {
								if (root.osdType === "capslock") {
									return Quickshell.iconPath(root.capslockState ? "keyboard-caps-lock-symbolic" : "keyboard-symbolic") || "";
								} else if (root.osdType === "brightness") {
									return Quickshell.iconPath("display-brightness-symbolic") || "";
								} else if (root.osdType === "mic") {
									return Quickshell.iconPath((Pipewire.defaultAudioSource?.audio.muted ?? false) ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic") || "";
								} else {
									return Quickshell.iconPath((Pipewire.defaultAudioSink?.audio.muted ?? false) ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic") || "";
								}
							}
						}

						Text {
							visible: root.osdType === "capslock"
							text: "Caps Lock " + (root.capslockState ? "On" : "Off")
							color: "white"
							font.pointSize: 14
							font.bold: true
							Layout.fillWidth: true
							horizontalAlignment: Text.AlignHCenter
						}

						Rectangle {
							visible: root.osdType === "volume" || root.osdType === "brightness" || root.osdType === "mic"
							Layout.fillWidth: true
							implicitHeight: 8
							radius: height / 2
							color: "#40ffffff"
							clip: true

							Rectangle {
								anchors {
									left: parent.left
									top: parent.top
									bottom: parent.bottom
								}

								implicitWidth: {
									if (root.osdType === "brightness") return parent.width * root.brightnessValue;
									if (root.osdType === "mic") return parent.width * (Pipewire.defaultAudioSource?.audio.volume ?? 0);
									return parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0);
								}
								radius: parent.radius
								color: "white"

								Behavior on implicitWidth {
									NumberAnimation {
										duration: 150
										easing.type: Easing.OutCubic
									}
								}
							}
							
							MouseArea {
								anchors.fill: parent
								onPositionChanged: (mouse) => {
									if (pressed) {
										let val = Math.max(0, Math.min(1, mouse.x / width));
										if (root.osdType === "brightness") {
											Quickshell.execDetached(["brightnessctl", "set", Math.round(val * 100) + "%"]);
											root.brightnessValue = val;
										} else if (root.osdType === "mic") {
											if (Pipewire.defaultAudioSource) Pipewire.defaultAudioSource.audio.volume = val;
										} else {
											if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = val;
										}
										hideTimer.restart();
									}
								}
								onClicked: (mouse) => {
									let val = Math.max(0, Math.min(1, mouse.x / width));
									if (root.osdType === "brightness") {
										Quickshell.execDetached(["brightnessctl", "set", Math.round(val * 100) + "%"]);
										root.brightnessValue = val;
									} else if (root.osdType === "mic") {
										if (Pipewire.defaultAudioSource) Pipewire.defaultAudioSource.audio.volume = val;
									} else {
										if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = val;
									}
									hideTimer.restart();
								}
							}
						}
						
						Text {
							visible: root.osdType === "volume" || root.osdType === "brightness" || root.osdType === "mic"
							text: {
								if (root.osdType === "brightness") return Math.round(root.brightnessValue * 100) + "%";
								if (root.osdType === "mic") {
									if (Pipewire.defaultAudioSource?.audio.muted) return "Muted";
									return Math.round((Pipewire.defaultAudioSource?.audio.volume ?? 0) * 100) + "%";
								}
								if (Pipewire.defaultAudioSink?.audio.muted) return "Muted";
								return Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%";
							}
							color: "white"
							font.pointSize: 12
							font.bold: true
							Layout.preferredWidth: 45
							horizontalAlignment: Text.AlignRight
						}
					}
				}
			}
		}
	}
}

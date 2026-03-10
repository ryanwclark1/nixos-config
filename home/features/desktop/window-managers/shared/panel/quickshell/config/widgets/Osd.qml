import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Wayland
import "../modules"
import "../services"

Scope {
	id: root

	PwObjectTracker {
		objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
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
			SystemStatus.brightness = val / 100.0;
			root.osdType = "brightness";
			root.shouldShowOsd = true;
			hideTimer.restart();
		}
	}

	property bool shouldShowOsd: false
	property string osdType: "volume"
	property bool capslockState: false
	property real sinkVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
	property bool sinkMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
	property real sourceVolume: Pipewire.defaultAudioSource?.audio?.volume ?? 0
	property bool sourceMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false

	onSinkVolumeChanged: {
		root.osdType = "volume";
		root.shouldShowOsd = true;
		hideTimer.restart();
	}

	onSinkMutedChanged: {
		root.osdType = "volume";
		root.shouldShowOsd = true;
		hideTimer.restart();
	}

	onSourceVolumeChanged: {
		root.osdType = "mic";
		root.shouldShowOsd = true;
		hideTimer.restart();
	}

	onSourceMutedChanged: {
		root.osdType = "mic";
		root.shouldShowOsd = true;
		hideTimer.restart();
	}

	Timer {
		id: hideTimer
		interval: 2000
		onTriggered: root.shouldShowOsd = false
	}

	Repeater {
		model: Quickshell.screens

		delegate: LazyLoader {
			active: root.shouldShowOsd

			PanelWindow {
				id: osdWindow
				screen: modelData

				anchors.top: true
				margins.top: screen.height / 2 - implicitHeight / 2
				anchors.left: true
				margins.left: screen.width / 2 - implicitWidth / 2
				exclusiveZone: 0

				implicitWidth: 120
				implicitHeight: 120
				color: "transparent"
				WlrLayershell.layer: WlrLayer.Overlay
				WlrLayershell.namespace: "quickshell"

				mask: Region {
					item: content
				}

				Rectangle {
					id: content
					anchors.fill: parent
					radius: 24
					color: Colors.bgGlass
					border.color: Colors.border
					border.width: 1

					opacity: root.shouldShowOsd ? 1.0 : 0.0
					scale: root.shouldShowOsd ? 1.0 : 0.8

					Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
					Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

					ColumnLayout {
						anchors.fill: parent
						anchors.margins: 15
						spacing: 8

						CircularGauge {
							Layout.alignment: Qt.AlignHCenter
							width: 48
							height: 48
							thickness: 4
							value: {
								if (root.osdType === "brightness") return SystemStatus.brightness;
								if (root.osdType === "mic") return root.sourceVolume;
								if (root.osdType === "capslock") return root.capslockState ? 1.0 : 0.0;
								return root.sinkVolume;
							}
							color: {
								if (root.osdType === "capslock") return root.capslockState ? Colors.primary : Colors.fgDim;
								if (root.osdType === "mic" && root.sourceMuted) return Colors.error;
								if (root.osdType === "volume" && root.sinkMuted) return Colors.error;
								return Colors.primary;
							}
							icon: {
								if (root.osdType === "capslock") return root.capslockState ? "󰬶" : "󰬵";
								if (root.osdType === "brightness") return "󰃠";
								if (root.osdType === "mic") return root.sourceMuted ? "󰍭" : "󰍬";
								if (root.osdType === "volume") return root.sinkMuted ? "󰝟" : "󰕾";
								return "";
							}
						}

						Text {
							Layout.alignment: Qt.AlignHCenter
							text: {
								if (root.osdType === "capslock") return root.capslockState ? "ON" : "OFF";
								if (root.osdType === "brightness") return Math.round(SystemStatus.brightness * 100) + "%";
								if (root.osdType === "mic") return root.sourceMuted ? "MUTED" : Math.round(root.sourceVolume * 100) + "%";
								return root.sinkMuted ? "MUTED" : Math.round(root.sinkVolume * 100) + "%";
							}
							color: Colors.fgMain
							font.pixelSize: 12
							font.weight: Font.Bold
							font.family: Colors.fontMono
						}

						Text {
							Layout.alignment: Qt.AlignHCenter
							text: root.osdType.toUpperCase()
							color: Colors.textDisabled
							font.pixelSize: 8
							font.weight: Font.Black
							font.letterSpacing: 1
						}
					}
				}
			}
		}
	}
}

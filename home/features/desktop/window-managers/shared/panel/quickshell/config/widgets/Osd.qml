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

	function showOsd(type) {
		root.osdType = type;
		root.shouldShowOsd = true;
		hideTimer.restart();
	}

	function showAudioOsd(percent, muted, volumeProp, mutedProp, type) {
		var parsed = parseFloat(percent);
		if (!isNaN(parsed)) root[volumeProp] = Colors.clamp01(parsed / 100.0);
		if (muted === "true" || muted === "false") root[mutedProp] = (muted === "true");
		showOsd(type);
	}

	IpcHandler {
		target: "Osd"

		function showVolume(percent: string, muted: string) {
			root.showAudioOsd(percent, muted, "displaySinkVolume", "displaySinkMuted", "volume");
		}

		function showMic(percent: string, muted: string) {
			root.showAudioOsd(percent, muted, "displaySourceVolume", "displaySourceMuted", "mic");
		}

		function showCapslock(state: string) {
			root.capslockState = (state === "on");
			root.showOsd("capslock");
		}

		function showBrightness(percent: string) {
			var val = parseFloat(percent);
			if (isNaN(val)) val = 0;
			SystemStatus.brightness = val / 100.0;
			root.showOsd("brightness");
		}
	}

	property bool shouldShowOsd: false
	property string osdType: "volume"
	property bool capslockState: false
	property bool suppressPipewireOsd: true
	property var osdScreen: (Quickshell.cursorScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null))
	property real displaySinkVolume: 0
	property bool displaySinkMuted: false
	property real displaySourceVolume: 0
	property bool displaySourceMuted: false
	property real sinkVolume: {
		var v = Pipewire.defaultAudioSink?.audio?.volume;
		return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
	}
	property bool sinkMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
	property real sourceVolume: {
		var v = Pipewire.defaultAudioSource?.audio?.volume;
		return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
	}
	property bool sourceMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false

	function onPipewireChanged(displayProp, value, type) {
		root[displayProp] = value;
		if (!root.suppressPipewireOsd) showOsd(type);
	}

	onSinkVolumeChanged: onPipewireChanged("displaySinkVolume", sinkVolume, "volume")
	onSinkMutedChanged: onPipewireChanged("displaySinkMuted", sinkMuted, "volume")
	onSourceVolumeChanged: onPipewireChanged("displaySourceVolume", sourceVolume, "mic")
	onSourceMutedChanged: onPipewireChanged("displaySourceMuted", sourceMuted, "mic")

	Component.onCompleted: {
		root.displaySinkVolume = root.sinkVolume;
		root.displaySinkMuted = root.sinkMuted;
		root.displaySourceVolume = root.sourceVolume;
		root.displaySourceMuted = root.sourceMuted;
		Qt.callLater(function() {
			root.suppressPipewireOsd = false;
		});
	}

	Timer {
		id: hideTimer
		interval: Config.osdDuration
		onTriggered: root.shouldShowOsd = false
	}

	PanelWindow {
		id: osdWindow
		screen: root.osdScreen
		visible: root.shouldShowOsd

		anchors.top: true
		anchors.left: true
		margins.top: screen ? (screen.height / 2 - implicitHeight / 2) : 0
		margins.left: screen ? (screen.width / 2 - implicitWidth / 2) : 0
		exclusiveZone: 0

		implicitWidth: Config.osdSize
		implicitHeight: Config.osdSize
		color: "transparent"
		WlrLayershell.layer: WlrLayer.Overlay
		WlrLayershell.namespace: "quickshell"

		mask: Region {
			item: content
		}

		Rectangle {
			id: content
			anchors.fill: parent
			radius: 28
			color: Colors.bgGlass
			border.color: Colors.primary
			border.width: 2

			opacity: root.shouldShowOsd ? 1.0 : 0.0
			scale: root.shouldShowOsd ? 1.0 : 0.9

			Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
			Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 18
				spacing: 10

				CircularGauge {
					Layout.alignment: Qt.AlignHCenter
					width: 78
					height: 78
					thickness: 6
					value: {
						if (root.osdType === "brightness") return SystemStatus.brightness;
						if (root.osdType === "mic") return root.displaySourceVolume;
						if (root.osdType === "capslock") return root.capslockState ? 1.0 : 0.0;
						return root.displaySinkVolume;
					}
					color: {
						if (root.osdType === "capslock") return root.capslockState ? Colors.primary : Colors.fgDim;
						if (root.osdType === "mic" && root.displaySourceMuted) return Colors.error;
						if (root.osdType === "volume" && root.displaySinkMuted) return Colors.error;
						return Colors.primary;
					}
					icon: {
						if (root.osdType === "capslock") return root.capslockState ? "󰬶" : "󰬵";
						if (root.osdType === "brightness") return "󰃠";
						if (root.osdType === "mic") return root.displaySourceMuted ? "󰍭" : "󰍬";
						if (root.osdType === "volume") return root.displaySinkMuted ? "󰝟" : "󰕾";
						return "";
					}
				}

				Text {
					Layout.alignment: Qt.AlignHCenter
					text: {
						if (root.osdType === "capslock") return root.capslockState ? "ON" : "OFF";
						if (root.osdType === "brightness") return Math.round(SystemStatus.brightness * 100) + "%";
						if (root.osdType === "mic") return root.displaySourceMuted ? "MUTED" : Math.round(root.displaySourceVolume * 100) + "%";
						return root.displaySinkMuted ? "MUTED" : Math.round(root.displaySinkVolume * 100) + "%";
					}
					color: "white"
					font.pixelSize: 18
					font.weight: Font.Black
					font.family: Colors.fontMono
				}

				Text {
					Layout.alignment: Qt.AlignHCenter
					text: root.osdType.toUpperCase()
					color: Colors.primary
					font.pixelSize: 10
					font.weight: Font.Black
					font.letterSpacing: 1.5
				}
			}
		}
	}
}

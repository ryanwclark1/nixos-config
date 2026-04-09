import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../../settings/components"

Item {
    id: root

    property var camera: null
    property string streamUrl: ""
    property string selectedQuality: "medium"

    signal closeRequested()

    visible: false

    onVisibleChanged: {
        if (visible && camera) {
            _requestStream();
        } else {
            videoPlayer.stop();
            videoPlayer.source = "";
        }
    }

    onStreamUrlChanged: {
        if (streamUrl && visible) {
            videoPlayer.source = streamUrl;
            videoPlayer.play();
        }
    }

    function _requestStream() {
        if (!camera || !camera.id) return;
        var cached = UnifiProtectService.cachedStreamUrl(camera.id, selectedQuality);
        if (cached) {
            root.streamUrl = cached;
        } else {
            UnifiProtectService.requestStream(camera.id, selectedQuality);
        }
    }

    Connections {
        target: UnifiProtectService
        function onStreamReady(cameraId, url) {
            if (root.camera && root.camera.id === cameraId && root.visible) {
                root.streamUrl = url;
            }
        }
    }

    // ── Background ──────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: Appearance.radiusMedium
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingS

        // ── Header ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.IconButton {
                icon: "arrow-left.svg"
                tooltipText: "Back to cameras"
                onClicked: root.closeRequested()
            }

            Text {
                text: root.camera ? UnifiProtectService.cameraDisplayName(root.camera) : "Camera"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Quality selector
            RowLayout {
                spacing: Appearance.spacingXS

                Repeater {
                    model: ["low", "medium", "high"]
                    delegate: SettingsActionButton {
                        required property string modelData
                        compact: true
                        label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        highlighted: root.selectedQuality === modelData
                        onClicked: {
                            root.selectedQuality = modelData;
                            videoPlayer.stop();
                            videoPlayer.source = "";
                            root.streamUrl = "";
                            root._requestStream();
                        }
                    }
                }
            }
        }

        // ── Video player ────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.radiusSmall
            color: "black"
            clip: true

            MediaPlayer {
                id: videoPlayer
                audioOutput: AudioOutput { muted: true }
                videoOutput: videoOutput
                onErrorOccurred: (error, errorString) => {
                    Logger.w("UnifiProtect", "Stream playback error:", errorString);
                    errorText.text = "Stream error: " + errorString;
                    errorText.visible = true;
                }
                onPlaybackStateChanged: {
                    if (playbackState === MediaPlayer.PlayingState) {
                        errorText.visible = false;
                        loadingIndicator.visible = false;
                    }
                }
            }

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
                visible: videoPlayer.playbackState === MediaPlayer.PlayingState
            }

            // Loading state
            ColumnLayout {
                id: loadingIndicator
                anchors.centerIn: parent
                spacing: Appearance.spacingS
                visible: root.visible && videoPlayer.playbackState !== MediaPlayer.PlayingState && !errorText.visible

                SharedWidgets.SvgIcon {
                    Layout.alignment: Qt.AlignHCenter
                    source: "camera.svg"
                    color: Colors.textDisabled
                    size: 32
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.streamUrl ? "Connecting to stream..." : "Requesting stream..."
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            // Error state
            Text {
                id: errorText
                anchors.centerIn: parent
                visible: false
                color: Colors.warning
                font.pixelSize: Appearance.fontSizeSmall
                wrapMode: Text.WordWrap
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ── Stream info footer ──────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
                text: root.camera && root.camera.state === "CONNECTED" ? "Live" : "Offline"
                color: root.camera && root.camera.state === "CONNECTED" ? Colors.primary : Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Bold
            }

            Text {
                text: "Quality: " + root.selectedQuality
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
            }

            Item { Layout.fillWidth: true }

            SettingsActionButton {
                compact: true
                iconName: "open-external.svg"
                label: "Open in VLC"
                visible: root.streamUrl !== ""
                onClicked: {
                    Quickshell.execDetached(["vlc", root.streamUrl]);
                }
            }
        }
    }
}

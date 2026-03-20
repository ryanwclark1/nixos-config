import QtQuick
import QtQuick.Layouts
import "."
import "../../../services"
import "../../../widgets"

RowLayout {
    id: root

    required property var appNode   // {nodeRef, id, name, iconName, volume, muted}
    readonly property string appIconName: root.appNode && root.appNode.iconName ? String(root.appNode.iconName) : ""
    readonly property string appName: root.appNode && root.appNode.name ? String(root.appNode.name) : "Unknown"
    readonly property real appVolume: {
        var value = root.appNode ? Number(root.appNode.volume) : 0;
        return isNaN(value) ? 0 : Colors.clamp01(value);
    }
    readonly property bool appMuted: !!(root.appNode && root.appNode.muted)

    Layout.fillWidth: true
    spacing: Appearance.spacingS
    height: 40

    // App icon fallback if no icon resolves
    SvgIcon {
        visible: !appIconImage.visible
        color: root.appMuted ? Colors.error : Colors.primary
        source: "music-note-2.svg"
        size: Appearance.fontSizeLarge
        Layout.preferredWidth: 24
    }

    Image {
        id: appIconImage
        visible: status === Image.Ready
        source: {
            if (!root.appIconName)
                return "";
            return Config.resolveIconSource(root.appIconName);
        }
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        sourceSize.width: 20
        sourceSize.height: 20
        fillMode: Image.PreserveAspectFit
    }

    // App name
    Text {
        text: root.appName
        color: Colors.text
        font.pixelSize: Appearance.fontSizeSmall
        elide: Text.ElideRight
        Layout.preferredWidth: 70
        Layout.maximumWidth: 70
    }

    // Volume slider
    SliderTrack {
        Layout.fillWidth: true
        value: root.appVolume
        muted: root.appMuted
        icon: "music-note-2.svg"
        onSliderMoved: v => AudioService.setAppVolume(root.appNode.nodeRef, v)
    }

    // Mute button
    MuteButton {
        muted: root.appMuted
        icon: "speaker.svg"
        mutedIcon: "speaker-mute.svg"
        size: 28
        action: function () {
            AudioService.toggleAppMute(root.appNode.nodeRef);
        }
    }
}

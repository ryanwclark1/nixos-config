import QtQuick
import QtQuick.Layouts
import "../services"

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
    spacing: Colors.spacingS
    height: 40

    // App icon (Nerd Font fallback if no icon resolved)
    Text {
        text: {
            if (root.appIconName) {
                var resolved = Config.resolveIconSource(root.appIconName);
                if (resolved)
                    return "";  // will use Image instead
            }
            return "󰎈";  // default music/app icon
        }
        visible: !appIconImage.visible
        color: root.appMuted ? Colors.error : Colors.primary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeLarge
        Layout.preferredWidth: 24
        horizontalAlignment: Text.AlignHCenter
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
        font.pixelSize: Colors.fontSizeSmall
        elide: Text.ElideRight
        Layout.preferredWidth: 70
        Layout.maximumWidth: 70
    }

    // Volume slider
    SliderTrack {
        Layout.fillWidth: true
        value: root.appVolume
        muted: root.appMuted
        icon: "󰎈"
        onSliderMoved: v => AudioService.setAppVolume(root.appNode.nodeRef, v)
    }

    // Mute button
    MuteButton {
        muted: root.appMuted
        icon: "󰕾"
        mutedIcon: "󰝟"
        size: 28
        action: function () {
            AudioService.toggleAppMute(root.appNode.nodeRef);
        }
    }
}

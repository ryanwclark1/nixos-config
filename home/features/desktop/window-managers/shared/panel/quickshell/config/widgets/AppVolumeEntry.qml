import QtQuick
import QtQuick.Layouts
import "../services"

RowLayout {
    id: root

    required property var appNode   // {nodeRef, id, name, iconName, volume, muted}

    Layout.fillWidth: true
    spacing: Colors.spacingS
    height: 40

    // App icon (Nerd Font fallback if no icon resolved)
    Text {
        text: {
            if (root.appNode.iconName) {
                var resolved = Config.resolveIconSource(root.appNode.iconName);
                if (resolved) return "";  // will use Image instead
            }
            return "󰎈";  // default music/app icon
        }
        visible: !appIconImage.visible
        color: root.appNode.muted ? Colors.error : Colors.primary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeLarge
        Layout.preferredWidth: 24
        horizontalAlignment: Text.AlignHCenter
    }

    Image {
        id: appIconImage
        visible: status === Image.Ready
        source: {
            if (!root.appNode.iconName) return "";
            return Config.resolveIconSource(root.appNode.iconName);
        }
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        sourceSize.width: 20
        sourceSize.height: 20
        fillMode: Image.PreserveAspectFit
    }

    // App name
    Text {
        text: root.appNode.name
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        elide: Text.ElideRight
        Layout.preferredWidth: 70
        Layout.maximumWidth: 70
    }

    // Volume slider
    SliderTrack {
        Layout.fillWidth: true
        value: root.appNode.volume
        muted: root.appNode.muted
        icon: "󰎈"
        onSliderMoved: v => AudioService.setAppVolume(root.appNode.nodeRef, v)
    }

    // Mute button
    MuteButton {
        muted: root.appNode.muted
        icon: "󰕾"
        mutedIcon: "󰝟"
        size: 28
        action: function() {
            AudioService.toggleAppMute(root.appNode.nodeRef);
        }
    }
}

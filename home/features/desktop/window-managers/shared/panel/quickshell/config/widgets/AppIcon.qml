import QtQuick
import "../services"

Item {
  id: root

  property string iconName: ""
  property string appName: ""
  property int iconSize: 32
  property var iconMap: null
  property string fallbackIcon: "󰀻"

  width: iconSize
  height: iconSize

  readonly property string _resolvedSource: {
    var name = iconName;
    if (!name) return "";

    // Already an absolute path or file URI — use directly
    if (name.startsWith("/") || name.startsWith("file://"))
      return name.startsWith("file://") ? name : "file://" + name;

    // If iconMap provided, try alias lookup then direct lookup
    if (iconMap) {
      var lower = name.toLowerCase();
      var aliases = Config.iconAliases[lower] || [];
      for (var i = 0; i < aliases.length; ++i) {
        if (iconMap[aliases[i]]) return "file://" + iconMap[aliases[i]];
      }
      if (iconMap[lower]) return "file://" + iconMap[lower];
    }

    // Fall back to Config.resolveIconSource (aliases + Quickshell.iconPath)
    return Config.resolveIconSource(name);
  }

  Image {
    id: iconImage
    anchors.fill: parent
    source: root._resolvedSource
    sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    visible: source !== "" && status === Image.Ready
  }

  Text {
    anchors.centerIn: parent
    text: root.fallbackIcon
    color: Colors.text
    font.family: Colors.fontMono
    font.pixelSize: root.iconSize * 0.6
    visible: !iconImage.visible
  }
}

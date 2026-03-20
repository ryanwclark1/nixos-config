import QtQuick
import "../services"

Item {
  id: root

  property string iconName: ""
  property string desktopId: ""
  property string appId: ""
  property string execName: ""
  property string appName: ""
  property var iconCandidates: []
  property int iconSize: Appearance.iconSizeMedium
  property var iconMap: null
  property string fallbackIcon: "󰀻"

  width: iconSize
  height: iconSize

  function candidateList() {
    var values = [];

    function appendUnique(value) {
      var next = String(value || "").trim();
      if (next === "" || values.indexOf(next) !== -1)
        return;
      values.push(next);
    }

    function execBasename(value) {
      var raw = String(value || "").trim();
      if (raw === "")
        return "";
      var head = raw.split(/\s+/)[0] || "";
      if (head === "")
        return "";
      var slash = head.lastIndexOf("/");
      return slash >= 0 ? head.substring(slash + 1) : head;
    }

    appendUnique(root.iconName);
    appendUnique(root.desktopId);
    appendUnique(root.appId);
    appendUnique(execBasename(root.execName));
    appendUnique(root.appName);

    var extra = Array.isArray(root.iconCandidates) ? root.iconCandidates : [];
    for (var i = 0; i < extra.length; ++i)
      appendUnique(extra[i]);

    return values;
  }

  function resolveCandidate(name) {
    var candidate = String(name || "");
    if (candidate === "")
      return "";

    if (candidate.startsWith("/") || candidate.startsWith("file://"))
      return candidate.startsWith("file://") ? candidate : "file://" + candidate;

    if (iconMap) {
      var lower = candidate.toLowerCase();
      var desktopLower = lower.endsWith(".desktop") ? lower.substring(0, lower.length - 8) : lower;
      var aliases = Config.iconAliases[lower] || [];
      for (var i = 0; i < aliases.length; ++i) {
        if (iconMap[aliases[i]])
          return "file://" + iconMap[aliases[i]];
      }
      if (desktopLower !== lower) {
        var desktopAliases = Config.iconAliases[desktopLower] || [];
        for (var j = 0; j < desktopAliases.length; ++j) {
          if (iconMap[desktopAliases[j]])
            return "file://" + iconMap[desktopAliases[j]];
        }
      }
      if (iconMap[lower])
        return "file://" + iconMap[lower];
      if (desktopLower !== lower && iconMap[desktopLower])
        return "file://" + iconMap[desktopLower];
    }

    return Config.resolveIconSource(candidate);
  }

  function isGlyphIcon(name) {
    var value = String(name || "");
    if (value === "" || value.length > 3)
      return false;
    return !/[A-Za-z0-9/_\-.]/.test(value);
  }

  readonly property string _resolvedSource: {
    var candidates = candidateList();
    for (var i = 0; i < candidates.length; ++i) {
      var resolved = resolveCandidate(candidates[i]);
      if (resolved !== "")
        return resolved;
    }
    return "";
  }

  readonly property string _fallbackText: {
    if (root._resolvedSource === "" && isGlyphIcon(root.iconName))
      return root.iconName;
    return root.fallbackIcon;
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
    text: root._fallbackText
    color: Colors.text
    font.family: Appearance.fontMono
    font.pixelSize: root.iconSize * 0.6
    visible: !iconImage.visible
  }
}

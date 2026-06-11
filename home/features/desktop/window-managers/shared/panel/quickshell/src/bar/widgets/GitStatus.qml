import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
  id: root

  property string windowTitle: ""
  property string appId: ""
  property string branchName: ""
  property real iconScale: 1.0
  property real fontScale: 1.0

  readonly property string normalizedAppId: (appId || "").toLowerCase()
  readonly property bool looksLikeTerminal: normalizedAppId.includes("terminal")
    || normalizedAppId.includes("ghostty")
    || normalizedAppId.includes("kitty")
  readonly property bool looksLikePath: windowTitle.includes("~") || windowTitle.includes("/")

  visible: !!branchName && (looksLikeTerminal || looksLikePath)

  implicitWidth: visible ? gitRow.implicitWidth + Appearance.spacingM * iconScale : 0
  implicitHeight: 22 * iconScale
  radius: height / 2
  color: Colors.highlightLight
  border.color: Colors.primaryRing
  border.width: 1

  readonly property int _gitPollMs: 20000

  CommandPoll {
    id: gitPoll
    interval: root._gitPollMs
    running: looksLikeTerminal || looksLikePath
    command: ["sh", "-c",
      "path=$(echo \"$1\" | grep -o '/[^ ]*' | head -1); " +
      "[ -z \"$path\" ] && path=$HOME; " +
      "cd \"$path\" 2>/dev/null || cd $HOME; " +
      "git rev-parse --abbrev-ref HEAD 2>/dev/null",
      "--", root.windowTitle]
    onUpdated: root.branchName = (gitPoll.value || "").trim()
  }

  RowLayout {
    id: gitRow
    anchors.centerIn: parent
    spacing: Appearance.spacingXS * root.iconScale

    SharedWidgets.SvgIcon {
      source: "git-branch.svg"
      color: Colors.primary
      size: Appearance.fontSizeSmall * root.iconScale
    }

    Text {
      text: root.branchName
      color: Colors.text
      font.pixelSize: Appearance.fontSizeXS * root.fontScale
      font.weight: Font.Bold
    }
  }
}

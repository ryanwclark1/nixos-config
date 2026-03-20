import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
  id: root

  property string windowTitle: ""
  property string appId: ""
  property string branchName: ""

  readonly property string normalizedAppId: (appId || "").toLowerCase()
  readonly property bool looksLikeTerminal: normalizedAppId.includes("terminal")
    || normalizedAppId.includes("ghostty")
    || normalizedAppId.includes("kitty")
  readonly property bool looksLikePath: windowTitle.includes("~") || windowTitle.includes("/")

  visible: !!branchName && (looksLikeTerminal || looksLikePath)

  implicitWidth: visible ? gitRow.implicitWidth + Appearance.spacingM : 0
  implicitHeight: 22
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
    spacing: Appearance.spacingXS

    Text {
      text: "󰊢"
      color: Colors.primary
      font.family: Appearance.fontMono
      font.pixelSize: Appearance.fontSizeSmall
    }

    Text {
      text: root.branchName
      color: Colors.text
      font.pixelSize: Appearance.fontSizeXS
      font.weight: Font.Bold
    }
  }
}

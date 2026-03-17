import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

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

  implicitWidth: visible ? gitRow.implicitWidth + Colors.spacingM : 0
  implicitHeight: 22
  radius: height / 2
  color: Colors.withAlpha(Colors.primary, 0.15)
  border.color: Colors.withAlpha(Colors.primary, 0.3)
  border.width: 1

  CommandPoll {
    id: gitPoll
    interval: 3000
    running: root.visible
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
    spacing: Colors.spacingXS

    Text {
      text: "󰊢"
      color: Colors.primary
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeSmall
    }

    Text {
      text: root.branchName
      color: Colors.text
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Bold
    }
  }
}

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

    implicitWidth: visible ? gitRow.implicitWidth + 12 : 0
    implicitHeight: 22
    radius: 11
    color: Colors.withAlpha(Colors.primary, 0.15)
    border.color: Colors.withAlpha(Colors.primary, 0.3)
    border.width: 1

    SharedWidgets.CommandPoll {
        id: gitPoll
        interval: 3000
        running: root.visible
        command: ["sh", "-c", "
            path=$(echo '" + root.windowTitle + "' | grep -o '/[^ ]*' | head -1)
            [ -z \"$path\" ] && path=$HOME
            cd \"$path\" 2>/dev/null || cd $HOME
            git rev-parse --abbrev-ref HEAD 2>/dev/null
        "]
        onUpdated: root.branchName = (gitPoll.value || "").trim()
    }

    RowLayout {
        id: gitRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "󰊢"
            color: Colors.primary
            font.family: Colors.fontMono
            font.pixelSize: 12
        }

        Text {
            text: root.branchName
            color: Colors.text
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets
import "." as Widgets

RowLayout {
    id: root
    spacing: Colors.spacingM
    
    property var widgetInstance: null
    property int maxTitleWidth: 300

    readonly property var activeWindow: {
        if (CompositorAdapter.isNiri && CompositorAdapter.niriActiveWindow)
            return CompositorAdapter.niriActiveWindow;
        if (CompositorAdapter.isHyprland && typeof ToplevelManager !== "undefined") {
            return ToplevelManager.activeToplevel;
        }
        return null;
    }

    readonly property string activeTitle: activeWindow ? (activeWindow.title || "") : ""
    readonly property string activeAppId: activeWindow ? (activeWindow.app_id || activeWindow.class || "") : ""

    visible: activeTitle !== ""

    // ── App Icon ───────────────────────────────
    Rectangle {
        width: 22; height: 22; radius: 6
        color: Colors.withAlpha(Colors.surface, 0.4)
        border.color: Colors.border; border.width: 1
        
        Image {
            anchors.fill: parent; anchors.margins: 4
            source: Config.resolveIconSource(root.activeAppId)
            sourceSize: Qt.size(32, 32)
            asynchronous: true
            fillMode: Image.PreserveAspectFit
        }
    }

    // ── Window Title ───────────────────────────
    Text {
        Layout.maximumWidth: root.maxTitleWidth
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        text: root.activeTitle
    }

    // ── Inline Git Status ──────────────────────
    Rectangle {
        id: gitStatus
        property string branchName: ""
        visible: !!branchName && (root.activeAppId.toLowerCase().includes("terminal") || root.activeAppId.toLowerCase().includes("ghostty") || root.activeAppId.toLowerCase().includes("kitty") || root.activeTitle.includes("~") || root.activeTitle.includes("/"))
        
        implicitWidth: visible ? gitRow.implicitWidth + 12 : 0
        implicitHeight: 22
        radius: 11
        color: Colors.withAlpha(Colors.primary, 0.15)
        border.color: Colors.withAlpha(Colors.primary, 0.3)
        border.width: 1
        
        SharedWidgets.CommandPoll {
            id: gitPoll
            interval: 3000
            running: gitStatus.visible
            command: ["sh", "-c", "
                path=$(echo '" + root.activeTitle + "' | grep -o '/[^ ]*' | head -1)
                [ -z \"$path\" ] && path=$HOME
                cd \"$path\" 2>/dev/null || cd $HOME
                git rev-parse --abbrev-ref HEAD 2>/dev/null
            "]
            onUpdated: gitStatus.branchName = (gitPoll.value || "").trim()
        }

        RowLayout {
            id: gitRow
            anchors.centerIn: parent
            spacing: 4
            Text { text: "󰊢"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 12 }
            Text { text: gitStatus.branchName; color: Colors.text; font.pixelSize: 10; font.weight: Font.Bold }
        }
    }

    // ── Inline Media Context ───────────────────
    Rectangle {
        id: mediaContext
        visible: !!MediaService.currentPlayer && MediaService.trackTitle !== ""
        
        implicitWidth: visible ? mediaRow.implicitWidth + 12 : 0
        implicitHeight: 22
        radius: 11
        color: Colors.withAlpha(MediaService.artAccentColor, 0.15)
        border.color: Colors.withAlpha(MediaService.artAccentColor, 0.3)
        border.width: 1
        
        Behavior on color { ColorAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 400 } }

        RowLayout {
            id: mediaRow
            anchors.centerIn: parent
            spacing: 6
            
            Text {
                text: MediaService.isPlaying ? "󰏤" : "󰐊"
                color: MediaService.artAccentColor
                font.family: Colors.fontMono
                font.pixelSize: 12
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MediaService.playPause()
                }
            }
            
            Text {
                text: MediaService.trackTitle
                color: Colors.text
                font.pixelSize: 9
                font.weight: Font.Bold
                elide: Text.ElideRight
                Layout.maximumWidth: 120
            }

            Text {
                text: "󰒭"
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: 12
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MediaService.next()
                }
            }
        }
    }
}

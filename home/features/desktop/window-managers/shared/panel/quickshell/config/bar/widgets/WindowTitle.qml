import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Item {
    id: root

    property var widgetInstance: null
    readonly property var widgetSettings: widgetInstance && widgetInstance.settings ? widgetInstance.settings : ({})
    property int maxTitleWidth: {
        var parsed = parseInt(widgetSettings.maxTitleWidth !== undefined ? widgetSettings.maxTitleWidth : 300, 10);
        return Math.max(120, isNaN(parsed) ? 300 : parsed);
    }
    readonly property bool showAppIcon: widgetSettings.showAppIcon !== false
    readonly property bool showGitStatus: widgetSettings.showGitStatus !== false
    readonly property bool showMediaContext: widgetSettings.showMediaContext !== false

    readonly property string activeTitle: CompositorAdapter.activeWindowTitle || ""
    readonly property string activeAppId: CompositorAdapter.activeWindowAppId || ""

    visible: activeTitle !== ""
    implicitWidth: visible ? contentRow.implicitWidth : 0
    implicitHeight: visible ? contentRow.implicitHeight : 0

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Colors.spacingM

        // ── App Icon ───────────────────────────────
        Rectangle {
            visible: root.showAppIcon
            width: 22; height: 22; radius: Colors.radiusXXS
            color: Colors.cardSurface
            border.color: Colors.border; border.width: 1

            SharedWidgets.AppIcon {
                anchors.centerIn: parent
                iconName: root.activeAppId
                appName: root.activeTitle
                iconSize: 16
                fallbackIcon: "󰣆"
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

        // ── Git Status ─────────────────────────────
        GitStatus {
            visible: root.showGitStatus
            windowTitle: root.activeTitle
            appId: root.activeAppId
        }

        // ── Inline Media Context ───────────────────
        Rectangle {
            id: mediaContext
            visible: root.showMediaContext && !!MediaService.currentPlayer && MediaService.trackTitle !== ""

            implicitWidth: visible ? mediaRow.implicitWidth + Colors.spacingM : 0
            implicitHeight: 22
            radius: 11
            color: Colors.withAlpha(MediaService.artAccentColor, 0.15)
            border.color: Colors.withAlpha(MediaService.artAccentColor, 0.3)
            border.width: 1
            
            Behavior on color { ColorAnimation { duration: Colors.durationEmphasis } }
            Behavior on border.color { ColorAnimation { duration: Colors.durationEmphasis } }

            RowLayout {
                id: mediaRow
                anchors.centerIn: parent
                spacing: Colors.spacingSM

                Text {
                    text: MediaService.isPlaying ? "󰏤" : "󰐊"
                    color: MediaService.artAccentColor
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeSmall

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
                    font.pixelSize: Colors.fontSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.next()
                    }
                }
            }
        }
    }
}

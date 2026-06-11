import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root

    property var widgetInstance: null
    property real fontScale: 1.0
    property real iconScale: 1.0
    readonly property var widgetSettings: widgetInstance && widgetInstance.settings ? widgetInstance.settings : ({})
    property int maxTitleWidth: {
        var parsed = parseInt(widgetSettings.maxTitleWidth !== undefined ? widgetSettings.maxTitleWidth : 300, 10);
        return Math.max(120, isNaN(parsed) ? 300 : parsed);
    }
    readonly property bool showAppIcon: widgetSettings.showAppIcon !== false
    readonly property bool showGitStatus: widgetSettings.showGitStatus !== false
    readonly property bool showMediaContext: widgetSettings.showMediaContext !== false

    SharedWidgets.Ref {
        service: MediaService
        active: root.showMediaContext
    }

    readonly property string activeTitle: CompositorAdapter.activeWindowTitle || ""
    readonly property string activeAppId: CompositorAdapter.activeWindowAppId || ""

    tooltipText: root.activeTitle
    visible: activeTitle !== ""

    RowLayout {
        id: contentRow
        spacing: Appearance.spacingM * root.iconScale

        // ── App Icon ───────────────────────────────
        Rectangle {
            visible: root.showAppIcon
            width: 22 * root.iconScale; height: 22 * root.iconScale; radius: Appearance.radiusXXS * root.iconScale
            color: Colors.cardSurface
            border.color: Colors.border; border.width: 1

            SharedWidgets.AppIcon {
                anchors.centerIn: parent
                iconName: root.activeAppId
                appName: root.activeTitle
                iconSize: 16 * root.iconScale
                fallbackIcon: "app-generic.svg"
            }
        }

        // ── Window Title ───────────────────────────
        Text {
            Layout.maximumWidth: root.maxTitleWidth * root.iconScale
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: root.activeTitle
        }

        // ── Git Status ─────────────────────────────
        GitStatus {
            visible: root.showGitStatus
            windowTitle: root.activeTitle
            appId: root.activeAppId
            iconScale: root.iconScale
            fontScale: root.fontScale
        }

        // ── Inline Media Context ───────────────────
        Rectangle {
            id: mediaContext
            visible: root.showMediaContext && !!MediaService.currentPlayer && MediaService.trackTitle !== ""

            implicitWidth: visible ? mediaRow.implicitWidth + Appearance.spacingM * root.iconScale : 0
            implicitHeight: 22 * root.iconScale
            radius: implicitHeight / 2
            color: Colors.withAlpha(MediaService.artAccentColor, 0.15)
            border.color: Colors.withAlpha(MediaService.artAccentColor, 0.3)
            border.width: 1
            
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationEmphasis } }
            Behavior on border.color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationEmphasis } }

            RowLayout {
                id: mediaRow
                anchors.centerIn: parent
                spacing: Appearance.spacingSM * root.iconScale

                SharedWidgets.SvgIcon {
                    source: MediaService.isPlaying ? "pause.svg" : "play.svg"
                    color: MediaService.artAccentColor
                    size: Appearance.fontSizeSmall * root.iconScale

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.playPause()
                    }
                }

                Text {
                    text: MediaService.trackTitle
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeXXS * root.fontScale
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.maximumWidth: 120 * root.iconScale
                }

                SharedWidgets.SvgIcon {
                    source: "arrow-right.svg"
                    color: Colors.textDisabled
                    size: Appearance.fontSizeSmall * root.iconScale

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

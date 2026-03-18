import QtQuick
import QtQuick.Layouts
import "../../../../services"

ColumnLayout {
    id: root
    required property bool compactMode

    spacing: Colors.spacingM
    Layout.fillWidth: true

    Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        Text {
            width: root.compactMode ? parent.width : undefined
            text: "Auto-Cycle Interval"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
        }

        Text {
            text: Config.wallpaperCycleInterval === 0 ? "Off" : Config.wallpaperCycleInterval + " min"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            font.family: Colors.fontMono
        }
    }

    Item {
        Layout.fillWidth: true
        height: 24

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            color: Colors.surface
            radius: Colors.radiusXS

            Rectangle {
                width: parent.width * (Config.wallpaperCycleInterval / 60)
                height: parent.height
                color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                radius: Colors.radiusXS
                Behavior on width {
                    NumberAnimation { duration: Colors.durationSnap }
                }
                Behavior on color { CAnim {} }
            }
        }

        Rectangle {
            width: 14
            height: 14
            radius: width / 2
            color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
            border.color: Colors.bgWidget
            border.width: 2
            x: Math.max(0, Math.min(parent.width - width, parent.width * (Config.wallpaperCycleInterval / 60) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            Behavior on x {
                NumberAnimation { duration: Colors.durationSnap }
            }
            Behavior on color { CAnim {} }
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            cursorShape: Qt.PointingHandCursor
            function updateCycle(mouse) {
                var raw = (mouse.x / width) * 60;
                if (raw < 2) {
                    Config.wallpaperCycleInterval = 0;
                    return;
                }
                var snapped = Math.round(raw / 5) * 5;
                Config.wallpaperCycleInterval = Math.max(5, Math.min(60, snapped));
            }
            onPressed: mouse => updateCycle(mouse)
            onPositionChanged: mouse => {
                if (pressed)
                    updateCycle(mouse);
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        Text {
            width: root.compactMode ? parent.width : undefined
            text: "Off"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
        }

        Text {
            text: "60 min"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
        }
    }
}

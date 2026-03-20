import QtQuick
import "../services"
import "../services/WeatherVisuals.js" as WeatherVisuals

Item {
    id: root

    property string condition: ""
    property color color: Colors.accent
    property int size: Appearance.iconSizeSmall
    property bool animated: Config.weatherUiAnimationEnabled

    readonly property var visual: WeatherVisuals.visualForCondition(condition)
    readonly property color effectColor: color.a > 0 ? color : Colors.accent
    readonly property real _motionBudget: Math.max(0.3, Appearance._powerAnimScale)
    readonly property int _ambientDuration: Math.round(Appearance.durationAmbient / _motionBudget)
    readonly property int _ambientShortDuration: Math.round(Appearance.durationAmbientShort / _motionBudget)
    readonly property int _effectCount: animated ? Math.max(2, Math.round((size / 14) * (0.8 + visual.intensity))) : 0
    readonly property bool _animationsEnabled: visible && animated && !Colors.isTransitioning

    function _bandAlpha(multiplier) {
        return Math.max(0.08, Math.min(0.55, visual.intensity * multiplier));
    }

    width: size
    height: size

    SvgIcon {
        id: baseIcon
        anchors.fill: parent
        source: root.visual.icon
        color: root.color
        size: root.size
    }

    Item {
        anchors.fill: parent
        clip: true
        visible: root.animated

        Item {
            anchors.fill: parent
            visible: root.visual.scene === "clear"

            Rectangle {
                id: solarHalo
                width: Math.round(root.width * 0.76)
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: Colors.withAlpha(root.effectColor, root._bandAlpha(0.18))
                opacity: 0.3

                SequentialAnimation on scale {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.12; duration: root._ambientDuration; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.92; duration: root._ambientDuration; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on opacity {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.45; duration: root._ambientShortDuration; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.2; duration: root._ambientShortDuration; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                width: Math.round(root.width * 0.9)
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: "transparent"
                border.width: Math.max(1, Math.round(root.size * 0.05))
                border.color: Colors.withAlpha(root.effectColor, root._bandAlpha(0.48))
                opacity: 0.24

                SequentialAnimation on scale {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    PauseAnimation { duration: Math.round(root._ambientShortDuration * 0.4) }
                    NumberAnimation { to: 1.12; duration: root._ambientDuration; easing.type: Easing.OutSine }
                    NumberAnimation { to: 0.84; duration: root._ambientDuration; easing.type: Easing.InSine }
                }
                SequentialAnimation on opacity {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.38; duration: root._ambientShortDuration; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.14; duration: root._ambientDuration; easing.type: Easing.InOutSine }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.visual.scene === "cloud"

            SvgIcon {
                id: cloudDriftA
                source: root.visual.icon
                color: Colors.withAlpha(root.effectColor, root._bandAlpha(0.22))
                size: Math.round(root.size * 0.9)
                x: Math.round(-root.size * 0.18)
                y: Math.round(root.size * 0.04)
                opacity: 0.35

                SequentialAnimation on x {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: Math.round(root.size * 0.02); duration: Math.round(root._ambientDuration * 1.3); easing.type: Easing.InOutSine }
                    NumberAnimation { to: Math.round(-root.size * 0.18); duration: Math.round(root._ambientDuration * 1.3); easing.type: Easing.InOutSine }
                }
            }

            SvgIcon {
                id: cloudDriftB
                source: root.visual.icon
                color: Colors.withAlpha(root.effectColor, root._bandAlpha(0.16))
                size: Math.round(root.size * 0.72)
                x: Math.round(root.size * 0.1)
                y: Math.round(root.size * 0.18)
                opacity: 0.3

                SequentialAnimation on x {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: Math.round(root.size * 0.02); duration: Math.round(root._ambientDuration * 1.1); easing.type: Easing.InOutSine }
                    NumberAnimation { to: Math.round(root.size * 0.16); duration: Math.round(root._ambientDuration * 1.1); easing.type: Easing.InOutSine }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.visual.scene === "rain" || root.visual.scene === "thunder"

            Repeater {
                model: root._effectCount + 2

                delegate: Rectangle {
                    id: rainDrop
                    readonly property real totalCount: root._effectCount + 2
                    readonly property real startY: -height - ((index % 3) * root.size * 0.12)
                    width: Math.max(1, Math.round(root.size * 0.07))
                    height: Math.max(5, Math.round(root.size * 0.34))
                    radius: width / 2
                    color: Colors.withAlpha(root.effectColor, root._bandAlpha(0.5))
                    rotation: -18
                    opacity: 0.3 + (index % 3) * 0.08
                    x: Math.round((root.width - width) * ((index + 0.45) / (totalCount + 0.6)))
                    y: startY

                    SequentialAnimation on y {
                        running: root._animationsEnabled && parent.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 110 }
                        NumberAnimation { to: root.height + rainDrop.height; duration: Math.round((root._ambientShortDuration + index * 90) * 0.9); easing.type: Easing.Linear }
                        ScriptAction { script: rainDrop.y = rainDrop.startY; }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Math.round(root.size * 0.25)
                color: Colors.withAlpha("#ffffff", 0.55)
                opacity: 0
                visible: root.visual.scene === "thunder"

                SequentialAnimation on opacity {
                    running: root._animationsEnabled && parent.visible
                    loops: Animation.Infinite
                    PauseAnimation { duration: Math.round(root._ambientDuration * 1.5) }
                    NumberAnimation { to: 0.34; duration: Appearance.durationFlash; easing.type: Easing.OutCubic }
                    NumberAnimation { to: 0.0; duration: Appearance.durationFast; easing.type: Easing.InCubic }
                    PauseAnimation { duration: Math.round(root._ambientDuration * 0.8) }
                    NumberAnimation { to: 0.22; duration: Appearance.durationFlash; easing.type: Easing.OutCubic }
                    NumberAnimation { to: 0.0; duration: Appearance.durationSnap; easing.type: Easing.InCubic }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.visual.scene === "snow"

            Repeater {
                model: root._effectCount + 1

                delegate: Rectangle {
                    id: snowFlake
                    readonly property real totalCount: root._effectCount + 1
                    property real baseX: (root.width - width) * ((index + 0.3) / (totalCount + 0.5))
                    readonly property real startY: -height - ((index % 4) * root.size * 0.08)
                    width: Math.max(2, Math.round(root.size * (0.08 + (index % 2) * 0.02)))
                    height: width
                    radius: width / 2
                    color: Colors.withAlpha("#ffffff", root._bandAlpha(0.62))
                    opacity: 0.42 + (index % 3) * 0.08
                    x: baseX
                    y: startY

                    SequentialAnimation on y {
                        running: root._animationsEnabled && parent.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 150 }
                        NumberAnimation { to: root.height + snowFlake.height; duration: Math.round(root._ambientDuration * 1.15 + index * 120); easing.type: Easing.Linear }
                        ScriptAction { script: snowFlake.y = snowFlake.startY; }
                    }

                    SequentialAnimation on x {
                        running: root._animationsEnabled && parent.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: baseX + Math.round(root.size * 0.08); duration: Math.round(root._ambientShortDuration * 1.1); easing.type: Easing.InOutSine }
                        NumberAnimation { to: baseX - Math.round(root.size * 0.06); duration: Math.round(root._ambientShortDuration * 1.1); easing.type: Easing.InOutSine }
                        NumberAnimation { to: baseX; duration: Math.round(root._ambientShortDuration * 0.8); easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.visual.scene === "fog"

            Repeater {
                model: 3

                delegate: Rectangle {
                    id: fogBand
                    width: Math.round(root.width * (0.95 - index * 0.12))
                    height: Math.max(3, Math.round(root.size * 0.2))
                    radius: height / 2
                    color: Colors.withAlpha(root.effectColor, root._bandAlpha(0.18 + index * 0.05))
                    opacity: 0.2 + index * 0.08
                    y: Math.round(root.size * (0.18 + index * 0.2))
                    x: -Math.round(width * 0.25) + index * Math.round(root.size * 0.06)

                    SequentialAnimation on x {
                        running: root._animationsEnabled && parent.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: Math.round(root.size * 0.16); duration: Math.round(root._ambientDuration * (1.4 + index * 0.2)); easing.type: Easing.InOutSine }
                        NumberAnimation { to: -Math.round(width * 0.25); duration: Math.round(root._ambientDuration * (1.4 + index * 0.2)); easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
}

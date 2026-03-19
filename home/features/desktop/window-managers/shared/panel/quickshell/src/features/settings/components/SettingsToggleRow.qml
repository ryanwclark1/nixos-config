import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label
    property string icon
    property string configKey: ""
    property bool checked: configKey ? Config[configKey] : false
    property string enabledText: "Enabled"
    property string disabledText: "Disabled"
    property bool highlighted: false
    signal toggled

    readonly property bool _active: configKey ? Config[configKey] : root.checked
    readonly property bool narrowLayout: width < 420

    function triggerToggle() {
        if (root.configKey)
            Config[root.configKey] = !Config[root.configKey];
        else
            root.toggled();
    }

    Layout.fillWidth: true
    implicitHeight: toggleContent.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.modalFieldSurface
    border.color: root._active ? Colors.primary : Colors.border
    border.width: 1

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root._active ? Colors.primaryFaint : "transparent"
        Behavior on color {
            enabled: !Colors.isTransitioning
            CAnim {}
        }
    }

    SharedWidgets.StateLayer {
        id: toggleStateLayer
        hovered: toggleHover.containsMouse
        pressed: toggleHover.pressed
        stateColor: Colors.primary
    }

    ColumnLayout {
        id: toggleContent
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            SettingsIconBox { icon: root.icon; active: root._active }

            Text {
                text: root.label
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            SharedWidgets.ToggleSwitch {
                checked: root._active
                Layout.alignment: Qt.AlignTop
                onToggled: root.triggerToggle()
            }
        }

        Text {
            text: root._active ? root.enabledText : root.disabledText
            color: root._active ? Colors.primary : Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            leftPadding: root.narrowLayout ? 0 : 38 + Colors.spacingM
        }
    }

    MouseArea {
        id: toggleHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            toggleStateLayer.burst(mouse.x, mouse.y);
            root.triggerToggle();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.primary
        opacity: highlightPulse.running ? highlightPulse._opacity : 0
        visible: root.highlighted

        SequentialAnimation {
            id: highlightPulse
            property real _opacity: 0
            running: root.highlighted
            loops: 2
            NumberAnimation { target: highlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Colors.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { target: highlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Colors.durationSlow; easing.type: Easing.InCubic }
        }
    }
}

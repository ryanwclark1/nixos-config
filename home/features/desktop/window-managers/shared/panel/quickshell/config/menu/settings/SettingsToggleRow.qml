import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label
    property string icon
    property string configKey: ""
    property bool checked: configKey ? Config[configKey] : false
    property string enabledText: "Enabled"
    property string disabledText: "Disabled"
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
    color: Colors.bgWidget
    border.color: root._active ? Colors.primary : Colors.border
    border.width: 1

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root._active ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
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

            Rectangle {
                width: 38
                height: 38
                radius: Colors.radiusSmall
                color: root._active ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14) : Colors.withAlpha(Colors.text, 0.06)
                border.color: root._active ? Colors.withAlpha(Colors.primary, 0.6) : Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignTop

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root._active ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }
            }

            Text {
                text: root.label
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            SharedWidgets.DankToggle {
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
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

Flow {
    id: root

    property var settingsRoot: null
    property string currentTabId: ""
    property var tabsModel: []

    signal tabRequested(string tabId)

    width: parent ? parent.width : implicitWidth
    spacing: Appearance.spacingS
    visible: (tabsModel || []).length > 0

    Repeater {
        model: root.tabsModel || []

        delegate: Rectangle {
            required property var modelData

            readonly property bool selected: String(modelData.id || "") === root.currentTabId

            radius: Appearance.radiusPill
            color: selected ? Colors.primarySubtle : Colors.modalFieldSurface
            border.color: selected ? Colors.primaryRing : Colors.border
            border.width: 1
            implicitHeight: 30
            implicitWidth: chipRow.implicitWidth + Appearance.spacingM * 2

            Behavior on color {
                enabled: !Colors.isTransitioning
                ColorAnimation { duration: Appearance.durationFast }
            }

            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: Appearance.spacingXS

                SharedWidgets.SvgIcon {
                    visible: String(modelData.icon || "").endsWith(".svg")
                    source: visible ? (modelData.icon || "") : ""
                    color: selected ? Colors.primary : Colors.textSecondary
                    size: Appearance.fontSizeXS
                }
                Text {
                    visible: !!(modelData.icon || "") && !String(modelData.icon || "").endsWith(".svg")
                    text: modelData.icon || ""
                    color: selected ? Colors.primary : Colors.textSecondary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeXS
                }

                Text {
                    text: modelData.shortLabel || modelData.label || ""
                    color: selected ? Colors.text : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: selected ? Font.Bold : Font.DemiBold
                }
            }

            SharedWidgets.StateLayer {
                id: chipState
                anchors.fill: parent
                hovered: chipMouse.containsMouse
                pressed: chipMouse.pressed
                stateColor: Colors.primary
                disabled: selected
            }

            MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !selected
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    chipState.burst(mouseX, mouseY);
                    root.tabRequested(String(modelData.id || ""));
                    if (!root.settingsRoot)
                        return;
                    if (root.settingsRoot.clearSettingHighlight)
                        root.settingsRoot.clearSettingHighlight();
                    if (root.settingsRoot.setCurrentTab)
                        root.settingsRoot.setCurrentTab(String(modelData.id || ""));
                }
            }
        }
    }
}

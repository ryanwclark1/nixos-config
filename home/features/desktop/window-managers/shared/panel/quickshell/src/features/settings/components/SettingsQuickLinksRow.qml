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
    spacing: Colors.spacingS
    visible: (tabsModel || []).length > 0

    Repeater {
        model: root.tabsModel || []

        delegate: Rectangle {
            required property var modelData

            readonly property bool selected: String(modelData.id || "") === root.currentTabId

            radius: Colors.radiusPill
            color: selected ? Colors.primarySubtle : Colors.modalFieldSurface
            border.color: selected ? Colors.primaryRing : Colors.border
            border.width: 1
            implicitHeight: 30
            implicitWidth: chipRow.implicitWidth + Colors.spacingM * 2

            Behavior on color {
                enabled: !Colors.isTransitioning
                ColorAnimation { duration: Colors.durationFast }
            }

            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: Colors.spacingXS

                Loader {
                    active: !!(modelData.icon || "")
                    visible: active
                    sourceComponent: (modelData.icon || "").endsWith(".svg") ? _qlSvgIcon : _qlNerdIcon
                }
                Component {
                    id: _qlSvgIcon
                    SharedWidgets.SvgIcon { source: modelData.icon || ""; color: selected ? Colors.primary : Colors.textSecondary; size: Colors.fontSizeXS }
                }
                Component {
                    id: _qlNerdIcon
                    Text {
                        text: modelData.icon || ""
                        color: selected ? Colors.primary : Colors.textSecondary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeXS
                    }
                }

                Text {
                    text: modelData.shortLabel || modelData.label || ""
                    color: selected ? Colors.text : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
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

import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root

    property var widgetInstance: null
    property var panelRef: null
    property string surfaceId: ""
    property string iconText: ""
    property string defaultLabel: ""
    property real iconSize: Appearance.fontSizeXL
    property string tooltipShortcutText: ""
    property var extraContextActions: []

    isActive: panelRef ? panelRef.isSurfaceActive(surfaceId) : false
    anchorWindow: panelRef ? panelRef.anchorWindow : null
    tooltipShortcut: tooltipShortcutText
    onClicked: if (panelRef) panelRef.requestSurface(surfaceId, this)
    contextActions: {
        var actions = [];
        for (var i = 0; i < extraContextActions.length; i++)
            actions.push(extraContextActions[i]);
        if (extraContextActions.length > 0)
            actions.push({ separator: true });
        actions.push({
            label: "Open " + tooltipText,
            icon: iconText,
            action: function() { if (root.panelRef) root.panelRef.requestSurface(root.surfaceId, root); }
        });
        return actions;
    }
    onContextMenuRequested: (actions, rect) => {
        if (panelRef) panelRef.contextMenuRequested(actions, rect);
    }

    Row {
        spacing: Appearance.spacingXS * root.iconScale

        Loader {
            sourceComponent: (root.iconText || "").endsWith(".svg") ? _bspSvg : _bspNerd
        }
        Component {
            id: _bspSvg
            SharedWidgets.SvgIcon {
                source: root.iconText
                color: Colors.text
                size: root.iconSize * root.iconScale
            }
        }
        Component {
            id: _bspNerd
            Text {
                text: root.iconText
                color: Colors.text
                font.pixelSize: root.iconSize * root.iconScale
                font.family: Appearance.fontMono
            }
        }

        Text {
            visible: root.panelRef ? !root.panelRef.triggerWidgetIconOnly(root.widgetInstance) : true
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            text: root.panelRef ? root.panelRef.triggerWidgetLabel(root.widgetInstance, root.defaultLabel) : root.defaultLabel
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

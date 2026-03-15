import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Item {
  id: root
  property var widgetInstance: null
  property var anchorWindow: null
  property bool compact: false
  property bool iconOnly: false

  implicitWidth: pill.width
  implicitHeight: pill.height

  SharedWidgets.Ref { service: ServiceUnitService }

  SharedWidgets.BarPill {
    id: pill
    anchorWindow: root.anchorWindow
    horizontalPadding: (root.compact || root.iconOnly) ? 6 : 10
    
    isActive: root.isSurfaceActive("devopsMenu")
    onClicked: root.requestSurface("devopsMenu", this)

    tooltipText: "DevOps & Services: " + ServiceUnitService.dockerContainers.length + " containers, " + ServiceUnitService.sshActiveCount + " SSH sessions"

    RowLayout {
      spacing: Colors.spacingS
      anchors.centerIn: parent

      Text {
        text: "󰒍"
        color: ServiceUnitService.sshActiveCount > 0 ? Colors.accent : (ServiceUnitService.dockerContainers.length > 0 ? Colors.primary : Colors.textSecondary)
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
      }

      Text {
        visible: !root.iconOnly && !root.compact
        text: {
            var parts = [];
            if (ServiceUnitService.dockerContainers.length > 0) parts.push("D:" + ServiceUnitService.dockerContainers.length);
            if (ServiceUnitService.sshActiveCount > 0) parts.push("S:" + ServiceUnitService.sshActiveCount);
            return parts.length > 0 ? parts.join(" ") : "DevOps";
        }
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
      }
    }
  }

  function isSurfaceActive(id) {
    // This will be resolved via Panel.qml's helper
    return root.parent && root.parent.isSurfaceActive && root.parent.isSurfaceActive(id);
  }

  function requestSurface(id, anchor) {
    if (root.parent && root.parent.requestSurface)
        root.parent.requestSurface(id, anchor);
  }
}

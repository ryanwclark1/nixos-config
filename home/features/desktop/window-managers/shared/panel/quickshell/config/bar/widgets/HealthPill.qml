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

  SharedWidgets.BarPill {
    id: pill
    anchorWindow: root.anchorWindow
    horizontalPadding: (root.compact || root.iconOnly) ? 6 : 10
    
    color: {
        switch (SystemStatus.overallStatus) {
            case "healthy": return Colors.withAlpha(Colors.surface, 0.4);
            case "warning": return Colors.withAlpha(Colors.warning, 0.15);
            case "manual_review_required": return Colors.withAlpha(Colors.error, 0.15);
            default: return Colors.withAlpha(Colors.textDisabled, 0.15);
        }
    }
    
    border.color: {
        switch (SystemStatus.overallStatus) {
            case "healthy": return Colors.border;
            case "warning": return Colors.warning;
            case "manual_review_required": return Colors.error;
            default: return Colors.textDisabled;
        }
    }

    onClicked: {
        // Open Settings Hub to Health tab
        Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "health"]);
    }

    tooltipText: "System Health: " + SystemStatus.overallStatus.replace(/_/g, " ")

    RowLayout {
      spacing: Colors.spacingS
      anchors.centerIn: parent

      Text {
        text: {
            switch (SystemStatus.overallStatus) {
                case "healthy": return "󰓅";
                case "warning": return "󰀪";
                case "manual_review_required": return "󰅚";
                default: return "󰓅";
            }
        }
        color: {
            switch (SystemStatus.overallStatus) {
                case "healthy": return Colors.textSecondary;
                case "warning": return Colors.warning;
                case "manual_review_required": return Colors.error;
                default: return Colors.textDisabled;
            }
        }
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        
        SequentialAnimation on opacity {
            running: SystemStatus.overallStatus !== "healthy"
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
        }
      }

      Text {
        visible: !root.iconOnly && !root.compact
        text: "Health"
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
      }
    }
  }
}

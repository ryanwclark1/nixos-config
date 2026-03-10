import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 280
  color: Colors.bgWidget
  radius: 12
  border.color: Colors.border

  SystemClock {
    id: calendarClock
    precision: SystemClock.Hours
  }

  property date today: calendarClock.date
  property date viewDate: calendarClock.date

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 10

    // Header: Month and Year
    RowLayout {
      Layout.fillWidth: true
      Text {
        text: root.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
        color: Colors.fgMain
        font.pixelSize: 16
        font.weight: Font.Bold
      }
      Item { Layout.fillWidth: true }
      // Navigation (Optional, keeping it simple for now)
    }

    // Day Labels
    RowLayout {
      Layout.fillWidth: true
      spacing: 0
      Repeater {
        model: ["S", "M", "T", "W", "T", "F", "S"]
        delegate: Text {
          Layout.fillWidth: true
          text: modelData
          color: Colors.textDisabled
          font.pixelSize: 11
          font.weight: Font.Bold
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    // Days Grid
    GridLayout {
      columns: 7
      Layout.fillWidth: true
      Layout.fillHeight: true
      rowSpacing: 5
      columnSpacing: 0

      Repeater {
        model: 42 // 6 weeks
        delegate: Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          color: "transparent"

          property int dayNumber: {
            var firstDay = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth(), 1).getDay();
            var d = index - firstDay + 1;
            var daysInMonth = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + 1, 0).getDate();
            return (d > 0 && d <= daysInMonth) ? d : -1;
          }

          property bool isToday: dayNumber === root.today.getDate() &&
                               root.viewDate.getMonth() === root.today.getMonth() &&
                               root.viewDate.getFullYear() === root.today.getFullYear()

          radius: 15
          border.color: isToday ? Colors.primary : "transparent"
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: parent.dayNumber > 0 ? parent.dayNumber : ""
            color: parent.isToday ? Colors.primary : (parent.dayNumber > 0 ? Colors.fgMain : "transparent")
            font.pixelSize: 12
            font.weight: parent.isToday ? Font.Bold : Font.Normal
          }
        }
      }
    }
  }
}

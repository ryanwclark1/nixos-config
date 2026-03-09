import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 280
  color: "#0dffffff"
  radius: 12
  border.color: "#33ffffff"

  property date today: new Date()
  property date viewDate: new Date()
  
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 10

    // Header: Month and Year
    RowLayout {
      Layout.fillWidth: true
      Text {
        text: root.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
        color: "#e6e6e6"
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
          color: "#666666"
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
          border.color: isToday ? "#4caf50" : "transparent"
          border.width: 1
          
          Text {
            anchors.centerIn: parent
            text: parent.dayNumber > 0 ? parent.dayNumber : ""
            color: parent.isToday ? "#4caf50" : (parent.dayNumber > 0 ? "#e6e6e6" : "transparent")
            font.pixelSize: 12
            font.weight: parent.isToday ? Font.Bold : Font.Normal
          }
        }
      }
    }
  }
}

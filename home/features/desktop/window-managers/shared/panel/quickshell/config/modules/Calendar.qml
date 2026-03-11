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
  property int calendarMonth: today.getMonth()
  property int calendarYear: today.getFullYear()

  // ── Navigation helpers ─────────────────────────
  function prevMonth() {
    if (calendarMonth === 0) { calendarMonth = 11; calendarYear--; }
    else calendarMonth--;
  }

  function nextMonth() {
    if (calendarMonth === 11) { calendarMonth = 0; calendarYear++; }
    else calendarMonth++;
  }

  function goToday() {
    calendarMonth = today.getMonth();
    calendarYear = today.getFullYear();
  }

  // ── Days model ─────────────────────────────────
  readonly property var daysModel: {
    var firstOfMonth = new Date(calendarYear, calendarMonth, 1);
    var daysBefore = firstOfMonth.getDay(); // 0=Sun
    var daysInMonth = new Date(calendarYear, calendarMonth + 1, 0).getDate();
    var daysInPrevMonth = new Date(calendarYear, calendarMonth, 0).getDate();

    var cells = [];

    // Previous month trailing days
    for (var b = daysBefore - 1; b >= 0; b--) {
      cells.push({ day: daysInPrevMonth - b, currentMonth: false, isToday: false });
    }

    // Current month
    var todayDate = today.getDate();
    var isTodayMonth = (calendarMonth === today.getMonth() && calendarYear === today.getFullYear());
    for (var d = 1; d <= daysInMonth; d++) {
      cells.push({ day: d, currentMonth: true, isToday: isTodayMonth && d === todayDate });
    }

    // Next month leading days (fill to 42 cells = 6 rows)
    var remaining = 42 - cells.length;
    for (var a = 1; a <= remaining; a++) {
      cells.push({ day: a, currentMonth: false, isToday: false });
    }

    return cells;
  }

  // ── Day-of-week headers ────────────────────────
  readonly property var dayHeaders: {
    var headers = [];
    for (var i = 0; i < 7; i++) {
      var name = Qt.locale().dayName(i, Locale.ShortFormat);
      headers.push(name.substring(0, 2).toUpperCase());
    }
    return headers;
  }

  // ── Month name ─────────────────────────────────
  readonly property string monthName: {
    var d = new Date(calendarYear, calendarMonth, 1);
    return d.toLocaleDateString(Qt.locale(), "MMMM yyyy");
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 8

    // Header: Month and Year with navigation
    RowLayout {
      Layout.fillWidth: true

      MouseArea {
        width: 24; height: 24
        hoverEnabled: true
        onClicked: root.prevMonth()
        Rectangle {
          anchors.fill: parent; radius: 12
          color: parent.containsMouse ? Colors.highlightLight : "transparent"
        }
        Text {
          anchors.centerIn: parent
          text: "󰍞"
          color: Colors.fgMain
          font.family: Colors.fontMono
          font.pixelSize: 14
        }
      }

      Item { Layout.fillWidth: true }

      MouseArea {
        width: monthLabel.implicitWidth + 8
        height: monthLabel.implicitHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.goToday()

        Text {
          id: monthLabel
          anchors.centerIn: parent
          text: root.monthName
          color: parent.containsMouse ? Colors.primary : Colors.fgMain
          font.pixelSize: 15
          font.weight: Font.Bold
          Behavior on color { ColorAnimation { duration: 150 } }
        }
      }

      Item { Layout.fillWidth: true }

      MouseArea {
        width: 24; height: 24
        hoverEnabled: true
        onClicked: root.nextMonth()
        Rectangle {
          anchors.fill: parent; radius: 12
          color: parent.containsMouse ? Colors.highlightLight : "transparent"
        }
        Text {
          anchors.centerIn: parent
          text: "󰍟"
          color: Colors.fgMain
          font.family: Colors.fontMono
          font.pixelSize: 14
        }
      }
    }

    // Day Labels
    RowLayout {
      Layout.fillWidth: true
      spacing: 0
      Repeater {
        model: root.dayHeaders
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
      rowSpacing: 2
      columnSpacing: 0

      Repeater {
        model: root.daysModel
        delegate: Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 28
          color: modelData.isToday ? Colors.primary : "transparent"
          radius: 14

          Text {
            anchors.centerIn: parent
            text: modelData.day
            color: modelData.isToday ? Colors.background
              : modelData.currentMonth ? Colors.fgMain
              : Colors.textDisabled
            font.pixelSize: 12
            font.weight: modelData.isToday ? Font.Bold : Font.Normal
            opacity: modelData.currentMonth ? 1.0 : 0.4
          }
        }
      }
    }
  }

  // Scroll navigation
  WheelHandler {
    onWheel: (event) => {
      if (event.angleDelta.y > 0) root.prevMonth();
      else root.nextMonth();
    }
  }
}

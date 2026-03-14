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
    monthTransition.restart();
    if (calendarMonth === 0) { calendarMonth = 11; calendarYear--; }
    else calendarMonth--;
  }

  function nextMonth() {
    monthTransition.restart();
    if (calendarMonth === 11) { calendarMonth = 0; calendarYear++; }
    else calendarMonth++;
  }

  // Month transition: brief opacity dip on the days grid
  SequentialAnimation {
    id: monthTransition
    NumberAnimation { target: daysGrid; property: "opacity"; to: 0.3; duration: 60 }
    NumberAnimation { target: daysGrid; property: "opacity"; to: 1.0; duration: Colors.durationFast; easing.type: Easing.OutCubic }
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

  readonly property bool isCurrentMonth: calendarMonth === today.getMonth() && calendarYear === today.getFullYear()

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: Colors.spacingS

    // Header: Month and Year with navigation
    RowLayout {
      Layout.fillWidth: true

      MouseArea {
        width: 24; height: 24
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.prevMonth()
        Rectangle {
          anchors.fill: parent; radius: 12
          color: parent.containsMouse ? Colors.highlightLight : "transparent"
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        }
        Text {
          anchors.centerIn: parent
          text: "󰍞"
          color: Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeMedium
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
          color: parent.containsMouse ? Colors.primary : Colors.text
          font.pixelSize: Colors.fontSizeLarge
          font.weight: Font.Bold
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        }
      }

      Item { Layout.fillWidth: true }

      // "Today" pill button (visible when not viewing current month)
      MouseArea {
        visible: !root.isCurrentMonth
        width: todayLabel.implicitWidth + 16
        height: 22
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.goToday()

        Rectangle {
          anchors.fill: parent
          radius: 11
          color: parent.containsMouse ? Colors.primary : Colors.highlightLight
          border.color: Colors.primary
          border.width: 1
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        }

        Text {
          id: todayLabel
          anchors.centerIn: parent
          text: "Today"
          color: parent.containsMouse ? Colors.background : Colors.primary
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Bold
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        }
      }

      MouseArea {
        width: 24; height: 24
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.nextMonth()
        Rectangle {
          anchors.fill: parent; radius: 12
          color: parent.containsMouse ? Colors.highlightLight : "transparent"
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        }
        Text {
          anchors.centerIn: parent
          text: "󰍟"
          color: Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeMedium
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
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Bold
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    // Days Grid with month transition fade
    GridLayout {
      id: daysGrid
      columns: 7
      Layout.fillWidth: true
      Layout.fillHeight: true
      rowSpacing: 2
      columnSpacing: 0

      Behavior on opacity { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

      Repeater {
        model: root.daysModel
        delegate: Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 28
          color: modelData.isToday ? Colors.primary
            : dayMouse.containsMouse && modelData.currentMonth ? Colors.highlightLight
            : "transparent"
          radius: Colors.radiusMedium
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }

          Text {
            anchors.centerIn: parent
            text: modelData.day
            color: modelData.isToday ? Colors.background
              : modelData.currentMonth ? Colors.text
              : Colors.textDisabled
            font.pixelSize: Colors.fontSizeSmall
            font.weight: modelData.isToday ? Font.Bold : Font.Normal
            opacity: modelData.currentMonth ? 1.0 : 0.4
          }

          MouseArea {
            id: dayMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: modelData.currentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
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

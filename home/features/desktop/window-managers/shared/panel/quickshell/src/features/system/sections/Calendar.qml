import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 300
  color: Colors.cardSurface
  radius: Colors.radiusLarge
  border.color: Colors.border
  clip: true

  // Inner highlight
  SharedWidgets.InnerHighlight { highlightOpacity: 0.1 }
  SharedWidgets.SurfaceGradient {}

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
    NumberAnimation { target: daysGrid; property: "opacity"; to: 0.3; duration: Colors.durationFlash }
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
      Layout.bottomMargin: Colors.spacingS

      MouseArea {
        width: 32; height: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.prevMonth()
        Rectangle {
          anchors.fill: parent; radius: Colors.radiusSmall
          color: parent.containsMouse ? Colors.highlightLight : "transparent"
          Behavior on color { CAnim {} }
        }
        Text {
          anchors.centerIn: parent
          text: "󰍞"
          color: Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
        }
      }

      Item { Layout.fillWidth: true }

      Text {
        id: monthLabel
        text: root.monthName
        color: Colors.text
        font.pixelSize: Colors.fontSizeLarge
        font.weight: Font.Bold
      }

      // "Today" dot (visible when viewing current month)
      Rectangle {
        visible: root.isCurrentMonth
        width: 6; height: 6
        radius: 3
        color: Colors.primary
        Layout.leftMargin: Colors.spacingXS
      }

      Item { Layout.fillWidth: true }

      // "Today" pill button (visible when not viewing current month)
      MouseArea {
        visible: !root.isCurrentMonth
        width: todayLabel.implicitWidth + 24
        height: 28
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.goToday()

        Rectangle {
          anchors.fill: parent
          radius: height / 2
          color: parent.containsMouse ? Colors.primary : Colors.highlightLight
          border.color: Colors.primary
          border.width: 1
          Behavior on color { CAnim {} }
        }

        Text {
          id: todayLabel
          anchors.centerIn: parent
          text: "Today"
          color: parent.containsMouse ? Colors.background : Colors.primary
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Bold
          Behavior on color { CAnim {} }
        }
      }

      MouseArea {
        width: 32; height: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.nextMonth()
        Rectangle {
          anchors.fill: parent; radius: Colors.radiusSmall
          color: parent.containsMouse ? Colors.highlightLight : "transparent"
          Behavior on color { CAnim {} }
        }
        Text {
          anchors.centerIn: parent
          text: "󰍟"
          color: Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
        }
      }
    }

    // Day Labels
    RowLayout {
      Layout.fillWidth: true
      spacing: 0
      Layout.bottomMargin: Colors.spacingXS
      Repeater {
        model: root.dayHeaders
        delegate: Text {
          Layout.fillWidth: true
          text: modelData
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXXS
          font.weight: Font.Bold
          font.letterSpacing: 1.0
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
      rowSpacing: 4
      columnSpacing: 0

      Behavior on opacity { Anim { duration: Colors.durationFast } }

      Repeater {
        model: root.daysModel
        delegate: Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 32

          Rectangle {
            anchors.centerIn: parent
            width: 32; height: 32
            color: modelData.isToday ? Colors.primary
              : dayMouse.containsMouse && modelData.currentMonth ? Colors.highlightLight
              : "transparent"
            radius: width / 2
            Behavior on color { CAnim {} }

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

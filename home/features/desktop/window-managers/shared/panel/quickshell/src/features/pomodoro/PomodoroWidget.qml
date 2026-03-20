import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

ThemedContainer {
  id: root
  variant: "card"
  radius: Colors.radiusCard

  implicitWidth: 280
  implicitHeight: column.implicitHeight + Colors.spacingL * 2

  // ── Derived state ────────────────────────────
  readonly property color lapColor: PomodoroService.isBreak ? Colors.success : Colors.primary
  readonly property string lapLabel: PomodoroService.isLongBreak ? "LONG BREAK"
    : PomodoroService.isBreak ? "BREAK" : "FOCUS"

  ColumnLayout {
    id: column
    anchors {
      left: parent.left; right: parent.right
      top: parent.top
      margins: Colors.spacingL
    }
    spacing: Colors.spacingM

    // ── Status label ─────────────────────────
    RowLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingS

      Text {
        text: root.lapLabel
        color: root.lapColor
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.Black
        font.letterSpacing: Colors.letterSpacingWide
      }

      Item { Layout.fillWidth: true }

      // Cycle dots
      Row {
        spacing: Colors.spacingXXS
        Repeater {
          model: PomodoroService.cyclesBeforeLongBreak
          delegate: Rectangle {
            width: 6; height: 6
            radius: Colors.radiusXS3
            color: index < PomodoroService.cycle
              ? Colors.primary
              : Colors.withAlpha(Colors.text, Colors.textFaint * 2)
          }
        }
      }
    }

    // ── Ring + time display ──────────────────
    Item {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 140
      Layout.preferredHeight: 140

      // Background track
      Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
          fillColor: "transparent"
          strokeColor: Colors.withAlpha(root.lapColor, Colors.primaryFaint)
          strokeWidth: 8
          capStyle: ShapePath.RoundCap
          PathAngleArc {
            centerX: 70; centerY: 70
            radiusX: 62; radiusY: 62
            startAngle: 0
            sweepAngle: 360
          }
        }
      }

      // Progress arc
      Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
          fillColor: "transparent"
          strokeColor: root.lapColor
          strokeWidth: 8
          capStyle: ShapePath.RoundCap

          PathAngleArc {
            centerX: 70; centerY: 70
            radiusX: 62; radiusY: 62
            startAngle: -90
            sweepAngle: PomodoroService.progress * 360

            Behavior on sweepAngle {
              NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutQuad }
            }
          }
        }
      }

      // Time display
      ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingXXS

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: PomodoroService.timeDisplay
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
          font.family: Colors.fontMono
          font.letterSpacing: Colors.letterSpacingTight
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: PomodoroService.running ? "running" : "paused"
          color: Colors.withAlpha(Colors.text, Colors.textThin)
          font.pixelSize: Colors.fontSizeXXS
          font.weight: Font.Medium
          font.letterSpacing: Colors.letterSpacingWide
        }
      }
    }

    // ── Controls ─────────────────────────────
    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Colors.spacingXS
      spacing: Colors.spacingS

      Item { Layout.fillWidth: true }

      // Reset
      SharedWidgets.IconButton {
        icon: ""
        size: 34
        iconSize: Colors.fontSizeMedium
        iconColor: Colors.textSecondary
        stateColor: Colors.text
        tooltipText: "Reset timer"
        onClicked: PomodoroService.reset()
      }

      // Play / Pause
      SharedWidgets.IconButton {
        icon: PomodoroService.running ? "" : ""
        size: 44
        iconSize: Colors.fontSizeXL
        iconColor: root.lapColor
        stateColor: root.lapColor
        normalColor: Colors.withAlpha(root.lapColor, Colors.primaryFaint)
        hoverColor: Colors.withAlpha(root.lapColor, Colors.primarySubtle)
        tooltipText: PomodoroService.running ? "Pause" : "Start"
        onClicked: PomodoroService.toggle()
      }

      // Skip
      SharedWidgets.IconButton {
        icon: "next.svg"
        size: 34
        iconSize: Colors.fontSizeMedium
        iconColor: Colors.textSecondary
        stateColor: Colors.text
        tooltipText: "Skip"
        onClicked: PomodoroService.skip()
      }

      Item { Layout.fillWidth: true }
    }
  }
}

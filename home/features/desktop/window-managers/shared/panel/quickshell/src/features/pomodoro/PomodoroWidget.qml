import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

ThemedContainer {
  id: root
  variant: "card"
  radius: Appearance.radiusCard

  implicitWidth: 280
  implicitHeight: column.implicitHeight + Appearance.spacingL * 2

  // ── Derived state ────────────────────────────
  readonly property color lapColor: PomodoroService.isBreak ? Colors.success : Colors.primary
  readonly property string lapLabel: PomodoroService.isLongBreak ? "LONG BREAK"
    : PomodoroService.isBreak ? "BREAK" : "FOCUS"

  ColumnLayout {
    id: column
    anchors {
      left: parent.left; right: parent.right
      top: parent.top
      margins: Appearance.spacingL
    }
    spacing: Appearance.spacingM

    // ── Status label ─────────────────────────
    RowLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingS

      Text {
        text: root.lapLabel
        color: root.lapColor
        font.pixelSize: Appearance.fontSizeXS
        font.weight: Font.Black
        font.letterSpacing: Appearance.letterSpacingWide
      }

      Item { Layout.fillWidth: true }

      // Cycle dots
      Row {
        spacing: Appearance.spacingXXS
        Repeater {
          model: PomodoroService.cyclesBeforeLongBreak
          delegate: Rectangle {
            width: 6; height: 6
            radius: Appearance.radiusXS3
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
              NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutQuad }
            }
          }
        }
      }

      // Time display
      ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacingXXS

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: PomodoroService.timeDisplay
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
          font.family: Appearance.fontMono
          font.letterSpacing: Appearance.letterSpacingTight
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: PomodoroService.running ? "running" : "paused"
          color: Colors.withAlpha(Colors.text, Colors.textThin)
          font.pixelSize: Appearance.fontSizeXXS
          font.weight: Font.Medium
          font.letterSpacing: Appearance.letterSpacingWide
        }
      }
    }

    // ── Controls ─────────────────────────────
    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Appearance.spacingXS
      spacing: Appearance.spacingS

      Item { Layout.fillWidth: true }

      // Reset
      SharedWidgets.IconButton {
        icon: ""
        size: 34
        iconSize: Appearance.fontSizeMedium
        iconColor: Colors.textSecondary
        stateColor: Colors.text
        tooltipText: "Reset timer"
        onClicked: PomodoroService.reset()
      }

      // Play / Pause
      SharedWidgets.IconButton {
        icon: PomodoroService.running ? "" : ""
        size: 44
        iconSize: Appearance.fontSizeXL
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
        iconSize: Appearance.fontSizeMedium
        iconColor: Colors.textSecondary
        stateColor: Colors.text
        tooltipText: "Skip"
        onClicked: PomodoroService.skip()
      }

      Item { Layout.fillWidth: true }
    }
  }
}

import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../shared" as SharedWidgets

Rectangle {
  id: root
  required property bool active
  required property int seconds

  signal revertRequested()
  signal confirmRequested()

  visible: active
  color: Colors.withAlpha(Colors.background, 0.94)
  radius: Colors.radiusLarge

  opacity: active ? 1.0 : 0.0
  Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

  ColumnLayout {
    anchors.centerIn: parent
    spacing: Colors.spacingXL

    // Big countdown ring / number
    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 110; height: 110

      Canvas {
        id: cdCanvas
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d");
          ctx.clearRect(0, 0, width, height);
          var cx = width / 2, cy = height / 2, r = 46;
          // Track
          ctx.beginPath();
          ctx.arc(cx, cy, r, 0, Math.PI * 2);
          ctx.strokeStyle = Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.4);
          ctx.lineWidth = 5;
          ctx.stroke();
          // Progress arc
          var progress = root.seconds / 30.0;
          ctx.beginPath();
          ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progress * Math.PI * 2);
          ctx.strokeStyle = Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.9);
          ctx.lineWidth = 5;
          ctx.lineCap = "round";
          ctx.stroke();
        }

      }

      Connections {
        target: root
        function onSecondsChanged() { cdCanvas.requestPaint(); }
      }

      Text {
        anchors.centerIn: parent
        text: root.seconds.toString()
        color: root.seconds <= 5 ? Colors.error : Colors.text
        font.pixelSize: 36
        font.weight: Font.Bold
        Behavior on color { ColorAnimation { duration: Colors.durationSlow } }
      }
    }

    Text {
      text: "Keep this display configuration?"
      color: Colors.text
      font.pixelSize: Colors.fontSizeLarge
      font.weight: Font.Bold
      Layout.alignment: Qt.AlignHCenter
    }

    Text {
      text: "Reverting in " + root.seconds + " seconds…"
      color: Colors.textSecondary
      font.pixelSize: Colors.fontSizeSmall
      Layout.alignment: Qt.AlignHCenter
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: Colors.spacingL

      // Revert Now
      Rectangle {
        width: 140; height: 44
        radius: Colors.radiusSmall
        color: Colors.withAlpha(Colors.error, 0.12)
        border.color: Colors.error
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: Colors.spacingS
          Text { text: "󰜺"; color: Colors.error; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
          Text { text: "Revert Now"; color: Colors.error; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold }
        }

        SharedWidgets.StateLayer {
          id: revertNowSL
          hovered: revertNowHover.containsMouse
          pressed: revertNowHover.containsPress
          stateColor: Colors.error
        }
        MouseArea {
          id: revertNowHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => { revertNowSL.burst(mouse.x, mouse.y); root.revertRequested(); }
        }
      }

      // Keep Changes
      Rectangle {
        width: 150; height: 44
        radius: Colors.radiusSmall
        color: Colors.withAlpha(Colors.secondary, 0.12)
        border.color: Colors.secondary
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: Colors.spacingS
          Text { text: "󰄬"; color: Colors.secondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
          Text { text: "Keep Changes"; color: Colors.secondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold }
        }

        SharedWidgets.StateLayer {
          id: keepSL
          hovered: keepHover.containsMouse
          pressed: keepHover.containsPress
          stateColor: Colors.secondary
        }
        MouseArea {
          id: keepHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => { keepSL.burst(mouse.x, mouse.y); root.confirmRequested(); }
        }
      }
    }
  }
}

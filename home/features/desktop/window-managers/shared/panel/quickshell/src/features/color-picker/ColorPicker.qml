import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../services/ColorUtils.js" as ColorUtils
import "../../widgets" as SharedWidgets
import "../../shared"

PanelWindow {
  id: root
  property var screenRef: Quickshell.cursorScreen || Config.primaryScreen()
  screen: screenRef
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
  readonly property int usableWidth: Math.max(0, width - edgeMargins.left - edgeMargins.right)
  readonly property int usableHeight: Math.max(0, height - edgeMargins.top - edgeMargins.bottom)

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  color: "transparent"
  visible: isOpen

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  // --- Public API ---
  property bool isOpen: false

  // Color state (HSV + alpha)
  property real hue: 0.62          // 0.0 – 1.0
  property real saturation: 0.75   // 0.0 – 1.0
  property real value: 0.85        // 0.0 – 1.0
  property real alpha: 1.0         // 0.0 – 1.0

  readonly property color currentColor: Qt.hsva(hue, saturation, value, alpha)

  // Hex string derived from current color (no alpha channel)
  readonly property string hexValue: {
    var r = Math.round(currentColor.r * 255);
    var g = Math.round(currentColor.g * 255);
    var b = Math.round(currentColor.b * 255);
    return "#"
      + ("0" + r.toString(16)).slice(-2).toUpperCase()
      + ("0" + g.toString(16)).slice(-2).toUpperCase()
      + ("0" + b.toString(16)).slice(-2).toUpperCase();
  }

  function open() {
    isOpen = true;
    svCanvas.requestPaint();
    hueCanvas.requestPaint();
    alphaCanvas.requestPaint();
  }

  function close() {
    isOpen = false;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  // Push a color to the recent list and persist it
  function addRecent(c) {
    var hex = {
      r: Math.round(c.r * 255),
      g: Math.round(c.g * 255),
      b: Math.round(c.b * 255)
    };
    var hexStr = "#"
      + ("0" + hex.r.toString(16)).slice(-2).toUpperCase()
      + ("0" + hex.g.toString(16)).slice(-2).toUpperCase()
      + ("0" + hex.b.toString(16)).slice(-2).toUpperCase();

    var list = Config.recentPickerColors.slice();
    // Remove duplicate if present
    var idx = list.indexOf(hexStr);
    if (idx !== -1) list.splice(idx, 1);
    list.unshift(hexStr);
    if (list.length > 8) list = list.slice(0, 8);
    Config.recentPickerColors = list;
  }

  // Apply a hex string (e.g. "#FF0080") to the HSV state
  function applyHex(hex) {
    var clean = hex.replace(/^#/, "");
    if (clean.length !== 6) return;
    var r = parseInt(clean.substring(0, 2), 16);
    var g = parseInt(clean.substring(2, 4), 16);
    var b = parseInt(clean.substring(4, 6), 16);
    var hsv = ColorUtils.rgbToHsv(r, g, b);
    root.hue        = hsv.h / 360;
    root.saturation = hsv.s;
    root.value      = hsv.v;
  }

  // Clipboard copy helper
  Process {
    id: clipboardProc
    command: ["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", root.hexValue]
    running: false
  }

  IpcHandler {
    target: "ColorPicker"
    function open()   { root.open();   }
    function close()  { root.close();  }
    function toggle() { root.toggle(); }
  }

  // ─── Background scrim ─────────────────────────────────────────────────────
  MouseArea {
    anchors.fill: parent
    onClicked: root.close()

    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: 0.55
    }
  }

  SharedWidgets.ElasticNumber {
    id: _cpElasticScale
    target: root.isOpen ? 1.0 : 0.94
    fastDuration: Appearance.durationSnap
    slowDuration: Appearance.durationNormal
    fastWeight: 0.45
  }

  // ─── Modal card ───────────────────────────────────────────────────────────
  Rectangle {
    id: mainBox
    width: Math.min(Math.max(320, root.usableWidth - 40), 420)
    height: mainColumn.implicitHeight + 48
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: root.edgeMargins.top + Math.max(20, (root.usableHeight - height) / 2)
    anchors.leftMargin: root.edgeMargins.left + Math.max(20, (root.usableWidth - width) / 2)

    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusLarge

    focus: root.isOpen
    onVisibleChanged: {
      if (visible)
        forceActiveFocus();
      else if (activeFocus)
        focus = false;
    }
    Keys.onEscapePressed: root.close()

    opacity: root.isOpen ? 1.0 : 0.0
    scale:   _cpElasticScale.value
    Behavior on opacity { NumberAnimation { id: cpFadeAnim;  duration: Appearance.durationMedium; easing.type: Easing.OutCubic } }
    layer.enabled: cpFadeAnim.running || _cpElasticScale.running

    // Block background click-through
    MouseArea { anchors.fill: parent }

    SharedWidgets.ElevationShadow { elevation: 16; shadowRadius: mainBox.radius }

    // ── Content column ──────────────────────────────────────────────────────
    ColumnLayout {
      id: mainColumn
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: Appearance.spacingLG
        leftMargin: Appearance.paddingLarge
        rightMargin: Appearance.paddingLarge
      }
      spacing: Appearance.spacingL

      // ── Header ──────────────────────────────────────────────────────────
      RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.paddingSmall

        Text {
          text: "󰈊"
          color: Colors.primary
          font.family: Appearance.fontMono
          font.pixelSize: Appearance.fontSizeXL
        }

        Text {
          text: "Color Picker"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeLarge
          font.weight: Font.Bold
          font.letterSpacing: Appearance.letterSpacingTight
          Layout.fillWidth: true
        }

        SharedWidgets.MenuCloseButton {
          onClicked: root.close()
        }
      }

      // ── SV (saturation/value) gradient canvas ────────────────────────────
      Item {
        Layout.fillWidth: true
        height: 200

        Canvas {
          id: svCanvas
          anchors.fill: parent
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded

          onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // 1) Base hue fill
            ctx.fillStyle = Qt.hsva(root.hue, 1.0, 1.0, 1.0).toString();
            ctx.fillRect(0, 0, width, height);

            // 2) White → transparent (saturation axis, left→right)
            var satGrad = ctx.createLinearGradient(0, 0, width, 0);
            satGrad.addColorStop(0, "rgba(255,255,255,1)");
            satGrad.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = satGrad;
            ctx.fillRect(0, 0, width, height);

            // 3) Transparent → black (value axis, top→bottom)
            var valGrad = ctx.createLinearGradient(0, 0, 0, height);
            valGrad.addColorStop(0, "rgba(0,0,0,0)");
            valGrad.addColorStop(1, "rgba(0,0,0,1)");
            ctx.fillStyle = valGrad;
            ctx.fillRect(0, 0, width, height);
          }

          Connections {
            target: root
            function onHueChanged() { svCanvas.requestPaint(); }
          }

          // Crosshair position
          property real crossX: root.saturation * width
          property real crossY: (1.0 - root.value) * height

          Behavior on crossX { SpringAnimation { spring: 3; damping: 0.8; epsilon: 0.5 } }
          Behavior on crossY { SpringAnimation { spring: 3; damping: 0.8; epsilon: 0.5 } }

          // Outer ring
          Rectangle {
            x: svCanvas.crossX - width / 2
            y: svCanvas.crossY - height / 2
            width: 18
            height: 18
            radius: height / 2
            color: "transparent"
            border.color: "white"
            border.width: 2

            // Inner colored dot
            Rectangle {
              anchors.centerIn: parent
              width: 10
              height: 10
              radius: width / 2
              color: root.currentColor
            }
          }

          // Drag interaction
          MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape: Qt.CrossCursor

            function updateSV(mx, my) {
              root.saturation = Math.max(0, Math.min(1, mx / width));
              root.value      = Math.max(0, Math.min(1, 1.0 - my / height));
            }

            onPressed:         (e) => updateSV(e.x, e.y)
            onPositionChanged: (e) => { if (pressed) updateSV(e.x, e.y) }
          }
        }
      }

      // ── Hue slider ────────────────────────────────────────────────────────
      Item {
        Layout.fillWidth: true
        height: 22

        Canvas {
          id: hueCanvas
          anchors.fill: parent
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded

          onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0/6, "#FF0000");
            grad.addColorStop(1/6, "#FFFF00");
            grad.addColorStop(2/6, "#00FF00");
            grad.addColorStop(3/6, "#00FFFF");
            grad.addColorStop(4/6, "#0000FF");
            grad.addColorStop(5/6, "#FF00FF");
            grad.addColorStop(6/6, "#FF0000");
            ctx.fillStyle = grad;
            var r = height / 2;
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.lineTo(width - r, 0);
            ctx.arcTo(width, 0, width, height, r);
            ctx.lineTo(width - r, height);
            ctx.lineTo(r, height);
            ctx.arcTo(0, height, 0, 0, r);
            ctx.closePath();
            ctx.fill();
          }

          // Thumb
          Rectangle {
            x: root.hue * parent.width - width / 2
            y: (parent.height - height) / 2
            width: 14
            height: 14
            radius: width / 2
            color: Qt.hsva(root.hue, 1.0, 1.0, 1.0)
            border.color: "white"
            border.width: 2

            Behavior on x { SpringAnimation { spring: 4; damping: 0.9; epsilon: 0.5 } }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function updateHue(mx) {
              root.hue = Math.max(0, Math.min(1, mx / width));
              svCanvas.requestPaint();
              alphaCanvas.requestPaint();
            }

            onPressed:         (e) => updateHue(e.x)
            onPositionChanged: (e) => { if (pressed) updateHue(e.x) }
          }
        }
      }

      // ── Alpha slider ───────────────────────────────────────────────────────
      Item {
        Layout.fillWidth: true
        height: 16

        // Checkerboard background to show transparency
        Canvas {
          id: checkerCanvas
          anchors.fill: parent
          renderStrategy: Canvas.Cooperative

          onPaint: {
            var ctx = getContext("2d");
            var size = 8;
            for (var col = 0; col * size < width; col++) {
              for (var row = 0; row * size < height; row++) {
                ctx.fillStyle = (col + row) % 2 === 0 ? "#CCCCCC" : "#999999";
                ctx.fillRect(col * size, row * size, size, size);
              }
            }
          }
        }

        Canvas {
          id: alphaCanvas
          anchors.fill: parent
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded

          onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var r = height / 2;
            var baseColor = Qt.hsva(root.hue, root.saturation, root.value, 1.0);
            var grad = ctx.createLinearGradient(0, 0, width, 0);
            grad.addColorStop(0, "rgba(" + Math.round(baseColor.r*255) + ","
                                         + Math.round(baseColor.g*255) + ","
                                         + Math.round(baseColor.b*255) + ",0)");
            grad.addColorStop(1, "rgba(" + Math.round(baseColor.r*255) + ","
                                         + Math.round(baseColor.g*255) + ","
                                         + Math.round(baseColor.b*255) + ",1)");
            ctx.fillStyle = grad;
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.lineTo(width - r, 0);
            ctx.arcTo(width, 0, width, height, r);
            ctx.lineTo(width - r, height);
            ctx.lineTo(r, height);
            ctx.arcTo(0, height, 0, 0, r);
            ctx.closePath();
            ctx.fill();
          }

          Connections {
            target: root
            function onHueChanged() { alphaCanvas.requestPaint(); }
            function onSaturationChanged() { alphaCanvas.requestPaint(); }
            function onValueChanged() { alphaCanvas.requestPaint(); }
          }

          // Thumb
          Rectangle {
            x: root.alpha * parent.width - width / 2
            y: (parent.height - height) / 2
            width: 12
            height: 12
            radius: Appearance.radiusXXS
            color: root.currentColor
            border.color: "white"
            border.width: 2

            Behavior on x { SpringAnimation { spring: 4; damping: 0.9; epsilon: 0.5 } }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function updateAlpha(mx) {
              root.alpha = Math.max(0, Math.min(1, mx / width));
            }

            onPressed:         (e) => updateAlpha(e.x)
            onPositionChanged: (e) => { if (pressed) updateAlpha(e.x) }
          }
        }
      }

      // ── Preview + hex input row ────────────────────────────────────────────
      RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Color preview circle
        Rectangle {
          width: 44
          height: 44
          radius: Appearance.radiusXL
          color: root.currentColor
          border.color: Colors.border
          border.width: 1
        }

        // Hex text input
        Rectangle {
          Layout.fillWidth: true
          height: 44
          radius: Appearance.radiusSmall
          color: Colors.bgWidget
          border.color: hexInput.activeFocus ? Colors.primary : Colors.border
          border.width: 1
          Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

          RowLayout {
            anchors { fill: parent; leftMargin: Appearance.spacingM; rightMargin: Appearance.spacingM }
            spacing: Appearance.spacingSM

            Text {
              text: "#"
              color: Colors.textDisabled
              font.family: Appearance.fontMono
              font.pixelSize: Appearance.fontSizeMedium
            }

            TextInput {
              id: hexInput
              Layout.fillWidth: true
              color: Colors.text
              font.family: Appearance.fontMono
              font.pixelSize: Appearance.fontSizeMedium
              font.capitalization: Font.AllUppercase
              maximumLength: 7
              text: root.hexValue
              onVisibleChanged: if (!visible && activeFocus) focus = false

              // When user edits hex, apply to color state
              onEditingFinished: {
                var val = text.startsWith("#") ? text : "#" + text;
                root.applyHex(val);
              }

              // Keep in sync when color changes externally (but not while user is typing)
              Connections {
                target: root
                function onHexValueChanged() {
                  if (!hexInput.activeFocus) hexInput.text = root.hexValue;
                }
              }
            }
          }
        }

        // Copy to clipboard button
        Rectangle {
          width: 44
          height: 44
          radius: Appearance.radiusSmall
          color: Colors.bgWidget
          border.color: copyHover.containsMouse ? Colors.primary : Colors.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: clipCopied.running ? "󰄬" : "󰆏"
            color: clipCopied.running ? Colors.primary : Colors.textSecondary
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeLarge
          }

          readonly property int _copyFeedbackMs: 1500

          Timer {
            id: clipCopied
            interval: parent._copyFeedbackMs
          }

          SharedWidgets.StateLayer {
            id: copyStateLayer
            anchors.fill: parent
            radius: parent.radius
            hovered: copyHover.containsMouse
            pressed: copyHover.pressed
          }

          MouseArea {
            id: copyHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              copyStateLayer.burst(mouse.x, mouse.y);
              clipboardProc.command = ["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", root.hexValue];
              clipboardProc.running = true;
              clipCopied.restart();
            }
          }
        }
      }

      // ── RGB sliders ────────────────────────────────────────────────────────
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingS

        Repeater {
          model: [
            { label: "R", value: Math.round(root.currentColor.r * 255), maxVal: 255,
              h: 0.0, s: 1.0, v: 1.0 },
            { label: "G", value: Math.round(root.currentColor.g * 255), maxVal: 255,
              h: 0.33, s: 1.0, v: 1.0 },
            { label: "B", value: Math.round(root.currentColor.b * 255), maxVal: 255,
              h: 0.66, s: 1.0, v: 1.0 }
          ]

          delegate: RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
              text: modelData.label
              color: Qt.hsva(modelData.h, modelData.s, modelData.v, 1.0)
              font.family: Appearance.fontMono
              font.pixelSize: Appearance.fontSizeSmall
              font.weight: Font.Bold
              Layout.preferredWidth: 12
            }

            Rectangle {
              Layout.fillWidth: true
              height: 6
              radius: Appearance.radiusXS
              color: Colors.surface

              Rectangle {
                width: Math.max(radius * 2, parent.width * (modelData.value / 255))
                height: parent.height
                radius: parent.radius
                color: Qt.hsva(modelData.h, modelData.s, modelData.v, 1.0)
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function updateChannel(mx) {
                  var ratio = Math.max(0, Math.min(1, mx / width));
                  var newVal = Math.round(ratio * 255);
                  var r = modelData.label === "R" ? newVal : Math.round(root.currentColor.r * 255);
                  var g = modelData.label === "G" ? newVal : Math.round(root.currentColor.g * 255);
                  var b = modelData.label === "B" ? newVal : Math.round(root.currentColor.b * 255);
                  var hsv = ColorUtils.rgbToHsv(r, g, b);
                  root.hue        = hsv.h / 360;
                  root.saturation = hsv.s;
                  root.value      = hsv.v;
                }

                onPressed:         (e) => updateChannel(e.x)
                onPositionChanged: (e) => { if (pressed) updateChannel(e.x) }
              }
            }

            Text {
              text: modelData.value
              color: Colors.textDisabled
              font.family: Appearance.fontMono
              font.pixelSize: Appearance.fontSizeXS
              Layout.preferredWidth: 28
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }

      // ── Separator ──────────────────────────────────────────────────────────
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // ── Preset swatches ────────────────────────────────────────────────────
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingS

        Text {
          text: "PRESETS"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Black
          font.letterSpacing: Appearance.letterSpacingExtraWide
        }

        readonly property var presetColors: [
          "#FF0000", "#FF5722", "#FF9800", "#FFC107",
          "#FFEB3B", "#8BC34A", "#4CAF50", "#009688",
          "#00BCD4", "#03A9F4", "#2196F3", "#3F51B5",
          "#673AB7", "#9C27B0", "#E91E63", "#F44336",
          "#795548", "#9E9E9E", "#607D8B", "#000000",
          "#FFFFFF", "#F5F5F5", "#BDBDBD", "#424242"
        ]

        Flow {
          Layout.fillWidth: true
          spacing: Appearance.spacingSM

          Repeater {
            model: parent.parent.presetColors

            delegate: Rectangle {
              width: 28
              height: 28
              radius: Appearance.radiusXXS
              color: modelData
              border.color: Colors.border
              border.width: 1

              scale: swatchMouse.containsMouse ? 1.15 : 1.0
              Behavior on scale { NumberAnimation { duration: Appearance.durationSnap; easing.type: Easing.OutBack } }

              MouseArea {
                id: swatchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyHex(modelData)
              }
            }
          }
        }
      }

      // ── Recent colors ──────────────────────────────────────────────────────
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingS
        visible: Config.recentPickerColors && Config.recentPickerColors.length > 0

        Text {
          text: "RECENT"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Black
          font.letterSpacing: Appearance.letterSpacingExtraWide
        }

        Row {
          spacing: Appearance.spacingSM

          Repeater {
            model: Config.recentPickerColors

            delegate: Rectangle {
              width: 28
              height: 28
              radius: Appearance.radiusXXS
              color: modelData
              border.color: Colors.border
              border.width: 1

              scale: recentMouse.containsMouse ? 1.15 : 1.0
              Behavior on scale { NumberAnimation { duration: Appearance.durationSnap; easing.type: Easing.OutBack } }

              MouseArea {
                id: recentMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyHex(modelData)
              }
            }
          }
        }
      }

      // ── Pick button ────────────────────────────────────────────────────────
      Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: Appearance.radiusMedium
        color: Colors.primary

        RowLayout {
          anchors.centerIn: parent
          spacing: Appearance.spacingS

          Rectangle {
            width: 18
            height: 18
            radius: height / 2
            color: root.currentColor
            border.color: "white"
            border.width: 1.5
          }

          Text {
            text: "Pick " + root.hexValue
            color: Colors.text
            font.pixelSize: Appearance.fontSizeMedium
            font.weight: Font.Bold
            font.family: Appearance.fontMono
          }
        }

        SharedWidgets.StateLayer {
          id: pickStateLayer
          anchors.fill: parent
          radius: parent.radius
          stateColor: Colors.primary
          hovered: pickHover.containsMouse
          pressed: pickHover.pressed
        }

        MouseArea {
          id: pickHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            pickStateLayer.burst(mouse.x, mouse.y);
            root.addRecent(root.currentColor);
            root.close();
          }
        }
      }

      // Bottom spacer
      Item { height: 4 }
    }
  }
}

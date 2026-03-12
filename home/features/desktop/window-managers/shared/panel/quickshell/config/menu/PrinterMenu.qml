import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  implicitWidth: 380
  implicitHeight: 480
  title: "Printers"
  toggleMethod: "togglePrinterMenu"
  contentSpacing: 12

  // Subscribe to PrinterService while this menu is alive
  SharedWidgets.Ref { service: PrinterService }

  // Refresh immediately when the menu becomes visible
  onVisibleChanged: {
    if (visible) PrinterService.refresh();
  }

  headerExtras: [
    // Active jobs chip — only shown when jobs are in flight
    Rectangle {
      visible: PrinterService.activeJobs > 0
      implicitWidth: jobsChipLabel.implicitWidth + 18
      implicitHeight: 24
      radius: 12
      color: Colors.withAlpha(Colors.warning, 0.16)

      Text {
        id: jobsChipLabel
        anchors.centerIn: parent
        text: PrinterService.activeJobs + " job" + (PrinterService.activeJobs !== 1 ? "s" : "")
        color: Colors.warning
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.DemiBold
      }
    },
    // Refresh button
    Rectangle {
      width: 30; height: 30; radius: height / 2
      color: "transparent"

      Text {
        anchors.centerIn: parent
        text: "󰑐"
        color: Colors.textSecondary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeLarge
      }

      SharedWidgets.StateLayer {
        id: refreshState
        anchors.fill: parent
        radius: parent.radius
        hovered: refreshHover.containsMouse
        pressed: refreshHover.pressed
      }

      MouseArea {
        id: refreshHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          refreshState.burst(mouse.x, mouse.y);
          PrinterService.refresh();
        }
      }
    }
  ]

  // ── STATUS CARD ────────────────────────────────────────────────────────
  Rectangle {
    visible: PrinterService.hasPrinters
    Layout.fillWidth: true
    implicitHeight: statusRow.implicitHeight + 16
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    RowLayout {
      id: statusRow
      anchors {
        left: parent.left; right: parent.right
        verticalCenter: parent.verticalCenter
        leftMargin: Colors.spacingM; rightMargin: Colors.spacingM
      }
      spacing: Colors.spacingM

      // Printer count
      ColumnLayout {
        spacing: 2
        Text {
          text: PrinterService.printers.length
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
          Layout.alignment: Qt.AlignHCenter
        }
        Text {
          text: "printer" + (PrinterService.printers.length !== 1 ? "s" : "")
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
          Layout.alignment: Qt.AlignHCenter
        }
      }

      // Divider
      Rectangle {
        width: 1; height: 28
        color: Colors.border
      }

      // Default printer info
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
          text: "Default"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
        }
        Text {
          text: PrinterService.defaultPrinter || "None set"
          color: PrinterService.defaultPrinter ? Colors.text : Colors.textDisabled
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }

      // Divider
      Rectangle {
        width: 1; height: 28
        color: Colors.border
        visible: PrinterService.activeJobs > 0
      }

      // Active jobs detail
      ColumnLayout {
        visible: PrinterService.activeJobs > 0
        spacing: 2
        Text {
          text: PrinterService.activeJobs
          color: Colors.warning
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
          Layout.alignment: Qt.AlignHCenter
        }
        Text {
          text: "active job" + (PrinterService.activeJobs !== 1 ? "s" : "")
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }
  }

  // ── PRINTER LIST ───────────────────────────────────────────────────────
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingS

        // Empty state — no printers detected
        SharedWidgets.EmptyState {
          Layout.fillWidth: true
          Layout.topMargin: 40
          visible: !PrinterService.hasPrinters
          icon: "󰐪"
          iconSize: 48
          message: "No printers configured"
        }

        // Section label
        SharedWidgets.SectionLabel { label: "PRINTERS"; visible: PrinterService.hasPrinters }

        // Per-printer cards
        Repeater {
          model: PrinterService.printers

          delegate: Rectangle {
            id: printerCard
            required property var modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: cardContent.implicitHeight + 20
            radius: Colors.radiusMedium

            readonly property bool isDefault: modelData.name === PrinterService.defaultPrinter
            readonly property bool isDisabled: modelData.status === "disabled"
            readonly property bool isPrinting: modelData.status === "printing"
            readonly property bool isHovered: cardHover.containsMouse

            color: isDefault ? Colors.withAlpha(Colors.primary, 0.08) : Colors.cardSurface

            border.color: isDefault ? Colors.withAlpha(Colors.primary, 0.4) : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }

            SharedWidgets.StateLayer {
              anchors.fill: parent
              radius: parent.radius
              stateColor: Colors.primary
              hovered: cardHover.containsMouse
              enableRipple: false
            }

            ColumnLayout {
              id: cardContent
              anchors {
                left: parent.left; right: parent.right
                top: parent.top
                margins: Colors.spacingM
              }
              spacing: Colors.spacingS

              // Top row: icon + name + status badge
              RowLayout {
                Layout.fillWidth: true
                spacing: Colors.paddingSmall

                // Printer icon
                Text {
                  text: "󰐪"
                  color: printerCard.isDisabled ? Colors.textDisabled
                       : printerCard.isPrinting ? Colors.warning
                       : Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeHuge
                  Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  // Printer name + default badge
                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                      text: modelData.name
                      color: printerCard.isDisabled ? Colors.textSecondary : Colors.text
                      font.pixelSize: Colors.fontSizeMedium
                      font.weight: Font.DemiBold
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    // Default badge
                    Rectangle {
                      visible: printerCard.isDefault
                      implicitWidth: defaultBadgeLabel.implicitWidth + 12
                      implicitHeight: 18
                      radius: height / 2
                      color: Colors.withAlpha(Colors.primary, 0.18)

                      Text {
                        id: defaultBadgeLabel
                        anchors.centerIn: parent
                        text: "Default"
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                      }
                    }
                  }

                  // Status text (truncated)
                  Text {
                    text: modelData.statusText
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }

                // Status indicator chip
                Rectangle {
                  implicitWidth: statusChipLabel.implicitWidth + 14
                  implicitHeight: 22
                  radius: 11
                  color: printerCard.isDisabled ? Colors.withAlpha(Colors.textDisabled, 0.12)
                       : printerCard.isPrinting ? Colors.withAlpha(Colors.warning, 0.16)
                       : Colors.withAlpha(Colors.success, 0.14)

                  Text {
                    id: statusChipLabel
                    anchors.centerIn: parent
                    text: modelData.status === "disabled" ? "Disabled"
                        : modelData.status === "printing" ? "Printing"
                        : "Idle"
                    color: printerCard.isDisabled ? Colors.textDisabled
                         : printerCard.isPrinting ? Colors.warning
                         : Colors.success
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Medium
                  }
                }
              }

              // Action buttons row
              RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                // Set Default button (hidden when already default)
                Rectangle {
                  visible: !printerCard.isDefault
                  implicitWidth: setDefaultLabel.implicitWidth + 16
                  implicitHeight: 26
                  radius: 13
                  color: Colors.highlightLight

                  Text {
                    id: setDefaultLabel
                    anchors.centerIn: parent
                    text: "Set Default"
                    color: setDefaultHover.containsMouse ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 160 } }
                  }

                  SharedWidgets.StateLayer {
                    id: setDefaultState
                    anchors.fill: parent
                    radius: parent.radius
                    stateColor: Colors.primary
                    hovered: setDefaultHover.containsMouse
                    pressed: setDefaultHover.pressed
                  }

                  MouseArea {
                    id: setDefaultHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                      setDefaultState.burst(mouse.x, mouse.y);
                      PrinterService.setDefault(modelData.name);
                    }
                  }
                }

                // Test Page button
                Rectangle {
                  visible: !printerCard.isDisabled
                  implicitWidth: testPageLabel.implicitWidth + 16
                  implicitHeight: 26
                  radius: 13
                  color: Colors.highlightLight

                  Text {
                    id: testPageLabel
                    anchors.centerIn: parent
                    text: "Test Page"
                    color: testPageHover.containsMouse ? Colors.accent : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 160 } }
                  }

                  SharedWidgets.StateLayer {
                    id: testPageState
                    anchors.fill: parent
                    radius: parent.radius
                    stateColor: Colors.accent
                    hovered: testPageHover.containsMouse
                    pressed: testPageHover.pressed
                  }

                  MouseArea {
                    id: testPageHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                      testPageState.burst(mouse.x, mouse.y);
                      PrinterService.printTestPage(modelData.name);
                    }
                  }
                }

                // Cancel All Jobs button (only when there are active jobs)
                Rectangle {
                  visible: PrinterService.activeJobs > 0 && !printerCard.isDisabled
                  implicitWidth: cancelJobsLabel.implicitWidth + 16
                  implicitHeight: 26
                  radius: 13
                  color: Colors.withAlpha(Colors.error, 0.10)

                  Text {
                    id: cancelJobsLabel
                    anchors.centerIn: parent
                    text: "Cancel Jobs"
                    color: cancelJobsHover.containsMouse ? Colors.error : Colors.withAlpha(Colors.error, 0.70)
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 160 } }
                  }

                  SharedWidgets.StateLayer {
                    id: cancelJobsState
                    anchors.fill: parent
                    radius: parent.radius
                    stateColor: Colors.error
                    hovered: cancelJobsHover.containsMouse
                    pressed: cancelJobsHover.pressed
                  }

                  MouseArea {
                    id: cancelJobsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                      cancelJobsState.burst(mouse.x, mouse.y);
                      PrinterService.cancelAllJobs(modelData.name);
                    }
                  }
                }

                Item { Layout.fillWidth: true }

                // Enable / Disable toggle
                Rectangle {
                  implicitWidth: toggleLabel.implicitWidth + 16
                  implicitHeight: 26
                  radius: 13
                  color: Colors.withAlpha(printerCard.isDisabled ? Colors.success : Colors.warning, 0.10)
                  Behavior on color { ColorAnimation { duration: 160 } }

                  Text {
                    id: toggleLabel
                    anchors.centerIn: parent
                    text: printerCard.isDisabled ? "Enable" : "Disable"
                    color: printerCard.isDisabled ? Colors.success : Colors.warning
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Medium
                  }

                  SharedWidgets.StateLayer {
                    id: toggleState
                    anchors.fill: parent
                    radius: parent.radius
                    stateColor: printerCard.isDisabled ? Colors.success : Colors.warning
                    hovered: toggleHover.containsMouse
                    pressed: toggleHover.pressed
                  }

                  MouseArea {
                    id: toggleHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                      toggleState.burst(mouse.x, mouse.y);
                      printerCard.isDisabled
                        ? PrinterService.enablePrinter(modelData.name)
                        : PrinterService.disablePrinter(modelData.name);
                    }
                  }
                }
              }
            }

            // Whole-card hover detection (no buttons consumed)
            MouseArea {
              id: cardHover
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
            }
          }
        }

    // Bottom spacer so the last card doesn't clip under scrollbar
    Item { implicitHeight: 4 }
  }
}

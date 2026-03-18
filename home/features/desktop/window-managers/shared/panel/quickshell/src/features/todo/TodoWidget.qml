import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

Item {
  id: root

  implicitWidth: 280
  implicitHeight: column.implicitHeight

  ColumnLayout {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top }
    spacing: Colors.spacingS

    // ── Add input ────────────────────────────────────────────────────
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 36
      radius: Colors.radiusSmall
      color: Colors.withAlpha(Colors.text, Colors.textFaint)
      border.color: inputField.activeFocus
        ? Colors.withAlpha(Colors.primary, Colors.primaryRing)
        : Colors.withAlpha(Colors.text, Colors.textThin)
      border.width: 1

      RowLayout {
        anchors { fill: parent; leftMargin: Colors.spacingM; rightMargin: Colors.spacingXS }
        spacing: Colors.spacingXS

        Text {
          text: ""
          color: inputField.activeFocus
            ? Colors.withAlpha(Colors.primary, 0.7)
            : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeSmall
        }

        TextInput {
          id: inputField
          Layout.fillWidth: true
          color: Colors.text
          font.pixelSize: Colors.fontSizeSmall
          selectionColor: Colors.withAlpha(Colors.primary, 0.35)
          clip: true
          placeholderText: "Add a task…"

          // placeholderText support via overlay text
          Text {
            anchors.fill: parent
            anchors.verticalCenter: undefined
            verticalAlignment: Text.AlignVCenter
            text: inputField.placeholderText
            color: Colors.textDisabled
            font: inputField.font
            visible: !inputField.text && !inputField.activeFocus
          }

          Keys.onReturnPressed: _commit()
          Keys.onEnterPressed: _commit()

          function _commit() {
            var text = inputField.text.trim();
            if (!text) return;
            TodoService.addTask(text);
            inputField.text = "";
          }
        }

        SharedWidgets.IconButton {
          icon: ""
          size: 28
          iconSize: Colors.fontSizeSmall
          iconColor: inputField.text.trim() ? Colors.primary : Colors.textDisabled
          stateColor: Colors.primary
          onClicked: inputField._commit()
        }
      }
    }

    // ── Empty state ──────────────────────────────────────────────────
    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: Colors.spacingL
      Layout.bottomMargin: Colors.spacingL
      Layout.alignment: Qt.AlignHCenter
      icon: "󰝦"
      message: "No tasks yet"
      visible: TodoService.totalCount === 0
    }

    // ── Task list ────────────────────────────────────────────────────
    ListView {
      id: taskList
      Layout.fillWidth: true
      implicitHeight: contentHeight
      interactive: false
      visible: TodoService.totalCount > 0

      // Pending first, then done
      model: {
        var all = TodoService.items;
        var pending = [];
        var done = [];
        for (var i = 0; i < all.length; i++) {
          if (all[i].done) done.push({ item: all[i], index: i });
          else pending.push({ item: all[i], index: i });
        }
        return pending.concat(done);
      }

      spacing: Colors.spacingXXS

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Colors.durationFast }
        NumberAnimation { property: "height"; from: 0; duration: Colors.durationFast; easing.type: Easing.OutQuad }
      }

      remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Colors.durationFast }
        NumberAnimation { property: "height"; to: 0; duration: Colors.durationFast; easing.type: Easing.InQuad }
      }

      displaced: Transition {
        Anim { property: "y"; duration: Colors.durationMedium }
      }

      delegate: Rectangle {
        id: row
        width: taskList.width
        implicitHeight: rowLayout.implicitHeight + Colors.spacingXS * 2
        radius: Colors.radiusXS
        color: rowHover.containsMouse
          ? Colors.withAlpha(Colors.text, Colors.textWash)
          : "transparent"

        readonly property var taskItem: modelData.item
        readonly property int taskIndex: modelData.index
        readonly property bool taskDone: taskItem.done

        Behavior on color {
          ColorAnimation { duration: Colors.durationSnap }
        }

        RowLayout {
          id: rowLayout
          anchors {
            fill: parent
            leftMargin: Colors.spacingXS
            rightMargin: Colors.spacingXXS
            topMargin: Colors.spacingXS
            bottomMargin: Colors.spacingXS
          }
          spacing: Colors.spacingXS

          // ── Checkbox ─────────────────────────────────────────────
          Rectangle {
            width: 18; height: 18
            radius: Colors.radiusXXS
            color: row.taskDone
              ? Colors.withAlpha(Colors.primary, Colors.primaryStrong)
              : "transparent"
            border.color: row.taskDone
              ? Colors.primary
              : Colors.withAlpha(Colors.text, 0.35)
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: Colors.durationSnap } }
            Behavior on border.color { ColorAnimation { duration: Colors.durationSnap } }

            Text {
              anchors.centerIn: parent
              text: ""
              color: Colors.primary
              font.family: Colors.fontMono
              font.pixelSize: 10
              opacity: row.taskDone ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: Colors.durationSnap } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: TodoService.toggleDone(row.taskIndex)
            }
          }

          // ── Task text ─────────────────────────────────────────────
          Text {
            Layout.fillWidth: true
            text: row.taskItem.content
            color: row.taskDone
              ? Colors.textDisabled
              : Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.strikeout: row.taskDone
            wrapMode: Text.WordWrap
            elide: Text.ElideNone

            Behavior on color { ColorAnimation { duration: Colors.durationSnap } }
          }

          // ── Delete button ─────────────────────────────────────────
          SharedWidgets.IconButton {
            icon: "󰅖"
            size: 24
            iconSize: Colors.fontSizeXS
            iconColor: Colors.textDisabled
            stateColor: Colors.error
            visible: rowHover.containsMouse
            onClicked: TodoService.deleteItem(row.taskIndex)
          }
        }

        MouseArea {
          id: rowHover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
        }
      }
    }

    // ── Footer: clear completed ──────────────────────────────────────
    RowLayout {
      Layout.fillWidth: true
      visible: TodoService.doneCount > 0
      spacing: Colors.spacingXS

      Text {
        text: TodoService.doneCount + " completed"
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeXS
      }

      Item { Layout.fillWidth: true }

      Rectangle {
        implicitWidth: clearLabel.implicitWidth + Colors.spacingM * 2
        implicitHeight: 24
        radius: Colors.radiusPill
        color: clearHover.containsMouse
          ? Colors.withAlpha(Colors.error, 0.15)
          : "transparent"
        border.color: clearHover.containsMouse
          ? Colors.withAlpha(Colors.error, 0.4)
          : Colors.withAlpha(Colors.text, Colors.textThin)
        border.width: 1

        Behavior on color { ColorAnimation { duration: Colors.durationSnap } }
        Behavior on border.color { ColorAnimation { duration: Colors.durationSnap } }

        Text {
          id: clearLabel
          anchors.centerIn: parent
          text: "Clear completed"
          color: clearHover.containsMouse ? Colors.error : Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS

          Behavior on color { ColorAnimation { duration: Colors.durationSnap } }
        }

        MouseArea {
          id: clearHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: TodoService.clearDone()
        }
      }
    }
  }
}

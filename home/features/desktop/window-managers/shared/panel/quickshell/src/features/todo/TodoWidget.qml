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
    spacing: Appearance.spacingS

    // ── Add input ────────────────────────────────────────────────────
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 36
      radius: Appearance.radiusSmall
      color: Colors.withAlpha(Colors.text, Colors.textFaint)
      border.color: inputField.activeFocus
        ? Colors.withAlpha(Colors.primary, Colors.primaryRing)
        : Colors.withAlpha(Colors.text, Colors.textThin)
      border.width: 1

      RowLayout {
        anchors { fill: parent; leftMargin: Appearance.spacingM; rightMargin: Appearance.spacingXS }
        spacing: Appearance.spacingXS

        Text {
          text: ""
          color: inputField.activeFocus
            ? Colors.withAlpha(Colors.primary, 0.7)
            : Colors.textDisabled
          font.family: Appearance.fontMono
          font.pixelSize: Appearance.fontSizeSmall
        }

        TextInput {
          id: inputField
          Layout.fillWidth: true
          color: Colors.text
          font.pixelSize: Appearance.fontSizeSmall
          selectionColor: Colors.withAlpha(Colors.primary, 0.35)
          clip: true
          property string placeholderText: "Add a task…"

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
          iconSize: Appearance.fontSizeSmall
          iconColor: inputField.text.trim() ? Colors.primary : Colors.textDisabled
          stateColor: Colors.primary
          tooltipText: "Add task"
          onClicked: inputField._commit()
        }
      }
    }

    // ── Empty state ──────────────────────────────────────────────────
    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: Appearance.spacingL
      Layout.bottomMargin: Appearance.spacingL
      Layout.alignment: Qt.AlignHCenter
      icon: "checkmark.svg"
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

      spacing: Appearance.spacingXXS

      add: ListTransitions.addFadeHeight
      remove: ListTransitions.removeFadeHeight
      displaced: ListTransitions.displaced

      delegate: Rectangle {
        id: row
        width: taskList.width
        implicitHeight: rowLayout.implicitHeight + Appearance.spacingXS * 2
        radius: Appearance.radiusXS
        color: rowHover.containsMouse
          ? Colors.withAlpha(Colors.text, Colors.textWash)
          : "transparent"

        readonly property var taskItem: modelData.item
        readonly property int taskIndex: modelData.index
        readonly property bool taskDone: taskItem.done

        Behavior on color {
          enabled: !Colors.isTransitioning
          ColorAnimation { duration: Appearance.durationSnap }
        }

        RowLayout {
          id: rowLayout
          anchors {
            fill: parent
            leftMargin: Appearance.spacingXS
            rightMargin: Appearance.spacingXXS
            topMargin: Appearance.spacingXS
            bottomMargin: Appearance.spacingXS
          }
          spacing: Appearance.spacingXS

          // ── Checkbox ─────────────────────────────────────────────
          Rectangle {
            width: 18; height: 18
            radius: Appearance.radiusXXS
            color: row.taskDone
              ? Colors.withAlpha(Colors.primary, Colors.primaryStrong)
              : "transparent"
            border.color: row.taskDone
              ? Colors.primary
              : Colors.withAlpha(Colors.text, 0.35)
            border.width: 1.5

            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }
            Behavior on border.color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }

            Text {
              anchors.centerIn: parent
              text: ""
              color: Colors.primary
              font.family: Appearance.fontMono
              font.pixelSize: Appearance.fontSizeCaption
              opacity: row.taskDone ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: Appearance.durationSnap } }
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
            font.pixelSize: Appearance.fontSizeSmall
            font.strikeout: row.taskDone
            wrapMode: Text.WordWrap
            elide: Text.ElideNone

            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }
          }

          // ── Delete button ─────────────────────────────────────────
          SharedWidgets.IconButton {
            icon: "dismiss.svg"
            size: Appearance.iconSizeSmall
            iconSize: Appearance.fontSizeXS
            iconColor: Colors.textDisabled
            stateColor: Colors.error
            tooltipText: "Delete task"
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
      spacing: Appearance.spacingXS

      Text {
        text: TodoService.doneCount + " completed"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
      }

      Item { Layout.fillWidth: true }

      Rectangle {
        implicitWidth: clearLabel.implicitWidth + Appearance.spacingM * 2
        implicitHeight: 24
        radius: Appearance.radiusPill
        color: clearHover.containsMouse
          ? Colors.withAlpha(Colors.error, 0.15)
          : "transparent"
        border.color: clearHover.containsMouse
          ? Colors.withAlpha(Colors.error, 0.4)
          : Colors.withAlpha(Colors.text, Colors.textThin)
        border.width: 1

        Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }
        Behavior on border.color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }

        Text {
          id: clearLabel
          anchors.centerIn: parent
          text: "Clear completed"
          color: clearHover.containsMouse ? Colors.error : Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS

          Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }
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

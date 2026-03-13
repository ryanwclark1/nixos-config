import Quickshell
import QtQuick
import "./menu"

ShellRoot {
  BatteryMenu { wantVisible: true }
  ClipboardMenu { wantVisible: true }
  MusicMenu { wantVisible: true }
  SystemStatsMenu { wantVisible: true }
  PrivacyMenu { wantVisible: true }
  RecordingMenu { wantVisible: true }
  CavaPopup { visible: true; cavaData: "▁▂▃▄▅▆▇█" }
}

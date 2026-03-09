import QtQuick
import Quickshell

PanelWindow {
  width: 100; height: 100
  color: "transparent"
  Component.onCompleted: {
    console.log("nix-snowflake:", Quickshell.iconPath("nix-snowflake"));
    console.log("nixos:", Quickshell.iconPath("nixos"));
    console.log("nix-snowflake-white:", Quickshell.iconPath("nix-snowflake-white"));
    Qt.quit();
  }
}

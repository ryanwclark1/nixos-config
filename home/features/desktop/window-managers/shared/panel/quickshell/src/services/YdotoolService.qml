pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // 0 = off, 1 = shift (one-shot), 2 = caps lock
    property int shiftMode: 0

    // Left Shift and Right Shift Linux keycodes
    property list<int> shiftKeys: [42, 54]

    // Send key-down event for a single keycode
    function press(keycode) {
        Quickshell.execDetached([
            "ydotool", "key", "--key-delay", "0",
            keycode + ":1"
        ]);
    }

    // Send key-up event for a single keycode
    function release(keycode) {
        Quickshell.execDetached([
            "ydotool", "key", "--key-delay", "0",
            keycode + ":0"
        ]);
    }

    // Release both shift keys and reset shiftMode to 0
    function releaseShiftKeys() {
        var args = ["ydotool", "key", "--key-delay", "0"];
        for (var i = 0; i < root.shiftKeys.length; i++)
            args.push(root.shiftKeys[i] + ":0");
        Quickshell.execDetached(args);
        root.shiftMode = 0;
    }

    // Release every possible key (keycodes 0–248) and reset shift state
    function releaseAllKeys() {
        var args = ["ydotool", "key", "--key-delay", "0"];
        for (var k = 0; k < 249; k++)
            args.push(k + ":0");
        Quickshell.execDetached(args);
        root.shiftMode = 0;
    }
}

pragma Singleton

import QtQuick
import "."

QtObject {
    id: root

    // Level constants
    readonly property int _LEVEL_DEBUG: 0
    readonly property int _LEVEL_INFO: 1
    readonly property int _LEVEL_WARN: 2
    readonly property int _LEVEL_ERROR: 3

    // Current minimum log level — debug only when Config.debug is true
    // NOTE: Config may not have a `debug` property yet, so check safely
    readonly property int _minLevel: {
        try { return Config.debug ? _LEVEL_DEBUG : _LEVEL_INFO; }
        catch(e) { return _LEVEL_INFO; }
    }

    // Format: [LEVEL][module] message args...
    function _fmt(levelTag, module, args) {
        var parts = ["[" + levelTag + "][" + module + "]"];
        for (var i = 0; i < args.length; i++)
            parts.push(String(args[i]));
        return parts.join(" ");
    }

    // Debug — gated on Config.debug
    function d(module) {
        if (_minLevel > _LEVEL_DEBUG) return;
        var args = Array.prototype.slice.call(arguments, 1);
        console.log(_fmt("D", module, args));
    }

    // Info
    function i(module) {
        if (_minLevel > _LEVEL_INFO) return;
        var args = Array.prototype.slice.call(arguments, 1);
        console.info(_fmt("I", module, args));
    }

    // Warning
    function w(module) {
        var args = Array.prototype.slice.call(arguments, 1);
        console.warn(_fmt("W", module, args));
    }

    // Error
    function e(module) {
        var args = Array.prototype.slice.call(arguments, 1);
        console.error(_fmt("E", module, args));
    }

    // Performance timing — returns a function that logs elapsed ms when called
    function perf(module, label) {
        var start = Date.now();
        return function() {
            var elapsed = Date.now() - start;
            console.log(_fmt("P", module, [label, elapsed + "ms"]));
        };
    }
}

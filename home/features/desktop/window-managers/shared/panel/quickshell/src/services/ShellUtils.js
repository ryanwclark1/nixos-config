.pragma library

// POSIX single-quote escaping: end quote, literal quote, reopen quote
function shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
}

// Build command array to launch `cmd` in the first available terminal emulator.
// Extra positional args are forwarded and available as $1, $2, etc. inside
// the cmd script (the outer shell shifts $1 to use as the -c argument).
// Usage: Quickshell.execDetached(SU.terminalCommand(cmd))
// Usage: Quickshell.execDetached(SU.terminalCommand("exec ssh \"$1\"", alias))
function terminalCommand(cmd) {
    var extraArgs = [];
    for (var i = 1; i < arguments.length; ++i)
        extraArgs.push(String(arguments[i]));

    if (extraArgs.length === 0) {
        return ["sh", "-c",
            "for t in ghostty kitty foot alacritty wezterm; do " +
            "if command -v $t >/dev/null 2>&1; then exec $t -e bash -lc \"$1\"; fi; done",
            "sh", cmd];
    }

    // With extra args: pass them through via $2..$N so the inner bash -lc script can use $1..$M
    // Outer shell: $1=cmd, $2..=extra args
    // Inner bash -lc "$1" bash "$2" "$3" ...
    var innerArgRefs = "";
    for (var j = 0; j < extraArgs.length; ++j)
        innerArgRefs += " \"$" + (j + 2) + "\"";
    var result = ["sh", "-c",
        "for t in ghostty kitty foot alacritty wezterm; do " +
        "if command -v $t >/dev/null 2>&1; then exec $t -e bash -lc \"$1\" bash" + innerArgRefs + "; fi; done",
        "sh", cmd];
    for (var k = 0; k < extraArgs.length; ++k)
        result.push(extraArgs[k]);
    return result;
}

// argv for: quickshell ipc call <target> <method> [extra args...]
// Usage: Quickshell.execDetached(SU.ipcCall("Shell", "openSurface", "controlCenter"));
function ipcCall(target, method) {
    var cmd = ["quickshell", "ipc", "call", String(target || ""), String(method || "")];
    for (var i = 2; i < arguments.length; ++i)
        cmd.push(String(arguments[i]));
    return cmd;
}

// argv for fixed-arity Shell surface IPC:
//   quickshell ipc call Shell <method> <surfaceId> <screenName>
// screenName defaults to "" to match the live Shell IPC contract.
function shellSurfaceCall(method, surfaceId, screenName) {
    var resolvedScreen = screenName;
    if (resolvedScreen === undefined || resolvedScreen === null)
        resolvedScreen = "";
    return ipcCall("Shell", method, surfaceId, resolvedScreen);
}

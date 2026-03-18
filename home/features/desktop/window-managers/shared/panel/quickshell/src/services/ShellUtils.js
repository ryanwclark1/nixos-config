.pragma library

// POSIX single-quote escaping: end quote, literal quote, reopen quote
function shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
}

// Build command array to launch `cmd` in the first available terminal emulator.
// Usage: Quickshell.execDetached(SU.terminalCommand(cmd))
function terminalCommand(cmd) {
    return ["sh", "-c",
        "for t in ghostty kitty foot alacritty wezterm; do " +
        "if command -v $t >/dev/null 2>&1; then exec $t -e bash -lc \"$1\"; fi; done",
        "sh", cmd];
}

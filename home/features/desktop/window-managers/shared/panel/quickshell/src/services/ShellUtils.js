.pragma library

// POSIX single-quote escaping: end quote, literal quote, reopen quote
function shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
}

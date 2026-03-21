.pragma library

// Thumbnail resolution for wallpaper grids: Freedesktop cache paths (read-only)
// plus deterministic Quickshell disk cache keys (path + mtime), shared with qs-wallpaper-thumb.sh.
// MD5 core matches the `md5` npm package (crypt word layout + endian swap).

/** UTF-8 encode string to byte array for MD5 input. */
function _utf8Bytes(str) {
  var out = [];
  for (var i = 0; i < str.length; i++) {
    var c = str.charCodeAt(i);
    if (c < 0x80) {
      out.push(c);
    } else if (c < 0x800) {
      out.push(0xc0 | (c >> 6), 0x80 | (c & 0x3f));
    } else if (c < 0xd800 || c >= 0xe000) {
      out.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
    } else {
      i++;
      c = 0x10000 + (((c & 0x3ff) << 10) | (str.charCodeAt(i) & 0x3ff));
      out.push(
        0xf0 | (c >> 18),
        0x80 | ((c >> 12) & 0x3f),
        0x80 | ((c >> 6) & 0x3f),
        0x80 | (c & 0x3f)
      );
    }
  }
  return out;
}

function _bytesToWords(bytes) {
  var words = [];
  for (var i = 0, b = 0; i < bytes.length; i++, b += 8)
    words[b >>> 5] |= bytes[i] << (24 - (b % 32));
  return words;
}

function _endianSwapWord(n) {
  return (((n << 8) | (n >>> 24)) & 0x00ff00ff) | (((n << 24) | (n >>> 8)) & 0xff00ff00);
}

function _wordsToBytes(words) {
  var bytes = [];
  for (var b = 0; b < words.length * 32; b += 8)
    bytes.push((words[b >>> 5] >>> (24 - (b % 32))) & 0xff);
  return bytes;
}

function _bytesToHex(bytes) {
  var hex = [];
  for (var i = 0; i < bytes.length; i++) {
    hex.push((bytes[i] >>> 4).toString(16));
    hex.push((bytes[i] & 0xf).toString(16));
  }
  return hex.join("");
}

function _md5Ff(a, b, c, d, x, s, t) {
  var n = a + ((b & c) | (~b & d)) + (x >>> 0) + t;
  return ((n << s) | (n >>> (32 - s))) + b;
}

function _md5Gg(a, b, c, d, x, s, t) {
  var n = a + ((b & d) | (c & ~d)) + (x >>> 0) + t;
  return ((n << s) | (n >>> (32 - s))) + b;
}

function _md5Hh(a, b, c, d, x, s, t) {
  var n = a + (b ^ c ^ d) + (x >>> 0) + t;
  return ((n << s) | (n >>> (32 - s))) + b;
}

function _md5Ii(a, b, c, d, x, s, t) {
  var n = a + (c ^ (b | ~d)) + (x >>> 0) + t;
  return ((n << s) | (n >>> (32 - s))) + b;
}

/** MD5 hex digest of a JavaScript string (UTF-8). */
function md5Hex(str) {
  var message = _utf8Bytes(String(str));
  var m = _bytesToWords(message.slice());
  var l = message.length * 8;
  var i;
  for (i = 0; i < m.length; i++)
    m[i] = _endianSwapWord(m[i]);
  m[l >>> 5] |= 0x80 << (l % 32);
  m[(((l + 64) >>> 9) << 4) + 14] = l;

  var a = 1732584193;
  var b = -271733879;
  var c = -1732584194;
  var d = 271733878;

  for (i = 0; i < m.length; i += 16) {
    var aa = a;
    var bb = b;
    var cc = c;
    var dd = d;

    a = _md5Ff(a, b, c, d, m[i + 0], 7, -680876936);
    d = _md5Ff(d, a, b, c, m[i + 1], 12, -389564586);
    c = _md5Ff(c, d, a, b, m[i + 2], 17, 606105819);
    b = _md5Ff(b, c, d, a, m[i + 3], 22, -1044525330);
    a = _md5Ff(a, b, c, d, m[i + 4], 7, -176418897);
    d = _md5Ff(d, a, b, c, m[i + 5], 12, 1200080426);
    c = _md5Ff(c, d, a, b, m[i + 6], 17, -1473231341);
    b = _md5Ff(b, c, d, a, m[i + 7], 22, -45705983);
    a = _md5Ff(a, b, c, d, m[i + 8], 7, 1770035416);
    d = _md5Ff(d, a, b, c, m[i + 9], 12, -1958414417);
    c = _md5Ff(c, d, a, b, m[i + 10], 17, -42063);
    b = _md5Ff(b, c, d, a, m[i + 11], 22, -1990404162);
    a = _md5Ff(a, b, c, d, m[i + 12], 7, 1804603682);
    d = _md5Ff(d, a, b, c, m[i + 13], 12, -40341101);
    c = _md5Ff(c, d, a, b, m[i + 14], 17, -1502002290);
    b = _md5Ff(b, c, d, a, m[i + 15], 22, 1236535329);

    a = _md5Gg(a, b, c, d, m[i + 1], 5, -165796510);
    d = _md5Gg(d, a, b, c, m[i + 6], 9, -1069501632);
    c = _md5Gg(c, d, a, b, m[i + 11], 14, 643717713);
    b = _md5Gg(b, c, d, a, m[i + 0], 20, -373897302);
    a = _md5Gg(a, b, c, d, m[i + 5], 5, -701558691);
    d = _md5Gg(d, a, b, c, m[i + 10], 9, 38016083);
    c = _md5Gg(c, d, a, b, m[i + 15], 14, -660478335);
    b = _md5Gg(b, c, d, a, m[i + 4], 20, -405537848);
    a = _md5Gg(a, b, c, d, m[i + 9], 5, 568446438);
    d = _md5Gg(d, a, b, c, m[i + 14], 9, -1019803690);
    c = _md5Gg(c, d, a, b, m[i + 3], 14, -187363961);
    b = _md5Gg(b, c, d, a, m[i + 8], 20, 1163531501);
    a = _md5Gg(a, b, c, d, m[i + 13], 5, -1444681467);
    d = _md5Gg(d, a, b, c, m[i + 2], 9, -51403784);
    c = _md5Gg(c, d, a, b, m[i + 7], 14, 1735328473);
    b = _md5Gg(b, c, d, a, m[i + 12], 20, -1926607734);

    a = _md5Hh(a, b, c, d, m[i + 5], 4, -378558);
    d = _md5Hh(d, a, b, c, m[i + 8], 11, -2022574463);
    c = _md5Hh(c, d, a, b, m[i + 11], 16, 1839030562);
    b = _md5Hh(b, c, d, a, m[i + 14], 23, -35309556);
    a = _md5Hh(a, b, c, d, m[i + 1], 4, -1530992060);
    d = _md5Hh(d, a, b, c, m[i + 4], 11, 1272893353);
    c = _md5Hh(c, d, a, b, m[i + 7], 16, -155497632);
    b = _md5Hh(b, c, d, a, m[i + 10], 23, -1094730640);
    a = _md5Hh(a, b, c, d, m[i + 13], 4, 681279174);
    d = _md5Hh(d, a, b, c, m[i + 0], 11, -358537222);
    c = _md5Hh(c, d, a, b, m[i + 3], 16, -722521979);
    b = _md5Hh(b, c, d, a, m[i + 6], 23, 76029189);
    a = _md5Hh(a, b, c, d, m[i + 9], 4, -640364487);
    d = _md5Hh(d, a, b, c, m[i + 12], 11, -421815835);
    c = _md5Hh(c, d, a, b, m[i + 15], 16, 530742520);
    b = _md5Hh(b, c, d, a, m[i + 2], 23, -995338651);

    a = _md5Ii(a, b, c, d, m[i + 0], 6, -198630844);
    d = _md5Ii(d, a, b, c, m[i + 7], 10, 1126891415);
    c = _md5Ii(c, d, a, b, m[i + 14], 15, -1416354905);
    b = _md5Ii(b, c, d, a, m[i + 5], 21, -57434055);
    a = _md5Ii(a, b, c, d, m[i + 12], 6, 1700485571);
    d = _md5Ii(d, a, b, c, m[i + 3], 10, -1894986606);
    c = _md5Ii(c, d, a, b, m[i + 10], 15, -1051523);
    b = _md5Ii(b, c, d, a, m[i + 1], 21, -2054922799);
    a = _md5Ii(a, b, c, d, m[i + 8], 6, 1873313359);
    d = _md5Ii(d, a, b, c, m[i + 15], 10, -30611744);
    c = _md5Ii(c, d, a, b, m[i + 6], 15, -1560198380);
    b = _md5Ii(b, c, d, a, m[i + 13], 21, 1309151649);
    a = _md5Ii(a, b, c, d, m[i + 4], 6, -145523070);
    d = _md5Ii(d, a, b, c, m[i + 11], 10, -1120210379);
    c = _md5Ii(c, d, a, b, m[i + 2], 15, 718787259);
    b = _md5Ii(b, c, d, a, m[i + 9], 21, -343485551);

    a = (a + aa) >>> 0;
    b = (b + bb) >>> 0;
    c = (c + cc) >>> 0;
    d = (d + dd) >>> 0;
  }

  var outWords = [_endianSwapWord(a), _endianSwapWord(b), _endianSwapWord(c), _endianSwapWord(d)];
  return _bytesToHex(_wordsToBytes(outWords));
}

/**
 * file:// URI with percent-encoded path segments (Freedesktop thumbnail key input).
 */
function canonicalFileUri(absolutePath) {
  var p = String(absolutePath || "");
  if (!p.length) return "";
  var norm = p.replace(/\\/g, "/");
  if (norm.charAt(0) !== "/") norm = "/" + norm;
  var parts = norm.split("/");
  var tail = [];
  for (var i = 0; i < parts.length; i++) {
    if (i === 0 && parts[i] === "") continue;
    tail.push(encodeURIComponent(parts[i]));
  }
  return "file://" + (norm.charAt(0) === "/" ? "/" : "") + tail.join("/");
}

function _thumbnailCacheDir(xdgCacheHome, home) {
  var h = String(home || "/home");
  var base = String(xdgCacheHome || "").trim();
  if (!base.length) base = h + "/.cache";
  return base;
}

/** file:// URL for ~/.cache/thumbnails/large/<md5>.png */
function freedesktopLargeFileUrl(absolutePath, xdgCacheHome, home) {
  if (!absolutePath) return "";
  var uri = canonicalFileUri(absolutePath);
  if (!uri.length) return "";
  var dir = _thumbnailCacheDir(xdgCacheHome, home) + "/thumbnails/large/";
  return "file://" + dir + md5Hex(uri) + ".png";
}

/** Stable cache key for Quickshell-generated WebP (must match wallpaper-thumb.sh). */
function quickshellThumbKey(absolutePath, mtime) {
  return md5Hex(String(absolutePath || "") + "\n" + String(mtime | 0));
}

/** Absolute filesystem path for Quickshell thumbnail (no file://). */
function quickshellThumbAbsolutePath(absolutePath, mtime, xdgCacheHome, home) {
  var key = quickshellThumbKey(absolutePath, mtime);
  if (!key.length) return "";
  return _thumbnailCacheDir(xdgCacheHome, home) + "/quickshell-wallpaper-thumbs/" + key + ".webp";
}

/** file:// URL for Quickshell cache entry (optional cache-bust query applied in QML). */
function quickshellThumbFileUrl(absolutePath, mtime, xdgCacheHome, home) {
  var fsPath = quickshellThumbAbsolutePath(absolutePath, mtime, xdgCacheHome, home);
  if (!fsPath.length) return "";
  return "file://" + fsPath;
}

.pragma library

// Shared HSV/RGB conversion utilities.
// Convention: H 0-360, S 0-1, V 0-1, RGB 0-255.

function hsvToRgb(h, s, v) {
    var hh = ((h % 360) + 360) % 360;
    var ss = Math.max(0, Math.min(1, s));
    var vv = Math.max(0, Math.min(1, v));
    var c = vv * ss;
    var x = c * (1 - Math.abs((hh / 60) % 2 - 1));
    var m = vv - c;
    var rp = 0, gp = 0, bp = 0;
    if (hh < 60)       { rp = c; gp = x; bp = 0; }
    else if (hh < 120) { rp = x; gp = c; bp = 0; }
    else if (hh < 180) { rp = 0; gp = c; bp = x; }
    else if (hh < 240) { rp = 0; gp = x; bp = c; }
    else if (hh < 300) { rp = x; gp = 0; bp = c; }
    else               { rp = c; gp = 0; bp = x; }
    return {
        r: Math.round((rp + m) * 255),
        g: Math.round((gp + m) * 255),
        b: Math.round((bp + m) * 255)
    };
}

function rgbToHsv(r, g, b) {
    var rr = Math.max(0, Math.min(255, r)) / 255;
    var gg = Math.max(0, Math.min(255, g)) / 255;
    var bb = Math.max(0, Math.min(255, b)) / 255;
    var maxv = Math.max(rr, gg, bb);
    var minv = Math.min(rr, gg, bb);
    var d = maxv - minv;
    var h = 0;
    if (d !== 0) {
        if (maxv === rr)      h = 60 * (((gg - bb) / d) % 6);
        else if (maxv === gg) h = 60 * (((bb - rr) / d) + 2);
        else                  h = 60 * (((rr - gg) / d) + 4);
    }
    if (h < 0) h += 360;
    var s = maxv === 0 ? 0 : d / maxv;
    var v = maxv;
    return { h: h, s: s, v: v };
}

function hex2(v) {
    var n = Math.max(0, Math.min(255, Math.round(v)));
    var s = n.toString(16);
    return s.length < 2 ? "0" + s : s;
}

.pragma library

function isBinaryData(content) {
    return String(content || "").indexOf("[[ binary data") !== -1;
}

function isImageContent(content) {
    var raw = String(content || "").toLowerCase();
    if (raw.indexOf("[[ binary data") === -1)
        return false;
    return raw.indexOf("png") !== -1
        || raw.indexOf("jpg") !== -1
        || raw.indexOf("jpeg") !== -1
        || raw.indexOf("bmp") !== -1
        || raw.indexOf("webp") !== -1
        || raw.indexOf("gif") !== -1;
}

function binarySummary(content) {
    var raw = String(content || "");
    var match = raw.match(/\[\[ binary data (.+?) \]\]/);
    return match ? match[1] : "Binary data";
}

function displayText(content) {
    var raw = String(content || "");
    if (raw === "")
        return "";
    if (isBinaryData(raw))
        return binarySummary(raw);
    return raw;
}

function launcherItem(entry) {
    var source = entry || {};
    var content = String(source.content || "");
    var image = isImageContent(content);
    var display = displayText(content);
    return {
        id: source.id,
        content: content,
        name: display,
        title: display,
        description: image ? "Clipboard image" : "",
        body: content,
        icon: image ? "image.svg" : "copy.svg",
        clipIsImage: image
    };
}

.pragma library

// Mutates anchorRect (e.g. PopupWindow.anchor.rect) to place a popup beside a bar edge.
// triggerRect: { x, y, width, height } — missing fields treated as 0.
// edge: "left" | "right" | "top" | "bottom" (top/bottom are horizontal-bar edges).
function assignPopupAnchor(anchorRect, triggerRect, edge, gap, popupWidth, popupHeight) {
    var tx = triggerRect.x || 0;
    var ty = triggerRect.y || 0;
    var tw = triggerRect.width || 0;
    var th = triggerRect.height || 0;
    if (edge === "left" || edge === "right") {
        anchorRect.y = ty + th / 2 - popupHeight / 2;
        anchorRect.x = edge === "left" ? tx + tw + gap : tx - popupWidth - gap;
    } else {
        anchorRect.x = tx + tw / 2 - popupWidth / 2;
        anchorRect.y = edge === "bottom" ? ty - popupHeight - gap : ty + th + gap;
    }
}

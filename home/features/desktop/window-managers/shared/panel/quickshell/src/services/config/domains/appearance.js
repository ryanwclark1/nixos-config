.pragma library

function _strDef(v) { return String(v || ""); }
function _num1(v) { return Number(v) || 1.0; }

var sectionKey = "appearance"

var maps = [
    ["fontFamily", "fontFamily", _strDef],
    ["monoFontFamily", "monoFontFamily", _strDef],
    ["fontScale", "fontScale", _num1],
    ["radiusScale", "radiusScale", _num1],
    ["spacingScale", "spacingScale", _num1],
    ["uiDensityScale", "uiDensityScale", _num1],
    ["animationSpeedScale", "animationSpeedScale", _num1],
    ["autoEcoMode", "autoEcoMode"],
    ["personalityGifEnabled", "personalityGifEnabled"],
    ["personalityGifPath", "personalityGifPath", _strDef],
    ["personalityGifReactionMode", "personalityGifReactionMode", _strDef]
]

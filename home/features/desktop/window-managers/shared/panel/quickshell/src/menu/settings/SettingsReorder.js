.pragma library

function clampIndex(index, count) {
    var upperBound = Math.max(0, Number(count) || 0);
    var value = Math.round(Number(index) || 0);
    if (value < 0)
        return 0;
    if (value > upperBound)
        return upperBound;
    return value;
}

function rowExtent(itemExtent, spacing) {
    return Math.max(1, Math.round(Number(itemExtent) || 0) + Math.round(Number(spacing) || 0));
}

function targetIndexFromMappedY(mappedY, itemExtent, spacing, count) {
    var extent = rowExtent(itemExtent, spacing);
    return clampIndex(Math.round((Number(mappedY) || 0) / extent), count);
}

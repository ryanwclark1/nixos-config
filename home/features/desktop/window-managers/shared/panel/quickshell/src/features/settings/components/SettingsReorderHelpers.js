.pragma library

function clampIndex(index, maxValue) {
    var bounded = Math.max(0, Math.min(Math.max(0, Number(maxValue) || 0), Math.round(Number(index) || 0)));
    return bounded;
}

function beginState(state, listId, itemId, index) {
    if (!state)
        return;
    state.sourceListId = String(listId || "");
    state.sourceItemId = String(itemId || "");
    state.sourceIndex = Math.max(-1, Math.round(Number(index) || -1));
    state.targetListId = state.sourceListId;
    state.targetIndex = state.sourceIndex;
}

function updateTarget(state, listId, index) {
    if (!state)
        return;
    state.targetListId = String(listId || "");
    state.targetIndex = Math.max(-1, Math.round(Number(index) || -1));
}

function clearState(state) {
    if (!state)
        return;
    state.sourceListId = "";
    state.sourceItemId = "";
    state.sourceIndex = -1;
    state.targetListId = "";
    state.targetIndex = -1;
}

function targetIndexFromMappedY(mappedY, itemExtent, spacing, count) {
    var extent = Math.max(1, Math.round(Number(itemExtent) || 0) + Math.round(Number(spacing) || 0));
    var upperBound = Math.max(0, Number(count) || 0);
    var value = Math.round((Number(mappedY) || 0) / extent);
    if (value < 0)
        return 0;
    if (value > upperBound)
        return upperBound;
    return value;
}

function mappedListY(cardItem, listItem, dragOffsetY) {
    if (!cardItem || !listItem)
        return 0;
    return cardItem.mapToItem(listItem, 0, cardItem.y + (Number(dragOffsetY) || 0)).y;
}

function currentListDropIndex(cardItem, rowIndex, listItem, count, dragOffsetY) {
    if (!cardItem || !listItem)
        return rowIndex;
    return targetIndexFromMappedY(mappedListY(cardItem, listItem, dragOffsetY), cardItem.height, listItem.spacing, count);
}

function normalizedTargetIndex(fromIndex, targetIndex, listLength) {
    var boundedTarget = clampIndex(targetIndex, Math.max(0, Number(listLength) || 0));
    if (fromIndex < boundedTarget)
        boundedTarget -= 1;
    return Math.max(0, boundedTarget);
}

function moveArrayItem(list, fromIndex, targetIndex) {
    var next = Array.isArray(list) ? list.slice() : [];
    if (fromIndex < 0 || fromIndex >= next.length)
        return { changed: false, items: next };

    var insertionIndex = normalizedTargetIndex(fromIndex, targetIndex, next.length);
    if (insertionIndex === fromIndex)
        return { changed: false, items: next };

    var moved = next.splice(fromIndex, 1)[0];
    next.splice(insertionIndex, 0, moved);
    return { changed: true, items: next, targetIndex: insertionIndex };
}

function moveValueToTarget(list, value, targetIndex) {
    var next = Array.isArray(list) ? list.slice() : [];
    var fromIndex = next.indexOf(value);
    if (fromIndex < 0)
        return { changed: false, items: next };
    return moveArrayItem(next, fromIndex, targetIndex);
}

function moveValueByDelta(list, value, delta) {
    var next = Array.isArray(list) ? list.slice() : [];
    var fromIndex = next.indexOf(value);
    if (fromIndex < 0)
        return { changed: false, items: next };
    var targetIndex = Math.max(0, Math.min(next.length - 1, fromIndex + Math.round(Number(delta) || 0)));
    if (targetIndex === fromIndex)
        return { changed: false, items: next };
    var moved = next.splice(fromIndex, 1)[0];
    next.splice(targetIndex, 0, moved);
    return { changed: true, items: next, targetIndex: targetIndex };
}

function orderCatalogItems(catalog, explicitOrder, idAccessor) {
    var source = Array.isArray(catalog) ? catalog : [];
    var order = Array.isArray(explicitOrder) ? explicitOrder : [];
    var extractId = typeof idAccessor === "function" ? idAccessor : function(item) {
        return String(item && item.id !== undefined ? item.id : "");
    };
    var byId = ({});
    var seen = ({});
    var out = [];
    var i;

    for (i = 0; i < source.length; ++i) {
        var itemId = String(extractId(source[i]) || "");
        if (itemId === "")
            continue;
        byId[itemId] = source[i];
    }

    for (i = 0; i < order.length; ++i) {
        var orderedId = String(order[i] || "");
        if (!byId[orderedId] || seen[orderedId])
            continue;
        seen[orderedId] = true;
        out.push(byId[orderedId]);
    }

    for (i = 0; i < source.length; ++i) {
        var fallbackId = String(extractId(source[i]) || "");
        if (fallbackId === "" || seen[fallbackId])
            continue;
        seen[fallbackId] = true;
        out.push(source[i]);
    }

    return out;
}

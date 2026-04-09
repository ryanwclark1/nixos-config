.pragma library

var ENTRY_TTL_MS = 5 * 60 * 1000;

function normalizeAddress(address) {
    return String(address || "").trim().toUpperCase();
}

function normalizeUuid(uuid) {
    return String(uuid || "").trim().toUpperCase();
}

function preferredName(device) {
    if (!device)
        return "";
    var name = String(device.displayName || device.name || device.alias || "").trim();
    if (name.length > 0)
        return name;
    return normalizeAddress(device.address);
}

function metadataFromDevice(device) {
    var manufacturerIds = [];
    if (Array.isArray(device.manufacturerIds))
        manufacturerIds = device.manufacturerIds.slice();
    else if (device.manufacturerId !== undefined && device.manufacturerId !== null)
        manufacturerIds = [device.manufacturerId];
    var serviceUuids = Array.isArray(device.serviceUuids) ? device.serviceUuids.slice() : [];
    return {
        manufacturerIds: manufacturerIds,
        serviceUuids: serviceUuids,
        appearance: device.appearance !== undefined && device.appearance !== null ? Number(device.appearance) : -1,
        rssi: device.rssi !== undefined && device.rssi !== null ? Number(device.rssi) : NaN,
        addressType: String(device.addressType || ""),
        source: String(device.source || "")
    };
}

function mergeEntry(existing, device, now, metadataSource) {
    var base = existing ? Object.assign({}, existing) : {};
    var address = normalizeAddress(device && device.address || base.address);
    var incomingMeta = metadataFromDevice(device || {});
    var source = String(metadataSource || incomingMeta.source || base.metadataSource || "");
    var next = Object.assign({}, base, {
        address: address,
        name: String(device && device.name || base.name || ""),
        alias: String(device && device.alias || base.alias || ""),
        displayName: preferredName(device || base),
        connected: !!(device && device.connected),
        paired: !!(device && device.paired),
        trusted: device && device.trusted !== undefined ? !!device.trusted : !!base.trusted,
        blocked: device && device.blocked !== undefined ? !!device.blocked : !!base.blocked,
        lastSeenMs: now,
        isLive: true,
        manufacturerIds: incomingMeta.manufacturerIds.length > 0 ? incomingMeta.manufacturerIds : (base.manufacturerIds || []),
        serviceUuids: incomingMeta.serviceUuids.length > 0 ? incomingMeta.serviceUuids : (base.serviceUuids || []),
        appearance: incomingMeta.appearance >= 0 ? incomingMeta.appearance : (base.appearance !== undefined ? base.appearance : -1),
        rssi: isFinite(incomingMeta.rssi) ? incomingMeta.rssi : base.rssi,
        addressType: incomingMeta.addressType || base.addressType || "",
        metadataSource: source || base.metadataSource || ""
    });
    return next;
}

function markMissingEntries(entriesByAddress, seenAddresses, now, ttlMs) {
    var ttl = ttlMs > 0 ? ttlMs : ENTRY_TTL_MS;
    var next = {};
    for (var key in entriesByAddress) {
        var entry = entriesByAddress[key];
        if (!entry)
            continue;
        var seen = !!seenAddresses[key];
        if (seen) {
            next[key] = Object.assign({}, entry, { isLive: true });
            continue;
        }
        var stale = Object.assign({}, entry, { isLive: false });
        if (!stale.connected && !stale.paired && now - Number(stale.lastSeenMs || 0) > ttl)
            continue;
        next[key] = stale;
    }
    return next;
}

function sortEntries(entries) {
    return entries.slice().sort(function(a, b) {
        if (!!a.connected !== !!b.connected)
            return a.connected ? -1 : 1;
        if (!!a.paired !== !!b.paired)
            return a.paired ? -1 : 1;
        if (!!a.isLive !== !!b.isLive)
            return a.isLive ? -1 : 1;
        var seenDiff = Number(b.lastSeenMs || 0) - Number(a.lastSeenMs || 0);
        if (seenDiff !== 0)
            return seenDiff;
        return String(a.displayName || a.address || "").localeCompare(String(b.displayName || b.address || ""));
    });
}

function sectionedEntries(entriesByAddress, now, ttlMs) {
    var ttl = ttlMs > 0 ? ttlMs : ENTRY_TTL_MS;
    var connected = [];
    var paired = [];
    var available = [];
    for (var key in entriesByAddress) {
        var entry = entriesByAddress[key];
        if (!entry)
            continue;
        if (!entry.connected && !entry.paired && now - Number(entry.lastSeenMs || 0) > ttl)
            continue;
        if (entry.connected)
            connected.push(entry);
        else if (entry.paired)
            paired.push(entry);
        else
            available.push(entry);
    }
    return {
        connected: sortEntries(connected),
        paired: sortEntries(paired),
        available: sortEntries(available),
        all: sortEntries(connected.concat(paired, available))
    };
}

function seenAgoLabel(entry, now) {
    if (!entry || entry.isLive)
        return "";
    var delta = Math.max(0, Number(now || 0) - Number(entry.lastSeenMs || 0));
    var seconds = Math.round(delta / 1000);
    if (seconds < 60)
        return "Seen just now";
    var minutes = Math.round(seconds / 60);
    if (minutes < 60)
        return "Seen " + minutes + "m ago";
    var hours = Math.round(minutes / 60);
    return "Seen " + hours + "h ago";
}

function buildCompanyLookup(rows) {
    var map = {};
    var items = Array.isArray(rows) ? rows : [];
    for (var i = 0; i < items.length; ++i) {
        var row = items[i];
        if (!row)
            continue;
        map[String(Number(row.code))] = String(row.name || "");
    }
    return map;
}

function buildServiceLookup(rows) {
    var map = {};
    var items = Array.isArray(rows) ? rows : [];
    for (var i = 0; i < items.length; ++i) {
        var row = items[i];
        if (!row)
            continue;
        var uuid = normalizeUuid(row.uuid);
        if (uuid.length === 0)
            continue;
        map[uuid] = String(row.name || "");
    }
    return map;
}

function buildAppearanceLookup(rows) {
    var map = {};
    var items = Array.isArray(rows) ? rows : [];
    for (var i = 0; i < items.length; ++i) {
        var category = items[i];
        if (!category)
            continue;
        var catValue = Number(category.category);
        if (!isFinite(catValue))
            continue;
        var catName = String(category.name || "");
        map[String(catValue << 6)] = catName;
        var sub = Array.isArray(category.subcategory) ? category.subcategory : [];
        for (var j = 0; j < sub.length; ++j) {
            var child = sub[j];
            if (!child)
                continue;
            var value = Number(child.value);
            if (!isFinite(value))
                continue;
            map[String((catValue << 6) + value)] = String(child.name || catName);
        }
    }
    return map;
}

function companyName(lookup, manufacturerIds) {
    var ids = Array.isArray(manufacturerIds) ? manufacturerIds : [];
    for (var i = 0; i < ids.length; ++i) {
        var name = lookup[String(Number(ids[i]))];
        if (name)
            return name;
    }
    return "";
}

function serviceNames(lookup, uuids, limit) {
    var out = [];
    var seen = {};
    var maxItems = limit > 0 ? limit : 2;
    var items = Array.isArray(uuids) ? uuids : [];
    for (var i = 0; i < items.length; ++i) {
        var uuid = normalizeUuid(items[i]);
        var name = lookup[uuid];
        if (!name || seen[name])
            continue;
        seen[name] = true;
        out.push(name);
        if (out.length >= maxItems)
            break;
    }
    return out;
}

function appearanceName(lookup, appearance) {
    var value = Number(appearance);
    if (!isFinite(value) || value < 0)
        return "";
    return lookup[String(value)] || "";
}

function enrichEntry(entry, lookups, now) {
    var next = Object.assign({}, entry);
    var companyLookup = lookups && lookups.companyLookup ? lookups.companyLookup : {};
    var serviceLookup = lookups && lookups.serviceLookup ? lookups.serviceLookup : {};
    var appearanceLookup = lookups && lookups.appearanceLookup ? lookups.appearanceLookup : {};
    next.vendorName = companyName(companyLookup, next.manufacturerIds || []);
    next.serviceNames = serviceNames(serviceLookup, next.serviceUuids || [], 2);
    next.appearanceName = appearanceName(appearanceLookup, next.appearance);
    next.seenLabel = seenAgoLabel(next, now);
    return next;
}

function subtitleForEntry(entry) {
    if (!entry)
        return "";
    var parts = [];
    if (entry.vendorName)
        parts.push(entry.vendorName);
    else if (entry.appearanceName)
        parts.push(entry.appearanceName);
    else if (entry.serviceNames && entry.serviceNames.length > 0)
        parts.push(entry.serviceNames[0]);
    if (entry.address)
        parts.push(entry.address);
    if (entry.seenLabel)
        parts.push(entry.seenLabel);
    return parts.join(" • ");
}

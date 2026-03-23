.pragma library

function _toNumber(value, fallbackValue) {
    var parsed = Number(value);
    return isFinite(parsed) ? parsed : (fallbackValue === undefined ? 0 : fallbackValue);
}

function _extractCardName(value) {
    var text = String(value || "");
    var match = text.match(/card\d+/);
    return match ? match[0] : "";
}

function _extractCardIndex(value) {
    var match = String(_extractCardName(value)).match(/\d+/);
    return match ? parseInt(match[0], 10) : Number.POSITIVE_INFINITY;
}

function _extractPciAddress(value) {
    var text = String(value || "");
    var match = text.match(/[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F]/);
    return match ? match[0].toLowerCase() : "";
}

function _isExplicitDgpu(gpuType) {
    var text = String(gpuType || "").toLowerCase();
    return text.indexOf("dgpu") !== -1 || text.indexOf("discrete") !== -1;
}

function normalizeGpuCandidate(candidate) {
    var raw = candidate && candidate.raw !== undefined ? candidate.raw : candidate;
    var vramTotalBytes = candidate && candidate.vramTotalBytes !== undefined
        ? _toNumber(candidate.vramTotalBytes, 0)
        : _toNumber(candidate && candidate.vramTotalMiB, 0) * 1024 * 1024;
    var vramUsedBytes = candidate && candidate.vramUsedBytes !== undefined
        ? _toNumber(candidate.vramUsedBytes, 0)
        : _toNumber(candidate && candidate.vramUsedMiB, 0) * 1024 * 1024;
    var busyPercent = candidate && candidate.busyPercent !== undefined
        ? _toNumber(candidate.busyPercent, 0)
        : _toNumber(candidate && candidate.gfxPercent, 0);
    var tempC = candidate && candidate.tempC !== undefined
        ? _toNumber(candidate.tempC, 0)
        : _toNumber(candidate && candidate.temperatureC, 0);
    var cardName = _extractCardName(candidate && (
        candidate.cardName
        || candidate.card
        || candidate.cardPath
        || candidate.drmCard
        || candidate.devicePath
    ));
    var pciAddress = _extractPciAddress(candidate && (
        candidate.pciAddress
        || candidate.pci
        || candidate.sysfsPath
        || candidate.devicePath
    ));

    return {
        raw: raw,
        cardName: cardName,
        cardIndex: _extractCardIndex(cardName),
        pciAddress: pciAddress,
        gpuType: String(candidate && (candidate.gpuType || candidate.type || "") || ""),
        isExplicitDgpu: _isExplicitDgpu(candidate && (candidate.gpuType || candidate.type || "")),
        busyPercent: busyPercent,
        tempC: tempC,
        vramTotalBytes: Math.max(0, vramTotalBytes),
        vramUsedBytes: Math.max(0, vramUsedBytes),
    };
}

function _isBetterCandidate(nextCandidate, currentCandidate) {
    if (!currentCandidate)
        return true;
    if (nextCandidate.isExplicitDgpu !== currentCandidate.isExplicitDgpu)
        return nextCandidate.isExplicitDgpu;
    if (nextCandidate.vramTotalBytes !== currentCandidate.vramTotalBytes)
        return nextCandidate.vramTotalBytes > currentCandidate.vramTotalBytes;
    if (nextCandidate.busyPercent !== currentCandidate.busyPercent)
        return nextCandidate.busyPercent > currentCandidate.busyPercent;
    if (nextCandidate.cardIndex !== currentCandidate.cardIndex)
        return nextCandidate.cardIndex < currentCandidate.cardIndex;
    if (nextCandidate.cardName !== currentCandidate.cardName)
        return nextCandidate.cardName < currentCandidate.cardName;
    return nextCandidate.pciAddress < currentCandidate.pciAddress;
}

function selectPreferredGpuCandidate(candidates) {
    var best = null;
    var list = Array.isArray(candidates) ? candidates : [];
    for (var i = 0; i < list.length; i++) {
        var normalized = normalizeGpuCandidate(list[i]);
        if (!normalized.cardName && !normalized.pciAddress)
            continue;
        if (_isBetterCandidate(normalized, best))
            best = normalized;
    }
    return best;
}

function amdgpuTopDeviceIdentity(device) {
    var info = device && device.Info ? device.Info : {};
    var devicePath = info.DevicePath || {};
    var vram = device && device.VRAM ? device.VRAM : {};
    var gpuActivity = device && device.gpu_activity ? device.gpu_activity : {};

    return normalizeGpuCandidate({
        raw: device,
        cardName: devicePath.card,
        pciAddress: devicePath.pci,
        gpuType: info["GPU Type"],
        busyPercent: gpuActivity.GFX ? gpuActivity.GFX.value : 0,
        vramTotalMiB: vram["Total VRAM"] ? vram["Total VRAM"].value : 0,
        vramUsedMiB: vram["Total VRAM Usage"] ? vram["Total VRAM Usage"].value : 0,
    });
}

function selectPreferredAmdgpuTopDevice(devices) {
    var best = null;
    var list = Array.isArray(devices) ? devices : [];
    for (var i = 0; i < list.length; i++) {
        var normalized = amdgpuTopDeviceIdentity(list[i]);
        if (_isBetterCandidate(normalized, best))
            best = normalized;
    }
    return best ? best.raw : null;
}

function findMatchingAmdgpuTopDevice(devices, identity) {
    var wantCard = _extractCardName(identity && (identity.cardName || identity.card || identity.cardPath));
    var wantPci = _extractPciAddress(identity && (identity.pciAddress || identity.pci || identity.devicePath));
    var list = Array.isArray(devices) ? devices : [];
    var fallback = null;

    for (var i = 0; i < list.length; i++) {
        var normalized = amdgpuTopDeviceIdentity(list[i]);
        if (wantCard && wantPci && normalized.cardName === wantCard && normalized.pciAddress === wantPci)
            return list[i];
        if (!fallback && wantCard && normalized.cardName === wantCard)
            fallback = list[i];
        if (!fallback && wantPci && normalized.pciAddress === wantPci)
            fallback = list[i];
    }

    return fallback;
}

function amdgpuFdinfoUsage(entry) {
    if (entry && entry.usage && entry.usage.usage)
        return entry.usage.usage;
    if (entry && entry.usage)
        return entry.usage;
    return {};
}

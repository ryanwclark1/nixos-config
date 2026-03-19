/**
 * Global test setup — provides a minimal Qt mock for files that use Qt.rgba().
 * Currently needed by: ColorUtils.js, and any future files using Qt APIs.
 */

globalThis.Qt = {
  rgba(r, g, b, a) {
    return { r, g, b, a: a !== undefined ? a : 1.0 };
  },
};

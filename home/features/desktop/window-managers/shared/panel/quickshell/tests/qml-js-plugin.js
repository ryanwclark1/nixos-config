/**
 * Vite plugin that transforms QML .pragma library JS files into valid ESM.
 *
 * Handles three QML-specific constructs:
 *  1. `.pragma library`           → stripped (no ESM equivalent)
 *  2. `.import "Foo.js" as Bar`   → `import * as Bar from "./Foo.js";`
 *  3. Top-level `function` / `var` → appended `export { ... }`
 */

import { dirname, resolve } from "path";

export default function qmlJsPlugin() {
  return {
    name: "qml-js-transform",
    enforce: "pre",

    // Resolve .import references relative to the importer's directory
    resolveId(source, importer) {
      if (importer && source.endsWith(".js") && !source.startsWith("/") && !source.startsWith(".")) {
        return resolve(dirname(importer), source);
      }
      return null;
    },

    transform(code, id) {
      const cleanId = String(id || "").split("?", 1)[0].split("#", 1)[0];
      if (!cleanId.endsWith(".js") || !code.includes(".pragma library")) return null;

      let transformed = code
        // Strip .pragma library
        .replace(/^\.pragma\s+library\s*$/m, "")
        // Convert .import "Foo.js" as Bar → import * as Bar from "./Foo.js";
        .replace(
          /^\.import\s+"([^"]+)"\s+as\s+(\w+)\s*$/gm,
          'import * as $2 from "$1";'
        );

      // Collect top-level function and var names for export
      const exports = new Set();
      for (const m of transformed.matchAll(/^function\s+(\w+)\s*\(/gm)) {
        exports.add(m[1]);
      }
      for (const m of transformed.matchAll(/^var\s+(\w+)\s*=/gm)) {
        exports.add(m[1]);
      }

      if (exports.size > 0) {
        transformed += "\nexport { " + [...exports].join(", ") + " };\n";
      }

      return { code: transformed, map: null };
    },
  };
}

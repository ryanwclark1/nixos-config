import { defineConfig } from "vitest/config";
import qmlJsPlugin from "./qml-js-plugin.js";

export default defineConfig({
  plugins: [qmlJsPlugin()],
  test: {
    include: ["tests/**/*.test.js"],
    setupFiles: ["tests/setup.js"],
  },
});

import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

function loadRenderer() {
  const source = readFileSync(resolve(quickshellRoot, "src/services/HypridleConfig.js"), "utf8")
    .replace(/^\s*\.pragma\s+library\s*$/m, "");
  return new Function(`${source}\nreturn { render, suspendCommand, clampMinutes };`)();
}

describe("HypridleConfig", () => {
  it("renders timeouts in seconds for the selected profile", () => {
    const { render } = loadRenderer();
    const rendered = render({
      monitorTimeout: 5,
      lockTimeout: 7,
      suspendTimeout: 10,
      suspendAction: "suspend",
    });

    expect(rendered).toContain("timeout = 300");
    expect(rendered).toContain("timeout = 420");
    expect(rendered).toContain("timeout = 600");
    expect(rendered).toContain("on-timeout = hyprctl dispatch dpms off");
    expect(rendered).toContain("on-timeout = loginctl lock-session");
    expect(rendered).toContain("on-timeout = systemctl suspend");
  });

  it("maps alternate suspend actions to systemctl commands", () => {
    const { render } = loadRenderer();

    expect(render({ monitorTimeout: 15, lockTimeout: 45, suspendTimeout: 45, suspendAction: "hibernate" }))
      .toContain("on-timeout = systemctl hibernate");
    expect(render({ monitorTimeout: 15, lockTimeout: 45, suspendTimeout: 45, suspendAction: "poweroff" }))
      .toContain("on-timeout = systemctl poweroff");
  });
});

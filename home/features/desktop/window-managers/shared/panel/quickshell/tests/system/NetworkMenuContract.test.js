import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

function source(relativePath) {
  return readFileSync(resolve(quickshellRoot, relativePath), "utf8");
}

describe("Network menu contract", () => {
  it("adds a copy action for public IPv4 cards through NetworkService", () => {
    const menu = source("src/features/network/NetworkMenu.qml");
    const service = source("src/services/NetworkService.qml");

    expect(menu).toContain('icon: "copy.svg"');
    expect(menu).toContain('tooltipText: String(modelData.copyTooltip || ("Copy " + modelData.label))');
    expect(menu).toContain('onClicked: NetworkService.copyText(String(modelData.copyLabel || modelData.label), String(modelData.copyValue || ""))');
    expect(menu).toContain('copyValue: NetworkService.publicIpv4');
    expect(menu).toContain('copyTooltip: "Copy public IPv4"');

    expect(service).toContain("function copyText(label, text) {");
    expect(service).toContain('ToastService.showNotice("Nothing to copy", String(label || "Value") + " is unavailable.");');
    expect(service).toContain('ToastService.showNotice("Copy pending", "Wait for the current clipboard action to finish.");');
    expect(service).toContain('+ "printf \'%s\' \\\"$1\\\" | wl-copy; "');
    expect(service).toContain('+ "printf \'%s\' \\\"$1\\\" | xclip -selection clipboard; "');
    expect(service).toContain("property Process clipboardActionProc: Process {");
  });
});

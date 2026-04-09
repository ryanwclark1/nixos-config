import { describe, it, expect } from "vitest";
import { shellQuote, terminalCommand, ipcCall, shellSurfaceCall } from "../../src/services/ShellUtils.js";

describe("shellQuote", () => {
  it("wraps in single quotes", () => {
    expect(shellQuote("hello")).toBe("'hello'");
  });

  it("escapes single quotes", () => {
    expect(shellQuote("it's a test")).toBe("'it'\\''s a test'");
  });

  it("handles empty/null", () => {
    expect(shellQuote("")).toBe("''");
    expect(shellQuote(null)).toBe("''");
  });

  it("preserves special chars inside quotes", () => {
    expect(shellQuote('$HOME & "stuff"')).toBe("'$HOME & \"stuff\"'");
  });
});

describe("terminalCommand", () => {
  it("returns shell command array for simple cmd", () => {
    const result = terminalCommand("htop");
    expect(result[0]).toBe("sh");
    expect(result[1]).toBe("-c");
    expect(result[2]).toContain("exec $t -e bash -lc");
    expect(result[3]).toBe("sh");
    expect(result[4]).toBe("htop");
    expect(result).toHaveLength(5);
  });

  it("appends extra args as positional parameters", () => {
    const result = terminalCommand('exec ssh "$1"', "myhost");
    // Extra args come after the base 5 elements
    expect(result).toHaveLength(6);
    expect(result[5]).toBe("myhost");
    // Inner script should reference $2
    expect(result[2]).toContain('"$2"');
  });

  it("handles multiple extra args", () => {
    const result = terminalCommand("cmd", "arg1", "arg2");
    expect(result).toHaveLength(7);
    expect(result[5]).toBe("arg1");
    expect(result[6]).toBe("arg2");
    expect(result[2]).toContain('"$2"');
    expect(result[2]).toContain('"$3"');
  });

  it("searches for known terminal emulators", () => {
    const result = terminalCommand("test");
    expect(result[2]).toContain("ghostty");
    expect(result[2]).toContain("kitty");
    expect(result[2]).toContain("foot");
    expect(result[2]).toContain("alacritty");
  });
});

describe("ipcCall", () => {
  it("builds quickshell ipc argv for target and method", () => {
    expect(ipcCall("Shell", "reloadConfig")).toEqual([
      "quickshell",
      "ipc",
      "call",
      "Shell",
      "reloadConfig",
    ]);
  });

  it("stringifies extra surface or argument tokens", () => {
    expect(ipcCall("SettingsHub", "openSetting", "tab", "Card", "Label")).toEqual([
      "quickshell",
      "ipc",
      "call",
      "SettingsHub",
      "openSetting",
      "tab",
      "Card",
      "Label",
    ]);
  });

  it("coerces empty target/method to string", () => {
    expect(ipcCall(null, undefined)).toEqual([
      "quickshell",
      "ipc",
      "call",
      "",
      "",
    ]);
  });
});

describe("shellSurfaceCall", () => {
  it("pads Shell surface calls with an empty screen name by default", () => {
    expect(shellSurfaceCall("openSurface", "displayConfig")).toEqual([
      "quickshell",
      "ipc",
      "call",
      "Shell",
      "openSurface",
      "displayConfig",
      "",
    ]);
  });

  it("preserves explicit screen targeting", () => {
    expect(shellSurfaceCall("toggleSurface", "weatherMenu", "focused")).toEqual([
      "quickshell",
      "ipc",
      "call",
      "Shell",
      "toggleSurface",
      "weatherMenu",
      "focused",
    ]);
  });
});

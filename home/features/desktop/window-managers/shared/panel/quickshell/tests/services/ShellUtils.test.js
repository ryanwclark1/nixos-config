import { describe, it, expect } from "vitest";
import { shellQuote, terminalCommand } from "../../src/services/ShellUtils.js";

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

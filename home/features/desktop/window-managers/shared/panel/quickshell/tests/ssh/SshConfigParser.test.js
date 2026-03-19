import { describe, it, expect } from "vitest";
import {
  stripComments,
  splitKeywordValue,
  tokenize,
  hasWildcard,
  isExactAlias,
  parseFile,
} from "../../src/features/ssh/components/SshConfigParser.js";

// ---------------------------------------------------------------------------
// stripComments
// ---------------------------------------------------------------------------

describe("stripComments", () => {
  it("strips trailing # comments", () => {
    expect(stripComments("Host foo # my server")).toBe("Host foo ");
  });

  it("preserves # inside double quotes", () => {
    expect(stripComments('Host "foo#bar"')).toBe('Host "foo#bar"');
  });

  it("preserves # inside single quotes", () => {
    expect(stripComments("Host 'foo#bar'")).toBe("Host 'foo#bar'");
  });

  it("handles escaped characters", () => {
    expect(stripComments("Host foo\\#bar")).toBe("Host foo\\#bar");
  });

  it("returns full line when no comment", () => {
    expect(stripComments("HostName 192.168.1.1")).toBe("HostName 192.168.1.1");
  });

  it("returns empty for pure comment line", () => {
    expect(stripComments("# this is a comment")).toBe("");
  });
});

// ---------------------------------------------------------------------------
// splitKeywordValue
// ---------------------------------------------------------------------------

describe("splitKeywordValue", () => {
  it("splits on whitespace", () => {
    expect(splitKeywordValue("Host foo")).toEqual({ key: "Host", value: "foo" });
  });

  it("splits on equals sign", () => {
    expect(splitKeywordValue("Port=22")).toEqual({ key: "Port", value: "22" });
  });

  it("handles extra whitespace around equals", () => {
    expect(splitKeywordValue("Port = 22")).toEqual({ key: "Port", value: "22" });
  });

  it("returns key-only when no value", () => {
    expect(splitKeywordValue("ForwardAgent")).toEqual({
      key: "ForwardAgent",
      value: "",
    });
  });

  it("returns null for empty input", () => {
    expect(splitKeywordValue("")).toBeNull();
    expect(splitKeywordValue("   ")).toBeNull();
  });

  it("preserves quoted values", () => {
    expect(splitKeywordValue('IdentityFile "~/.ssh/id_rsa"')).toEqual({
      key: "IdentityFile",
      value: '"~/.ssh/id_rsa"',
    });
  });
});

// ---------------------------------------------------------------------------
// tokenize
// ---------------------------------------------------------------------------

describe("tokenize", () => {
  it("splits on whitespace", () => {
    expect(tokenize("foo bar baz")).toEqual(["foo", "bar", "baz"]);
  });

  it("keeps quoted strings intact", () => {
    expect(tokenize('"foo bar" baz')).toEqual(["foo bar", "baz"]);
    expect(tokenize("'hello world'")).toEqual(["hello world"]);
  });

  it("handles escaped characters", () => {
    expect(tokenize("foo\\ bar")).toEqual(["foo bar"]);
  });

  it("returns empty array for empty input", () => {
    expect(tokenize("")).toEqual([]);
    expect(tokenize("   ")).toEqual([]);
  });

  it("handles mixed quoting", () => {
    expect(tokenize('hello "brave new" world')).toEqual([
      "hello",
      "brave new",
      "world",
    ]);
  });
});

// ---------------------------------------------------------------------------
// hasWildcard / isExactAlias
// ---------------------------------------------------------------------------

describe("hasWildcard", () => {
  it("detects * wildcard", () => {
    expect(hasWildcard("*.example.com")).toBe(true);
  });

  it("detects ? wildcard", () => {
    expect(hasWildcard("host?")).toBe(true);
  });

  it("detects [] bracket pattern", () => {
    expect(hasWildcard("host[123]")).toBe(true);
  });

  it("returns false for plain hostname", () => {
    expect(hasWildcard("myserver")).toBe(false);
  });
});

describe("isExactAlias", () => {
  it("returns true for plain hostname", () => {
    expect(isExactAlias("myserver")).toBe(true);
  });

  it("returns false for wildcard pattern", () => {
    expect(isExactAlias("*.example.com")).toBe(false);
  });

  it("returns false for negated pattern", () => {
    expect(isExactAlias("!badhost")).toBe(false);
  });

  it("returns false for empty string", () => {
    expect(isExactAlias("")).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// parseFile
// ---------------------------------------------------------------------------

describe("parseFile", () => {
  it("parses a simple host block", () => {
    const config = `
Host myserver
  HostName 192.168.1.100
  User admin
  Port 2222
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases).toHaveLength(1);
    expect(result.aliases[0]).toMatchObject({
      alias: "myserver",
      hostName: "192.168.1.100",
      user: "admin",
      port: 2222,
    });
  });

  it("parses multiple host blocks", () => {
    const config = `
Host web
  HostName web.example.com

Host db
  HostName db.example.com
  Port 5432
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases).toHaveLength(2);
    expect(result.aliases[0].alias).toBe("web");
    expect(result.aliases[1].alias).toBe("db");
    expect(result.aliases[1].port).toBe(5432);
  });

  it("skips wildcard patterns into skippedPatterns", () => {
    const config = `
Host *
  ServerAliveInterval 60

Host *.internal
  ProxyJump bastion
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases).toHaveLength(0);
    expect(result.skippedPatterns).toHaveLength(2);
    expect(result.skippedPatterns[0].alias).toBe("*");
    expect(result.skippedPatterns[1].alias).toBe("*.internal");
  });

  it("collects Include directives", () => {
    const config = `
Include ~/.ssh/config.d/*
Host foo
  HostName foo.example.com
`;
    const result = parseFile(config, "/test/config");
    expect(result.includes).toHaveLength(1);
    expect(result.includes[0].pattern).toBe("~/.ssh/config.d/*");
    expect(result.aliases).toHaveLength(1);
  });

  it("handles Match blocks", () => {
    const config = `
Match host *.prod
  ForwardAgent yes
`;
    const result = parseFile(config, "/test/config");
    expect(result.matchBlocks).toHaveLength(1);
    expect(result.matchBlocks[0].conditions).toEqual(["host", "*.prod"]);
  });

  it("ignores comment-only lines", () => {
    const config = `
# Global settings
Host mybox
  # User for mybox
  HostName mybox.local
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases).toHaveLength(1);
    expect(result.errors).toHaveLength(0);
  });

  it("handles Host with multiple patterns (mixed exact and wildcard)", () => {
    const config = `
Host web1 web2 *.staging
  HostName staging.example.com
`;
    const result = parseFile(config, "/test/config");
    // web1 and web2 are exact, *.staging is wildcard
    expect(result.aliases).toHaveLength(2);
    expect(result.aliases[0].alias).toBe("web1");
    expect(result.aliases[1].alias).toBe("web2");
    expect(result.skippedPatterns).toHaveLength(1);
  });

  it("returns empty result for empty input", () => {
    const result = parseFile("", "/test/config");
    expect(result.aliases).toEqual([]);
    expect(result.includes).toEqual([]);
    expect(result.errors).toEqual([]);
  });

  it("uses first-wins semantics for host options", () => {
    const config = `
Host dup
  Port 2222
  Port 3333
  HostName dup.example.com
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases[0].port).toBe(2222);
  });

  it("defaults port to 22 when not specified", () => {
    const config = `
Host noport
  HostName noport.example.com
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases[0].port).toBe(22);
  });

  it("preserves ProxyJump and IdentityFile options", () => {
    const config = `
Host jumpbox
  HostName internal.example.com
  ProxyJump bastion
  IdentityFile ~/.ssh/special_key
`;
    const result = parseFile(config, "/test/config");
    expect(result.aliases[0].proxyJump).toBe("bastion");
    expect(result.aliases[0].identityFile).toBe("~/.ssh/special_key");
  });
});

#!/usr/bin/env node
// Unit tests for web provider expansion pure functions.
// Loads the .pragma library JS files directly and tests their logic.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const srcDir = path.resolve(__dirname, "..", "src");

// ── Minimal loader for .pragma library JS ─────────────────────────────
// Strips `.pragma library` and evaluates in a fresh scope, returning exports.
function loadPragmaLib(relPath) {
  const raw = fs.readFileSync(path.join(srcDir, relPath), "utf8");
  const code = raw.replace(/^\.pragma library\s*/, "");
  const exports = {};
  const fn = new Function("exports", code + "\n" +
    "for (const k of Object.getOwnPropertyNames(this)) { if (typeof this[k] !== 'undefined') exports[k] = this[k]; }");
  // Run with a fresh `this` context so top-level vars become properties
  const ctx = Object.create(null);
  new Function("exports", `"use strict";\n${code}\n` +
    `Object.keys(this).forEach(function(k) { exports[k] = this[k]; }.bind(this));`
  ).call(ctx, exports);
  // Also grab `var` declarations which end up on the module scope
  const varMatch = code.matchAll(/^(?:var|function)\s+([a-zA-Z_$][a-zA-Z0-9_$]*)/gm);
  for (const m of varMatch) {
    if (ctx[m[1]] !== undefined) exports[m[1]] = ctx[m[1]];
  }
  return exports;
}

// Since .pragma library files use `var` at top scope which doesn't attach to
// `this` in strict mode, we use a simpler eval approach:
function loadModule(relPath) {
  const raw = fs.readFileSync(path.join(srcDir, relPath), "utf8");
  const code = raw.replace(/^\.pragma library\s*/, "");
  // Wrap in IIFE that returns all declared names
  const varNames = [...code.matchAll(/^(?:var|function)\s+([a-zA-Z_$][a-zA-Z0-9_$]*)/gm)].map(m => m[1]);
  const wrapped = `(function() {\n${code}\nreturn {${[...new Set(varNames)].join(",")}};\n})()`;
  return eval(wrapped);
}

let passed = 0;
let failed = 0;

function assert(condition, label) {
  if (condition) {
    passed++;
  } else {
    failed++;
    console.error(`  FAIL: ${label}`);
  }
}

function assertEq(actual, expected, label) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) {
    passed++;
  } else {
    failed++;
    console.error(`  FAIL: ${label}\n    expected: ${e}\n    actual:   ${a}`);
  }
}

// ── Load modules ──────────────────────────────────────────────────────

const ModeData = loadModule("launcher/LauncherModeData.js");
const WebProviders = loadModule("launcher/LauncherWebProviders.js");
const ConfigLauncher = loadModule("services/config/ConfigLauncher.js");

// ── Test: webProviderCatalog has 26 entries ───────────────────────────

const catalogKeys = Object.keys(ModeData.webProviderCatalog).sort();
assert(catalogKeys.length === 26, `catalog has 26 providers (got ${catalogKeys.length})`);

// Spot-check a few
assert(ModeData.webProviderCatalog.google !== undefined, "google exists");
assert(ModeData.webProviderCatalog.brave !== undefined, "brave exists");
assert(ModeData.webProviderCatalog.stackoverflow !== undefined, "stackoverflow exists");
assert(ModeData.webProviderCatalog.wikipedia !== undefined, "wikipedia exists");
assert(ModeData.webProviderCatalog.nixopts !== undefined, "nixopts exists");
assert(ModeData.webProviderCatalog.images !== undefined, "images exists");

// ── Test: mergedProviderCatalog ───────────────────────────────────────

const merged = ModeData.mergedProviderCatalog([
  { key: "rustdoc", name: "Rust Docs", exec: "https://doc.rust-lang.org/std/?search=%s" }
]);
assert(merged.google !== undefined, "merged keeps builtins");
assert(merged.rustdoc !== undefined, "merged includes custom");
assert(merged.rustdoc.isCustom === true, "custom engine flagged");
assertEq(merged.rustdoc.icon, "globe-search.svg", "custom engine default icon");

// Custom can override built-in
const overridden = ModeData.mergedProviderCatalog([
  { key: "google", name: "My Google", exec: "https://custom.google.com/?q=" }
]);
assertEq(overridden.google.name, "My Google", "custom overrides built-in");
assertEq(overridden.google.isCustom, true, "override flagged as custom");

// Invalid entries skipped
const withInvalid = ModeData.mergedProviderCatalog([
  null,
  { key: "", name: "No Key", exec: "https://example.com" },
  { key: "valid", name: "", exec: "https://example.com" },
  { key: "valid2", name: "Valid", exec: "" },
  { key: "ok", name: "OK", exec: "https://ok.com" }
]);
assert(withInvalid.ok !== undefined, "valid custom engine accepted");
assert(withInvalid.valid === undefined, "engine without name rejected");
assert(withInvalid.valid2 === undefined, "engine without exec rejected");

// ── Test: configuredWebProviders with custom engines ──────────────────

const custom = [{ key: "rustdoc", name: "Rust Docs", exec: "https://doc.rust-lang.org/std/?search=%s" }];
const configured = ModeData.configuredWebProviders(["google", "rustdoc"], custom);
assertEq(configured.length, 2, "configured returns 2 providers");
assertEq(configured[0].key, "google", "first is google");
assertEq(configured[1].key, "rustdoc", "second is rustdoc");

// Fallback when empty order
const fallback = ModeData.configuredWebProviders([], null);
assert(fallback.length === 5, "empty order falls back to default 5");

// ── Test: buildWebTarget with %s placeholder ──────────────────────────

const appendProvider = { exec: "https://google.com/search?q=", home: "https://google.com/" };
assertEq(
  WebProviders.buildWebTarget(appendProvider, "hello world"),
  "https://google.com/search?q=hello%20world",
  "append-style URL"
);

const placeholderProvider = { exec: "https://doc.rust-lang.org/std/?search=%s", home: "" };
assertEq(
  WebProviders.buildWebTarget(placeholderProvider, "Vec"),
  "https://doc.rust-lang.org/std/?search=Vec",
  "placeholder-style URL"
);

// Multiple %s placeholders
const multiPlaceholder = { exec: "https://example.com/?q=%s&lang=%s", home: "" };
assertEq(
  WebProviders.buildWebTarget(multiPlaceholder, "test"),
  "https://example.com/?q=test&lang=test",
  "multiple %s replaced"
);

// Empty query returns home
assertEq(
  WebProviders.buildWebTarget(appendProvider, ""),
  "https://google.com/",
  "empty query returns home"
);

// Null provider
assertEq(WebProviders.buildWebTarget(null, "test"), "", "null provider returns empty");

// ── Test: normalizeCustomEngines ──────────────────────────────────────

const normalized = ConfigLauncher.normalizeCustomEngines([
  { key: "MyEngine!", name: "My Engine", exec: "https://example.com/?q=%s" },
  { key: "valid-one", name: "Valid", exec: "https://valid.com" },
  { key: "valid-one", name: "Duplicate", exec: "https://dupe.com" },
  null,
  { key: "no-name", name: "", exec: "https://noname.com" },
  { key: "no-url", name: "No URL", exec: "" }
]);
assertEq(normalized.length, 2, "normalizeCustomEngines filters invalid entries");
assertEq(normalized[0].key, "myengine", "key sanitized (lowercase, special chars removed)");
assertEq(normalized[1].key, "valid-one", "valid key preserved");

// Cap at 50
const bigList = [];
for (let i = 0; i < 60; i++) bigList.push({ key: "e" + i, name: "Engine " + i, exec: "https://e" + i + ".com" });
const capped = ConfigLauncher.normalizeCustomEngines(bigList);
assertEq(capped.length, 50, "custom engines capped at 50");

// ── Test: _buildCatalogKeys ───────────────────────────────────────────

const keys = ConfigLauncher._buildCatalogKeys([]);
assert(keys.length === 26, `_buildCatalogKeys returns 26 built-in keys (got ${keys.length})`);
assert(keys.indexOf("google") !== -1, "google in catalog keys");
assert(keys.indexOf("images") !== -1, "images in catalog keys");

const keysWithCustom = ConfigLauncher._buildCatalogKeys([{ key: "rustdoc" }]);
assert(keysWithCustom.length === 27, "catalog keys includes custom engine");
assert(keysWithCustom.indexOf("rustdoc") !== -1, "rustdoc in catalog keys");

// Existing key not duplicated
const keysNoDupe = ConfigLauncher._buildCatalogKeys([{ key: "google" }]);
assertEq(keysNoDupe.length, 26, "existing key not duplicated");

// ── Test: webAliasToProviderKey with custom engines ───────────────────

const providers = [ModeData.webProviderCatalog.google];
const aliases = { google: ["g"] };
const customEngines = [{ key: "rustdoc", name: "Rust Docs", exec: "https://doc.rust-lang.org/std/?search=%s" }];

// Direct key match against merged catalog
assertEq(
  ModeData.webAliasToProviderKey("rustdoc", providers, aliases, customEngines),
  "rustdoc",
  "custom engine found by direct key"
);

// Built-in still works
assertEq(
  ModeData.webAliasToProviderKey("google", providers, aliases, customEngines),
  "google",
  "built-in found by direct key"
);

// Alias still works
assertEq(
  ModeData.webAliasToProviderKey("g", providers, aliases, customEngines),
  "google",
  "alias resolves to provider"
);

// Unknown returns empty
assertEq(
  ModeData.webAliasToProviderKey("unknown", providers, aliases, customEngines),
  "",
  "unknown returns empty"
);

// ── Test: parseWebQuery with custom engines ───────────────────────────

const parsed = ModeData.parseWebQuery("?rustdoc Vec", providers, aliases, customEngines);
assertEq(parsed.providerKey, "rustdoc", "parseWebQuery resolves custom engine");
assertEq(parsed.query, "Vec", "parseWebQuery extracts query");

// ── Report ────────────────────────────────────────────────────────────

console.log(`\nWeb provider unit tests: ${passed} passed, ${failed} failed.`);
if (failed > 0) process.exit(1);

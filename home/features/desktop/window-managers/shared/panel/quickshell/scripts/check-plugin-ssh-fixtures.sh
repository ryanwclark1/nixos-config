#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_dir="${script_dir}/../config/plugins/ssh-monitor"
parser_js="${plugin_dir}/SshConfigParser.js"
root_fixture="${plugin_dir}/fixtures/root.conf"
expected_import="${plugin_dir}/expected-import.json"
expected_settings="${plugin_dir}/expected-settings.json"
expected_state="${plugin_dir}/expected-state-envelope.json"

pass_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

if ! command -v jq >/dev/null 2>&1; then
  echo '[FAIL] jq is required for ssh plugin fixture checks' >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo '[FAIL] node is required for ssh plugin fixture checks' >&2
  exit 1
fi

for required in "$parser_js" "$root_fixture" "$expected_import" "$expected_settings" "$expected_state"; do
  if [[ ! -f "$required" ]]; then
    echo "[FAIL] Missing ssh plugin fixture file: ${required}" >&2
    exit 1
  fi
done

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

node - "$parser_js" "$root_fixture" <<'EOF' >"$tmp_json"
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const parserPath = process.argv[2];
const fixtureRoot = process.argv[3];
const parserSource = fs.readFileSync(parserPath, "utf8").replace(/^\.pragma library\s*/m, "");
const context = { module: { exports: {} }, exports: {} };
vm.createContext(context);
vm.runInContext(parserSource, context, { filename: parserPath });
const parser = context.module.exports;
const fixtureDir = path.dirname(fixtureRoot);
const parsed = parser.parseFile(fs.readFileSync(fixtureRoot, "utf8"), fixtureRoot);
const includeDir = path.join(fixtureDir, "includes");
const files = ["team.conf", "ops.conf", "extra.conf"].map(name => path.join(includeDir, name));
for (const file of files) {
  const next = parser.parseFile(fs.readFileSync(file, "utf8"), file);
  parsed.aliases.push(...next.aliases);
  parsed.skippedPatterns.push(...next.skippedPatterns);
  parsed.matchBlocks.push(...next.matchBlocks);
  parsed.errors.push(...next.errors);
}
function rel(p) {
  return path.relative(path.dirname(fixtureDir), p).replace(/\\/g, "/");
}
const payload = {
  aliases: parsed.aliases.map(entry => ({
    alias: entry.alias,
    hostName: entry.hostName,
    user: entry.user,
    port: entry.port,
    sourcePath: rel(entry.sourcePath),
    sourceLine: entry.sourceLine
  })).sort((a, b) => a.alias.localeCompare(b.alias)),
  skippedPatterns: parsed.skippedPatterns.map(entry => ({
    alias: entry.alias,
    sourcePath: rel(entry.sourcePath),
    sourceLine: entry.sourceLine
  })).sort((a, b) => a.alias.localeCompare(b.alias)),
  matchBlockCount: parsed.matchBlocks.length,
  errorCount: parsed.errors.length
};
process.stdout.write(JSON.stringify(payload, null, 2));
EOF

if diff -u <(jq -S . "$expected_import") <(jq -S . "$tmp_json") >/dev/null; then
  pass "ssh parser fixtures match the expected alias import output"
else
  fail "ssh parser fixtures drifted from the expected alias import output"
  diff -u <(jq -S . "$expected_import") <(jq -S . "$tmp_json") >&2 || true
fi

if jq -e '
  (.manualHosts | type == "array")
  and (.manualHosts | length == 1)
  and (.manualHosts[0].id == "prod-bastion")
  and (.manualHosts[0].host == "bastion.example.com")
  and (.enableSshConfigImport == true)
  and (.displayMode == "count")
  and (.defaultAction == "connect")
' "$expected_settings" >/dev/null 2>&1; then
  pass "ssh settings fixture matches the persisted settings contract"
else
  fail "ssh settings fixture drifted from the persisted settings contract"
fi

if jq -e '
  .stateVersion == 1
  and (.payload.lastConnectedId | type == "string")
  and (.payload.lastConnectedLabel | type == "string")
  and (.payload.lastConnectedAt | type == "string")
  and (.payload.recentIds | type == "array")
  and (.payload.lastImportSummary.imported | type == "number")
  and (.payload.lastImportSummary.skippedPatterns | type == "number")
  and (.payload.lastImportSummary.errors | type == "number")
' "$expected_state" >/dev/null 2>&1; then
  pass "ssh state envelope fixture matches the persisted runtime state contract"
else
  fail "ssh state envelope fixture drifted from the persisted runtime state contract"
fi

printf '[INFO] Plugin ssh fixture summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

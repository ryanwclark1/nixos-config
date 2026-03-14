#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
local_runner="${script_dir}/plugin-local.sh"
reference_dir_name="reference-local-toolkit"

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

tmp_plugins="$(mktemp -d)"
tmp_other_source="$(mktemp -d)"
tmp_non_symlink_dir="$(mktemp -d)"
tmp_invalid_reference_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_plugins" "$tmp_other_source" "$tmp_non_symlink_dir" "$tmp_invalid_reference_dir"' EXIT

reference_path="${tmp_plugins}/${reference_dir_name}"
other_target="${tmp_other_source}/not-the-reference-plugin"
non_symlink_target="${tmp_non_symlink_dir}/${reference_dir_name}"
invalid_reference_path="${tmp_invalid_reference_dir}/${reference_dir_name}"

if "$local_runner" install-reference "$tmp_plugins" >/tmp/plugin_reference_install.out 2>/tmp/plugin_reference_install.err; then
  pass "plugin-local install-reference links the reference plugin into the target directory"
else
  fail "plugin-local install-reference should succeed on an empty target directory"
  sed -n '1,120p' /tmp/plugin_reference_install.err >&2
fi

if [[ -L "$reference_path" && -f "$reference_path/manifest.json" ]]; then
  pass "reference plugin link points to a plugin manifest"
else
  fail "reference plugin manifest is not present after install-reference"
fi

if "$local_runner" install-reference "$tmp_plugins" >/tmp/plugin_reference_install_idempotent.out 2>/tmp/plugin_reference_install_idempotent.err; then
  pass "plugin-local install-reference is idempotent for the same linked reference plugin"
else
  fail "plugin-local install-reference should allow reinstalling the same reference symlink target"
  sed -n '1,120p' /tmp/plugin_reference_install_idempotent.err >&2
fi

mkdir -p "$other_target"
ln -s "$other_target" "$non_symlink_target"
if "$local_runner" install-reference "$tmp_non_symlink_dir" >/tmp/plugin_reference_install_wrong_symlink.out 2>/tmp/plugin_reference_install_wrong_symlink.err; then
  fail "plugin-local install-reference should refuse replacing a symlink that points somewhere else"
else
  if rg -q 'Refusing to replace symlink with different target' /tmp/plugin_reference_install_wrong_symlink.err; then
    pass "plugin-local install-reference refuses replacing a mismatched symlink target"
  else
    fail "plugin-local install-reference returned the wrong error for a mismatched symlink target"
    sed -n '1,120p' /tmp/plugin_reference_install_wrong_symlink.err >&2
  fi
fi
rm "$non_symlink_target"

mkdir -p "$non_symlink_target"
if "$local_runner" install-reference "$tmp_non_symlink_dir" >/tmp/plugin_reference_install_existing_dir.out 2>/tmp/plugin_reference_install_existing_dir.err; then
  fail "plugin-local install-reference should refuse overwriting an existing non-symlink path"
else
  if rg -q 'Refusing to overwrite non-symlink path' /tmp/plugin_reference_install_existing_dir.err; then
    pass "plugin-local install-reference refuses overwriting an existing non-symlink path"
  else
    fail "plugin-local install-reference returned the wrong error for an existing non-symlink path"
    sed -n '1,120p' /tmp/plugin_reference_install_existing_dir.err >&2
  fi
fi
rm -rf "$non_symlink_target"

if "$local_runner" smoke-reference "$tmp_plugins" >/tmp/plugin_reference_smoke.out 2>/tmp/plugin_reference_smoke.err; then
  pass "plugin-local smoke-reference validates the installed reference plugin"
else
  fail "plugin-local smoke-reference should pass for the installed reference plugin"
  sed -n '1,120p' /tmp/plugin_reference_smoke.err >&2
fi

if "$local_runner" smoke-reference "$tmp_invalid_reference_dir" >/tmp/plugin_reference_smoke_missing.out 2>/tmp/plugin_reference_smoke_missing.err; then
  fail "plugin-local smoke-reference should fail when the reference plugin manifest is absent"
else
  if rg -q 'Reference plugin manifest not found' /tmp/plugin_reference_smoke_missing.err; then
    pass "plugin-local smoke-reference fails cleanly when the reference plugin manifest is absent"
  else
    fail "plugin-local smoke-reference returned the wrong error for an absent reference plugin manifest"
    sed -n '1,120p' /tmp/plugin_reference_smoke_missing.err >&2
  fi
fi

mkdir -p "$invalid_reference_path"
cat > "${invalid_reference_path}/manifest.json" <<'EOF'
{
  "id": "not.reference.local.toolkit",
  "name": "Wrong Reference",
  "description": "Invalid local smoke fixture",
  "author": "tests",
  "version": "1.0.0",
  "type": "bar-widget",
  "entryPoints": {
    "barWidget": "BarWidget.qml"
  }
}
EOF
if "$local_runner" smoke-reference "$tmp_invalid_reference_dir" >/tmp/plugin_reference_smoke_wrong_id.out 2>/tmp/plugin_reference_smoke_wrong_id.err; then
  fail "plugin-local smoke-reference should fail when the installed manifest id is not the reference plugin id"
else
  if rg -q 'Reference plugin manifest has unexpected id' /tmp/plugin_reference_smoke_wrong_id.err; then
    pass "plugin-local smoke-reference fails cleanly when the installed manifest id is wrong"
  else
    fail "plugin-local smoke-reference returned the wrong error for an unexpected manifest id"
    sed -n '1,120p' /tmp/plugin_reference_smoke_wrong_id.err >&2
  fi
fi
rm -rf "$invalid_reference_path"

if "$local_runner" remove-reference "$tmp_plugins" >/tmp/plugin_reference_remove.out 2>/tmp/plugin_reference_remove.err; then
  pass "plugin-local remove-reference removes the linked reference plugin"
else
  fail "plugin-local remove-reference should remove the linked reference plugin"
  sed -n '1,120p' /tmp/plugin_reference_remove.err >&2
fi

if [[ ! -e "$reference_path" ]]; then
  pass "reference plugin path is absent after remove-reference"
else
  fail "reference plugin path still exists after remove-reference"
fi

if "$local_runner" remove-reference "$tmp_plugins" >/tmp/plugin_reference_remove_missing.out 2>/tmp/plugin_reference_remove_missing.err; then
  pass "plugin-local remove-reference is safe when the reference plugin is already absent"
else
  fail "plugin-local remove-reference should tolerate an already-absent reference plugin path"
  sed -n '1,120p' /tmp/plugin_reference_remove_missing.err >&2
fi

printf '[INFO] Plugin reference local summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))

#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_dir="${script_dir}/../src/data/bluetooth-numbers"
repo_url="https://github.com/nordicsemi/bluetooth-numbers-database.git"
branch="${1:-master}"

commit="$(git ls-remote "${repo_url}" "refs/heads/${branch}" | awk '{print $1}')"
if [[ -z "${commit}" ]]; then
  printf 'Could not resolve upstream branch: %s\n' "${branch}" >&2
  exit 1
fi

mkdir -p "${data_dir}"

base_url="https://raw.githubusercontent.com/nordicsemi/bluetooth-numbers-database/${commit}/v1"
for file in company_ids.json service_uuids.json gap_appearance.json; do
  curl -fsSL "${base_url}/${file}" -o "${data_dir}/${file}"
done

cat > "${data_dir}/SOURCE.json" <<EOF
{
  "upstream": "https://github.com/nordicsemi/bluetooth-numbers-database",
  "commit": "${commit}",
  "files": [
    "company_ids.json",
    "service_uuids.json",
    "gap_appearance.json"
  ],
  "license": "MIT"
}
EOF

printf 'Updated Bluetooth numbers snapshot to %s\n' "${commit}"

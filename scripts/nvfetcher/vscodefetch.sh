#!/usr/bin/env bash

, nvfetcher || exit 1



# The rest of your script (if you want to keep the old output)
result=$(jq '.[] | select(.passthru != null) | {name: .passthru.name, publisher: .passthru.publisher, sha256: .src.sha256, version: .version}' _sources/generated.json)
formatted_result=$(echo "$result" | sed -e 's/"name"/name/' -e 's/"publisher"/publisher/' -e 's/"sha256"/sha256/' -e 's/"version"/version/' -e 's/: / = /g' -e 's/,/;/g')
formatted_result=$(echo "$formatted_result" | sed -e 's/\([^;]\)"$/\1";/')
echo "$formatted_result"
echo "$formatted_result" > generated-vscode-nix.txt


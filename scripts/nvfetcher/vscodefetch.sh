#!/usr/bin/env bash

, nvfetcher || exit 1
result=$(jq '.[] | select(.passthru != null) | {name: .passthru.name, publisher: .passthru.publisher, sha256: .src.sha256, version: .version}' _sources/generated.json)

formatted_result=$(echo "$result" | sed -e 's/"name"/name/' -e 's/"publisher"/publisher/' -e 's/"sha256"/sha256/' -e 's/"version"/version/' -e 's/: / = /g' -e 's/,/;/g')
# Add a semicolon to lines ending with " but not already having a ;
formatted_result=$(echo "$formatted_result" | sed -e 's/\([^;]\)"$/\1";/')
echo "$formatted_result"
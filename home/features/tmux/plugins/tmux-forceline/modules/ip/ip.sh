#! /usr/bin/env bash

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is not installed." >&2
  exit 1
fi

# Check if jq is installed and set has_jq accordingly
if command -v jq >/dev/null 2>&1; then
  has_jq=true
else
  has_jq=false
fi

# Fetch JSON data from ipinfo.io
if ! json_data=$(curl --max-time 2 -s -f -H "Accept: application/json" ipinfo.io); then
  echo "Error: Failed to fetch data from ipinfo.io using curl." >&2
  exit 1
fi

# Parse JSON data and set environment variables
if [ "$has_jq" = true ]; then
  forceline_ipwan=$(echo "$json_data" | jq -r '.ip')
  forceline_city=$(echo "$json_data" | jq -r '.city')
  forceline_region=$(echo "$json_data" | jq -r '.region')
  forceline_country=$(echo "$json_data" | jq -r '.country')
  forceline_loc=$(echo "$json_data" | jq -r '.loc')
  forceline_postal=$(echo "$json_data" | jq -r '.postal')
  forceline_timezone=$(echo "$json_data" | jq -r '.timezone')
else
  # Use awk to parse JSON data if jq is not available
  forceline_ipwan=$(echo "$json_data" | awk -F'"' '/"ip":/ {print $4}')
  forceline_city=$(echo "$json_data" | awk -F'"' '/"city":/ {print $4}')
  forceline_region=$(echo "$json_data" | awk -F'"' '/"region":/ {print $4}')
  forceline_country=$(echo "$json_data" | awk -F'"' '/"country":/ {print $4}')
  forceline_loc=$(echo "$json_data" | awk -F'"' '/"loc":/ {print $4}')
  forceline_postal=$(echo "$json_data" | awk -F'"' '/"postal":/ {print $4}')
  forceline_timezone=$(echo "$json_data" | awk -F'"' '/"timezone":/ {print $4}')
fi

# Export variables (optional)
export forceline_ipwan
export forceline_city
export forceline_region
export forceline_country
export forceline_loc
export forceline_postal
export forceline_timezone

# Output the variables
echo "IP: $forceline_ipwan"
echo "City: $forceline_city"
echo "Region: $forceline_region"
echo "Country: $forceline_country"
echo "Location: $forceline_loc"
echo "Postal Code: $forceline_postal"
echo "Timezone: $forceline_timezone"
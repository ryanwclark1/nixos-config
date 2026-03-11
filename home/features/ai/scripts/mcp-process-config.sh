#!/usr/bin/env bash

# MCP Configuration Processor
# Processes MCP JSON template to resolve variables and SOPS secrets

set -euo pipefail

SOURCE_CONFIG="${HOME}/.config/open-webui/mcp-servers.json"
OUTPUT_CONFIG="${HOME}/.config/open-webui/mcp-servers-processed.json"

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v jq >/dev/null 2>&1; then
        missing+=("jq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        exit 1
    fi
}

# Ensure source config exists
check_source_config() {
    if [[ ! -f "$SOURCE_CONFIG" ]]; then
        echo "Error: Source MCP configuration not found at $SOURCE_CONFIG" >&2
        exit 1
    fi
}

# Main processing function
process_config() {
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$OUTPUT_CONFIG")"

    # Read the JSON template
    local template_json
    template_json=$(cat "$SOURCE_CONFIG" 2>/dev/null) || {
        echo "Error: Failed to read source configuration" >&2
        return 1
    }

    echo "Processing MCP configuration..."

    # Replace {{HOME}} with actual home directory
    echo "  Resolving HOME directory..."
    local processed_json
    processed_json=$(echo "$template_json" | sed "s|{{HOME}}|${HOME}|g")

    # Process SOPS secrets
    echo "  Resolving SOPS secrets..."
    while IFS= read -r line; do
        if [[ $line =~ \{\{SOPS:([^}]+)\}\} ]]; then
            local secret_key="${BASH_REMATCH[1]}"
            local secret_value=""

            echo "    Processing secret: $secret_key"

            # Try to read from various SOPS locations
            local sops_paths=(
                "/run/secrets/${secret_key}"
                "/run/secrets/${secret_key/\//-}"  # Replace / with -
                "/var/lib/sops-nix/secrets/${secret_key}"
                "/var/lib/sops-nix/secrets/${secret_key/\//-}"
                "${HOME}/.config/sops/secrets/${secret_key}"
            )

            for path in "${sops_paths[@]}"; do
                if [[ -f "$path" && -r "$path" ]]; then
                    secret_value=$(cat "$path" 2>/dev/null || echo "")
                    if [[ -n "$secret_value" ]]; then
                        echo "      Found at: $path"
                        break
                    fi
                fi
            done

            if [[ -z "$secret_value" ]]; then
                echo "      Warning: Could not read SOPS secret '$secret_key'" >&2
                echo "      Checked paths:"
                printf "        %s\n" "${sops_paths[@]}"
                secret_value="MISSING_SECRET_${secret_key}"
            fi

            processed_json=$(echo "$processed_json" | sed "s|{{SOPS:${secret_key}}}|${secret_value}|g")
        fi
    done < <(echo "$processed_json" | grep -o '{{SOPS:[^}]*}}' || true)

    # Write the processed configuration
    echo "$processed_json" > "$OUTPUT_CONFIG" || {
        echo "Error: Failed to write processed configuration" >&2
        return 1
    }

    # Validate JSON
    if ! jq . "$OUTPUT_CONFIG" >/dev/null 2>&1; then
        echo "Error: Generated JSON is invalid" >&2
        echo "Please check the source configuration for errors" >&2
        return 1
    fi

    echo "MCP configuration processed successfully:"
    echo "  Source: $SOURCE_CONFIG"
    echo "  Output: $OUTPUT_CONFIG"

    # Show summary of servers
    echo ""
    echo "Available MCP servers:"
    jq -r 'keys[]' "$OUTPUT_CONFIG" 2>/dev/null | while read -r server; do
        if [[ -n "$server" ]]; then
            local desc
            desc=$(jq -r ".\"$server\".description" "$OUTPUT_CONFIG" 2>/dev/null || echo "No description")
            echo "  $server: $desc"
        fi
    done

    echo ""
    echo "Configuration ready for MCP-enabled CLI tools!"
}

# Main execution
main() {
    check_dependencies
    check_source_config
    process_config
}

main "$@"

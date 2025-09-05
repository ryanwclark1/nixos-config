#!/usr/bin/env bash

# MCP CLI Launcher
# Launches CLI tools with MCP server integration
# Supports: aider, codex, crush, goose-cli, claude-code, qwen-code, gemini-cli

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_CONFIG_FILE="${HOME}/.config/open-webui/mcp-servers.json"
MCP_PROCESSED_CONFIG="/tmp/mcp-servers-processed.json"

# Check if MCP config exists
if [ ! -f "$MCP_CONFIG_FILE" ]; then
    echo "Error: MCP configuration not found at $MCP_CONFIG_FILE"
    exit 1
fi

# Process MCP config to resolve variables
process_mcp_config() {
    local input_file="$1"
    local output_file="$2"
    
    # Read the JSON and replace template variables
    local processed_json
    processed_json=$(cat "$input_file")
    
    # Replace {{HOME}} with actual home directory
    processed_json=$(echo "$processed_json" | sed "s|{{HOME}}|${HOME}|g")
    
    # Process SOPS secrets
    while IFS= read -r line; do
        if [[ $line =~ \{\{SOPS:([^}]+)\}\} ]]; then
            local secret_key="${BASH_REMATCH[1]}"
            local secret_value=""
            
            # Try to read from various SOPS locations
            local sops_paths=(
                "/run/secrets/${secret_key}"
                "/run/secrets/${secret_key/\//-}"  # Replace / with -
                "/var/lib/sops-nix/secrets/${secret_key}"
                "/var/lib/sops-nix/secrets/${secret_key/\//-}"
            )
            
            for path in "${sops_paths[@]}"; do
                if [ -f "$path" ] && [ -r "$path" ]; then
                    secret_value=$(cat "$path" 2>/dev/null || echo "")
                    break
                fi
            done
            
            if [ -z "$secret_value" ]; then
                echo "Warning: Could not read SOPS secret '$secret_key'" >&2
                secret_value="MISSING_SECRET_${secret_key}"
            fi
            
            processed_json=$(echo "$processed_json" | sed "s|{{SOPS:${secret_key}}}|${secret_value}|g")
        fi
    done < <(echo "$processed_json" | grep -o '{{SOPS:[^}]*}}' || true)
    
    echo "$processed_json" > "$output_file"
}

# Get available MCP servers
get_mcp_servers() {
    if [ ! -f "$MCP_PROCESSED_CONFIG" ]; then
        process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
    fi
    
    jq -r 'keys[]' "$MCP_PROCESSED_CONFIG" 2>/dev/null || echo ""
}

# Launch MCP server
launch_mcp_server() {
    local server_name="$1"
    
    if [ ! -f "$MCP_PROCESSED_CONFIG" ]; then
        process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
    fi
    
    local server_config
    server_config=$(jq ".\"$server_name\"" "$MCP_PROCESSED_CONFIG" 2>/dev/null)
    
    if [ "$server_config" = "null" ] || [ -z "$server_config" ]; then
        echo "Error: MCP server '$server_name' not found" >&2
        return 1
    fi
    
    local command args env_vars
    command=$(echo "$server_config" | jq -r '.command')
    args=$(echo "$server_config" | jq -r '.args[]?' | tr '\n' ' ')
    
    # Set environment variables if specified
    if echo "$server_config" | jq -e '.env' > /dev/null 2>&1; then
        while IFS= read -r line; do
            export "$line"
        done < <(echo "$server_config" | jq -r '.env | to_entries[] | "\(.key)=\(.value)"')
    fi
    
    # Launch the server
    exec $command $args
}

# CLI tool integration functions
launch_aider() {
    local servers="$1"
    if command -v aider >/dev/null 2>&1; then
        # Aider supports MCP via --mcp flag
        aider --mcp "$MCP_PROCESSED_CONFIG" "$@"
    else
        echo "Error: aider not found in PATH" >&2
        return 1
    fi
}

launch_claude_code() {
    local servers="$1"
    # Claude Code supports MCP through configuration
    if command -v claude-code >/dev/null 2>&1; then
        # Set MCP config environment variable
        export MCP_CONFIG_FILE="$MCP_PROCESSED_CONFIG"
        claude-code "$@"
    else
        echo "Error: claude-code not found in PATH" >&2
        return 1
    fi
}

launch_codex() {
    local servers="$1"
    if command -v codex >/dev/null 2>&1; then
        # Codex may support MCP through config file
        export MCP_SERVERS_CONFIG="$MCP_PROCESSED_CONFIG"
        codex "$@"
    else
        echo "Error: codex not found in PATH" >&2
        return 1
    fi
}

launch_crush() {
    local servers="$1"
    if command -v crush >/dev/null 2>&1; then
        # Crush MCP integration
        export MCP_CONFIG="$MCP_PROCESSED_CONFIG"
        crush "$@"
    else
        echo "Error: crush not found in PATH" >&2
        return 1
    fi
}

launch_goose_cli() {
    local servers="$1"
    if command -v goose >/dev/null 2>&1; then
        # Goose CLI MCP integration
        goose --mcp-config "$MCP_PROCESSED_CONFIG" "$@"
    else
        echo "Error: goose not found in PATH" >&2
        return 1
    fi
}

launch_qwen_code() {
    local servers="$1"
    if command -v qwen-code >/dev/null 2>&1; then
        # Qwen Code MCP integration
        export QWEN_MCP_CONFIG="$MCP_PROCESSED_CONFIG"
        qwen-code "$@"
    else
        echo "Error: qwen-code not found in PATH" >&2
        return 1
    fi
}

launch_gemini_cli() {
    local servers="$1"
    if command -v gemini-cli >/dev/null 2>&1; then
        # Gemini CLI MCP integration
        gemini-cli --mcp "$MCP_PROCESSED_CONFIG" "$@"
    else
        echo "Error: gemini-cli not found in PATH" >&2
        return 1
    fi
}

# Usage function
usage() {
    cat << EOF
MCP CLI Launcher - Launch CLI tools with MCP server integration

Usage: $(basename "$0") <command> [options...]

Commands:
  server <name>     Launch a specific MCP server
  list              List available MCP servers
  aider             Launch Aider with MCP support
  claude-code       Launch Claude Code with MCP support
  codex             Launch Codex with MCP support
  crush             Launch Crush with MCP support
  goose             Launch Goose CLI with MCP support
  qwen-code         Launch Qwen Code with MCP support
  gemini-cli        Launch Gemini CLI with MCP support

Examples:
  $(basename "$0") list
  $(basename "$0") server github
  $(basename "$0") aider --model gpt-4
  $(basename "$0") claude-code /path/to/project

Available MCP Servers:
$(get_mcp_servers | sed 's/^/  /')
EOF
}

# Main function
main() {
    local command="${1:-}"
    
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi
    
    shift
    
    case "$command" in
        "server")
            if [ $# -eq 0 ]; then
                echo "Error: Server name required" >&2
                usage
                exit 1
            fi
            launch_mcp_server "$1"
            ;;
        "list")
            echo "Available MCP Servers:"
            get_mcp_servers | while read -r server; do
                if [ -n "$server" ]; then
                    local desc
                    desc=$(jq -r ".\"$server\".description" "$MCP_CONFIG_FILE" 2>/dev/null || echo "No description")
                    echo "  $server: $desc"
                fi
            done
            ;;
        "aider")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_aider "" "$@"
            ;;
        "claude-code")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_claude_code "" "$@"
            ;;
        "codex")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_codex "" "$@"
            ;;
        "crush")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_crush "" "$@"
            ;;
        "goose")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_goose_cli "" "$@"
            ;;
        "qwen-code")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_qwen_code "" "$@"
            ;;
        "gemini-cli")
            process_mcp_config "$MCP_CONFIG_FILE" "$MCP_PROCESSED_CONFIG"
            launch_gemini_cli "" "$@"
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
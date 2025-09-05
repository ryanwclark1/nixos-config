#!/usr/bin/env bash

# Qwen Code Environment Manager
# Manage .qwen/.env files for projects and global settings

set -euo pipefail

GLOBAL_ENV_FILE="$HOME/.qwen/.env"
TEMPLATE_FILE="$HOME/.config/qwen/project-env-template"

usage() {
    cat << EOF
Qwen Code Environment Manager

Usage: $(basename "$0") <command> [options]

Commands:
  init [directory]     Initialize .qwen/.env in project directory (default: current)
  global              Show global Qwen Code environment settings
  check [directory]   Check which .env file Qwen Code would use (default: current)
  edit                Edit global .qwen/.env file
  template            Show project template
  test                Test Ollama connection with current settings
  status              Show Ollama and model status

Examples:
  $(basename "$0") init                    # Create .qwen/.env in current directory
  $(basename "$0") init /path/to/project   # Create .qwen/.env in specific directory
  $(basename "$0") check                   # Show which .env file would be used
  $(basename "$0") test                    # Test Ollama connection

Environment Variable Search Order (Qwen Code behavior):
  Starting from current directory, moving up to /:
    1. .qwen/.env
    2. .env
  Fallback to home directory:
    3. ~/.qwen/.env
    4. ~/.env
EOF
}

# Find which .env file Qwen Code would use (mimicking qwen-code behavior)
find_env_file() {
    local start_dir="${1:-$(pwd)}"
    local current_dir="$start_dir"
    
    # Search upward from current directory
    while [[ "$current_dir" != "/" ]]; do
        # Check .qwen/.env first
        if [[ -f "$current_dir/.qwen/.env" ]]; then
            echo "$current_dir/.qwen/.env"
            return 0
        fi
        
        # Check .env second  
        if [[ -f "$current_dir/.env" ]]; then
            echo "$current_dir/.env"
            return 0
        fi
        
        current_dir=$(dirname "$current_dir")
    done
    
    # Fallback to home directory
    if [[ -f "$HOME/.qwen/.env" ]]; then
        echo "$HOME/.qwen/.env"
        return 0
    fi
    
    if [[ -f "$HOME/.env" ]]; then
        echo "$HOME/.env" 
        return 0
    fi
    
    echo "No .env file found"
    return 1
}

# Initialize project .env file
init_project_env() {
    local target_dir="${1:-$(pwd)}"
    local env_file="$target_dir/.qwen/.env"
    
    echo "Initializing Qwen Code environment in: $target_dir"
    
    # Create .qwen directory
    mkdir -p "$target_dir/.qwen"
    
    if [[ -f "$env_file" ]]; then
        echo "Warning: $env_file already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            return 1
        fi
    fi
    
    # Copy template if available, otherwise create basic file
    if [[ -f "$TEMPLATE_FILE" ]]; then
        cp "$TEMPLATE_FILE" "$env_file"
        echo "Created $env_file from template"
    else
        cat > "$env_file" << 'EOF'
# Project-specific Qwen Code Configuration
# This overrides global settings in ~/.qwen/.env

# Model settings (inherits from global if not set)
# MODEL=hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL

# Project-specific preferences
QWEN_CODE_STYLE=detailed
QWEN_EXPLAIN_LEVEL=verbose
MAX_TOKENS=12288
TEMPERATURE=0.05

# MCP integration (inherits from global if not set)
# MCP_CONFIG_FILE=./project-mcp-servers.json
EOF
        echo "Created basic $env_file"
    fi
    
    echo "Edit the file to customize settings for this project"
}

# Show global environment settings
show_global_env() {
    if [[ -f "$GLOBAL_ENV_FILE" ]]; then
        echo "Global Qwen Code environment ($GLOBAL_ENV_FILE):"
        echo "================================================="
        cat "$GLOBAL_ENV_FILE"
    else
        echo "No global Qwen Code environment file found at $GLOBAL_ENV_FILE"
        echo "This will be created by your Nix configuration on next rebuild"
    fi
}

# Check which env file would be used
check_env_file() {
    local start_dir="${1:-$(pwd)}"
    local env_file
    
    echo "Checking environment file resolution from: $start_dir"
    echo "Search order (Qwen Code behavior):"
    
    local current_dir="$start_dir"
    local search_paths=()
    
    # Build search path list
    while [[ "$current_dir" != "/" ]]; do
        search_paths+=("$current_dir/.qwen/.env")
        search_paths+=("$current_dir/.env")
        current_dir=$(dirname "$current_dir")
    done
    
    search_paths+=("$HOME/.qwen/.env")
    search_paths+=("$HOME/.env")
    
    # Show search order and find first match
    local found_file=""
    for i in "${!search_paths[@]}"; do
        local path="${search_paths[$i]}"
        if [[ -f "$path" ]]; then
            if [[ -z "$found_file" ]]; then
                echo "$((i+1)). $path ✓ (WOULD BE USED)"
                found_file="$path"
            else
                echo "$((i+1)). $path ✓ (ignored)"
            fi
        else
            echo "$((i+1)). $path ✗ (not found)"
        fi
    done
    
    if [[ -n "$found_file" ]]; then
        echo ""
        echo "Qwen Code would use: $found_file"
        return 0
    else
        echo ""
        echo "No .env file found - Qwen Code will use defaults"
        return 1
    fi
}

# Test Ollama connection
test_ollama_connection() {
    local env_file
    env_file=$(find_env_file) || {
        echo "No .env file found, testing with defaults"
    }
    
    if [[ -n "$env_file" && "$env_file" != "No .env file found" ]]; then
        echo "Loading environment from: $env_file"
        set -a
        source "$env_file"
        set +a
    fi
    
    local base_url="${OPENAI_BASE_URL:-http://localhost:11434/v1}"
    local model="${MODEL:-hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL}"
    
    echo "Testing Ollama connection..."
    echo "Base URL: $base_url"
    echo "Model: $model"
    echo ""
    
    # Test basic connection
    if curl -sf "${base_url%/v1}/api/tags" >/dev/null 2>&1; then
        echo "✓ Ollama is running and accessible"
        
        # Test if model is available
        if curl -sf "${base_url%/v1}/api/tags" | grep -q "$(echo "$model" | cut -d: -f1)"; then
            echo "✓ Model '$model' is available"
        else
            echo "✗ Model '$model' not found in Ollama"
            echo "Available models:"
            curl -sf "${base_url%/v1}/api/tags" | jq -r '.models[].name' 2>/dev/null || echo "Could not retrieve model list"
        fi
    else
        echo "✗ Ollama is not accessible at ${base_url%/v1}"
        echo "Make sure Ollama is running: ollama serve"
    fi
}

# Show Ollama and model status
show_status() {
    echo "Ollama and Qwen Code Status"
    echo "==========================="
    
    # Check if Ollama is running
    if pgrep -f "ollama serve" >/dev/null; then
        echo "✓ Ollama service is running"
    else
        echo "✗ Ollama service not detected"
    fi
    
    # Check Ollama API
    if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "✓ Ollama API accessible at http://localhost:11434"
        
        echo ""
        echo "Available models:"
        curl -sf http://localhost:11434/api/tags | jq -r '.models[] | "  \(.name) (\(.size/1024/1024/1024 | floor)GB)"' 2>/dev/null || {
            echo "  Could not retrieve model list"
        }
    else
        echo "✗ Ollama API not accessible"
    fi
    
    echo ""
    check_env_file
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        "init")
            shift
            init_project_env "$@"
            ;;
        "global")
            show_global_env
            ;;
        "check")
            shift
            check_env_file "$@"
            ;;
        "edit")
            if [[ -f "$GLOBAL_ENV_FILE" ]]; then
                ${EDITOR:-nano} "$GLOBAL_ENV_FILE"
            else
                echo "Global .env file not found at $GLOBAL_ENV_FILE"
                echo "This will be created by your Nix configuration on next rebuild"
            fi
            ;;
        "template")
            if [[ -f "$TEMPLATE_FILE" ]]; then
                cat "$TEMPLATE_FILE"
            else
                echo "Template file not found at $TEMPLATE_FILE"
            fi
            ;;
        "test")
            test_ollama_connection
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help"|"")
            usage
            ;;
        *)
            echo "Error: Unknown command '$command'" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"
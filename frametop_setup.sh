#!/usr/bin/env bash

# Enable strict error handling and logging
# -e: Exit immediately if a command fails
# -u: Treat unset variables as an error
# -o pipefail: Return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status
set -euo pipefail
# Send all script output to system logger while maintaining console output
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Error handling function to provide detailed feedback on script failures
error_handler() {
    echo "Error occurred in script at line: ${1}"
    exit 1
}
trap 'error_handler ${LINENO}' ERR

# Git repository management function
# Handles both initial clone and updates of existing repository
manage_git_repo() {
    local repo_url="https://github.com/ryanwclark1/nixos-config"
    local repo_path="/home/administrator/nixos-config"

    if [ -d "$repo_path/.git" ]; then
        echo "Repository already exists locally. Updating..."
        cd "$repo_path"
        git fetch origin
        git stash -u || true
        git reset --hard origin/main
        git clean -fd
        echo "Repository successfully updated"
    else
        echo "Cloning fresh repository..."
        git clone "$repo_url" "$repo_path"
        echo "Repository successfully cloned"
    fi
}

# Directory creation function with security settings
# Creates directories with specific permissions and ownership
create_secure_dir() {
    local dir_path="$1"
    local mode="$2"
    sudo mkdir -p "$dir_path"
    sudo chmod "$mode" "$dir_path"
    sudo chown administrator:users "$dir_path"
}

# Function for securely copying user-owned files
# Uses temporary directory to handle permissions properly
secure_copy_file() {
    local src="$1"
    local dest="$2"
    local mode="$3"
    local temp_dir="/tmp/secure_copy_$$"

    # Create temporary directory with restrictive permissions
    mkdir -p "$temp_dir"
    chmod 700 "$temp_dir"

    local filename=$(basename "$dest")
    local temp_file="$temp_dir/$filename"

    echo "Copying $src to temporary location..."
    if ! scp "administrator@10.10.100.58:$src" "$temp_file"; then
        echo "Error: SCP failed for $src"
        rm -rf "$temp_dir"
        return 1
    fi

    echo "Moving $filename to final destination with proper permissions..."
    sudo mv "$temp_file" "$dest"
    sudo chmod "$mode" "$dest"
    sudo chown administrator:users "$dest"

    rm -rf "$temp_dir"
}

# Function for securely copying system SSH host keys
# Handles root-owned system files specifically
secure_copy_system_key() {
    local src="$1"
    local dest="$2"
    local mode="$3"
    local temp_dir="/tmp/secure_copy_$$"

    # Create temporary directory with restrictive permissions
    mkdir -p "$temp_dir"
    chmod 700 "$temp_dir"

    local filename=$(basename "$dest")
    local temp_file="$temp_dir/$filename"

    echo "Copying system SSH key $src to temporary location..."
    if ! scp "administrator@10.10.100.58:$src" "$temp_file"; then
        echo "Error: SCP failed for $src"
        rm -rf "$temp_dir"
        return 1
    fi

    echo "Moving $filename to final destination with root ownership..."
    sudo mv "$temp_file" "$dest"
    sudo chmod "$mode" "$dest"
    sudo chown root:root "$dest"

    rm -rf "$temp_dir"
}

# Log script start with timestamp
echo "Starting NixOS configuration setup at $(date)"

# Initialize git repository through nix-shell
echo "Setting up git environment and managing repository..."
nix-shell -p git gnumake --run "$(declare -f manage_git_repo); manage_git_repo"

# Create necessary directory structure
echo "Creating required directories..."
create_secure_dir "/home/administrator/nixos-config/host/frametop" 755
create_secure_dir "/home/administrator/.ssh" 700
create_secure_dir "/home/administrator/.config/sops/age" 700

# Copy and configure hardware configuration
echo "Copying hardware configuration..."
sudo cp /etc/nixos/hardware-configuration.nix "/home/administrator/nixos-config/host/frametop/hardware-configuration.nix"
sudo chown administrator:users "/home/administrator/nixos-config/host/frametop/hardware-configuration.nix"

# Copy and set up security credentials
echo "Copying security credentials..."
# User SSH keys
secure_copy_file "/home/administrator/.ssh/ssh_host_ed25519_key.pub" \
    "/home/administrator/.ssh/ssh_host_ed25519_key.pub" 644
secure_copy_file "/home/administrator/.ssh/ssh_host_ed25519_key" \
    "/home/administrator/.ssh/ssh_host_ed25519_key" 600

# System SSH host keys with root ownership
echo "Copying system SSH host keys..."
secure_copy_system_key "/etc/ssh/ssh_host_ed25519_key" \
    "/etc/ssh/ssh_host_ed25519_key" 600
secure_copy_system_key "/etc/ssh/ssh_host_ed25519_key.pub" \
    "/etc/ssh/ssh_host_ed25519_key.pub" 644

# SOPS age key
secure_copy_file "/home/administrator/.config/sops/age/keys.txt" \
    "/home/administrator/.config/sops/age/keys.txt" 600

# Manage system services
echo "Managing systemd services..."
for action in "stop" "disable"; do
    sudo systemctl $action efi.automount || echo "Warning: Failed to $action efi.automount service"
done
sudo systemctl daemon-reload || echo "Warning: Failed to reload systemd daemon"

# Create temporary files for build output and errors
BUILD_LOG=$(mktemp)
ERROR_LOG=$(mktemp)
trap 'rm -f $BUILD_LOG $ERROR_LOG' EXIT

# Rebuild NixOS configuration with comprehensive error capturing
echo "Rebuilding NixOS configuration..."
echo "Starting build at $(date)" > "$BUILD_LOG"

# Run nixos-rebuild with error handling
if sudo nixos-rebuild test --flake /home/administrator/nixos-config#frametop > >(tee -a "$BUILD_LOG") 2> >(tee -a "$ERROR_LOG" >&2); then
    echo "Configuration build successful at $(date)"
    echo "Summary of changes:"
    grep -E "^(building|installing|activating)" "$BUILD_LOG" || true

    if [ -s "$ERROR_LOG" ]; then
        echo "Warnings during build:"
        cat "$ERROR_LOG"
    fi
else
    echo "Configuration build failed at $(date)"
    echo "=== Full Build Log ==="
    cat "$BUILD_LOG"
    echo "=== Full Error Log ==="
    cat "$ERROR_LOG"
    echo "=== End of Logs ==="

    # Archive logs for later inspection
    sudo cp "$BUILD_LOG" "/var/log/nixos-rebuild-build-$(date +%Y%m%d_%H%M%S).log"
    sudo cp "$ERROR_LOG" "/var/log/nixos-rebuild-error-$(date +%Y%m%d_%H%M%S).log"
    echo "Build and error logs have been archived to /var/log/"
    exit 1
fi

# Generate and display password hash
echo "Generating password hash..."
PASSWORD_HASH=$(echo "password" | mkpasswd -s) || {
    echo "Error: Failed to generate password hash"
    exit 1
}
echo "Password hash: $PASSWORD_HASH"

# Log script completion
echo "NixOS configuration setup completed successfully at $(date)"
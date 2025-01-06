#!/usr/bin/env bash

# Enable strict error handling and logging
set -euo pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Function to handle errors and provide detailed feedback
error_handler() {
    echo "Error occurred in script at line: ${1}"
    exit 1
}
trap 'error_handler ${LINENO}' ERR

# Function to manage the git repository
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

# Function to create directory with specific permissions and ownership
create_secure_dir() {
    local dir_path="$1"
    local mode="$2"
    sudo mkdir -p "$dir_path"
    sudo chmod "$mode" "$dir_path"
    sudo chown administrator "$dir_path"
}

# Function to securely copy and set permissions for files
secure_copy_file() {
    local src="$1"
    local dest="$2"
    local mode="$3"

    scp "administrator@10.10.100.58:$src" "$dest"
    sudo chmod "$mode" "$dest"
    sudo chown administrator "$dest"
}

# Log script start with timestamp
echo "Starting NixOS configuration setup at $(date)"

# Create a temporary nix shell environment for git operations
echo "Setting up git environment and managing repository..."
nix-shell -p git gnumake --run "$(declare -f manage_git_repo); manage_git_repo"

# Create directory structure with appropriate permissions
echo "Creating required directories..."
create_secure_dir "/home/administrator/nixos-config/host/frametop" 755
create_secure_dir "/home/administrator/.ssh" 700
create_secure_dir "/home/administrator/.config/sops/age" 700

# Copy hardware configuration
echo "Copying hardware configuration..."
sudo cp /etc/nixos/hardware-configuration.nix "/home/administrator/nixos-config/host/frametop/hardware-configuration.nix"
sudo chown administrator "/home/administrator/nixos-config/host/frametop/hardware-configuration.nix"

# Copy security credentials with proper permissions
echo "Copying security credentials..."
secure_copy_file "/home/administrator/.ssh/ssh_host_ed25519_key.pub" \
    "/home/administrator/.ssh/ssh_host_ed25519_key.pub" 644
secure_copy_file "/home/administrator/.ssh/ssh_host_ed25519_key" \
    "/home/administrator/.ssh/ssh_host_ed25519_key" 600
secure_copy_file "/home/administrator/.config/sops/age/keys.txt" \
    "/home/administrator/.config/sops/age/keys.txt" 600

# Manage system services
echo "Managing systemd services..."
for action in "stop" "disable"; do
    sudo systemctl $action efi.automount || echo "Warning: Failed to $action efi.automount service"
done
sudo systemctl daemon-reload || echo "Warning: Failed to reload systemd daemon"

# Rebuild NixOS configuration
echo "Rebuilding NixOS configuration..."
sudo nixos-rebuild test --flake /home/administrator/nixos-config#frametop

# Generate password hash
echo "Generating password hash..."
PASSWORD_HASH=$(echo "password" | mkpasswd -s) || {
    echo "Error: Failed to generate password hash"
    exit 1
}
echo "Password hash: $PASSWORD_HASH"

# Log script completion
echo "NixOS configuration setup completed successfully at $(date)"
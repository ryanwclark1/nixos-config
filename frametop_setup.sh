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

# Log script start with timestamp
echo "Starting NixOS configuration setup at $(date)"

# Create a temporary nix shell environment for git operations
# We isolate git operations to minimize global environment changes
echo "Setting up git environment and cloning configuration..."
nix-shell -p git gnumake --run '
    git clone https://github.com/ryanwclark1/nixos-config ~/nixos-config
'

# Create necessary directories with appropriate permissions
echo "Creating required directories..."
mkdir -p ~/nixos-config/host/frametop
mkdir -p ~/.ssh
mkdir -p ~/.config/sops/age

# Set restrictive permissions for sensitive directories
chmod 700 ~/.ssh
chmod 700 ~/.config/sops
chmod 700 ~/.config/sops/age

# Copy hardware configuration with root privileges
echo "Copying hardware configuration..."
sudo cp /etc/nixos/hardware-configuration.nix ~/nixos-config/host/frametop/hardware-configuration.nix

# Securely copy SSH keys and SOPS age key with proper permissions
echo "Copying security credentials..."
scp administrator@10.10.100.58:~/.ssh/ssh_host_ed25519_key.pub ~/.ssh/ssh_host_ed25519_key.pub
scp administrator@10.10.100.58:~/.ssh/ssh_host_ed25519_key ~/.ssh/ssh_host_ed25519_key
scp administrator@10.10.100.58:~/.config/sops/age/keys.txt ~/.config/sops/age/keys.txt

# Set appropriate permissions for security files
echo "Setting secure file permissions..."
chmod 600 ~/.ssh/ssh_host_ed25519_key      # Private key requires strict permissions
chmod 644 ~/.ssh/ssh_host_ed25519_key.pub  # Public key can be readable
chmod 600 ~/.config/sops/age/keys.txt      # Age key requires strict permissions

# Manage system services with proper error handling
echo "Managing systemd services..."
sudo systemctl stop efi.automount || {
    echo "Warning: Failed to stop efi.automount service"
}
sudo systemctl disable efi.automount || {
    echo "Warning: Failed to disable efi.automount service"
}
sudo systemctl daemon-reload || {
    echo "Warning: Failed to reload systemd daemon"
}

# Rebuild NixOS configuration
echo "Rebuilding NixOS configuration..."
sudo nixos-rebuild test --flake ~/nixos-config#frametop

# Set up administrator credentials with proper permissions
echo "Configuring administrator security settings..."
sudo mkdir -p /home/administrator/.ssh
sudo mkdir -p /home/administrator/.config/sops/age

# Copy security files to administrator's home
sudo cp -r ~/.ssh/* /home/administrator/.ssh/
sudo cp -r ~/.config/sops/age/keys.txt /home/administrator/.config/sops/age/

# Set proper ownership and permissions for administrator files
sudo chown -R administrator:administrator /home/administrator/.ssh
sudo chown -R administrator:administrator /home/administrator/.config
sudo chmod 700 /home/administrator/.ssh
sudo chmod 700 /home/administrator/.config/sops
sudo chmod 700 /home/administrator/.config/sops/age
sudo chmod 600 /home/administrator/.ssh/ssh_host_ed25519_key
sudo chmod 644 /home/administrator/.ssh/ssh_host_ed25519_key.pub
sudo chmod 600 /home/administrator/.config/sops/age/keys.txt

# Generate password hash with error handling
echo "Generating password hash..."
PASSWORD_HASH=$(echo "password" | mkpasswd -s) || {
    echo "Error: Failed to generate password hash"
    exit 1
}
echo "Password hash: $PASSWORD_HASH"

# Log script completion with timestamp
echo "NixOS configuration setup completed successfully at $(date)"
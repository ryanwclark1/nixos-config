#!/usr/bin/env bash

# WireGuard Endpoint Setup Script for NixOS
# This script helps configure the WireGuard endpoint for woody

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}WireGuard Endpoint Setup for woody (NixOS)${NC}"

# Check if secrets file exists
SECRETS_FILE="secrets/secrets.yaml"
if [ ! -f "$SECRETS_FILE" ]; then
    echo -e "${RED}Error: Secrets file not found at $SECRETS_FILE${NC}"
    echo -e "${YELLOW}Please create the secrets file first.${NC}"
    exit 1
fi

echo -e "${YELLOW}Current WireGuard configuration:${NC}"
echo -e "Interface: wg0"
echo -e "Client IP: 10.11.11.17/32"
echo -e "Listen Port: 51820"
echo -e "Peer: AccentSplitTunnel"
echo -e "Public Key: zgZzw342CCMDrIjW2/sFf7ixAYR881h6LOG8hVDoclw="
echo -e "Allowed IPs: 172.22.22.0/24, 172.22.3.0/24"
echo ""

# Get endpoint from user
echo -e "${YELLOW}Please provide the WireGuard server endpoint:${NC}"
read -p "Server IP address: " SERVER_IP
read -p "Server port (default: 51820): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-51820}

ENDPOINT="$SERVER_IP:$SERVER_PORT"

echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo -e "Endpoint: $ENDPOINT"
echo -e "Client IP: 10.11.11.17/32"
echo ""

# Create configuration instructions
echo -e "${YELLOW}Configuration Instructions:${NC}"
echo -e "1. Update hosts/woody/services/wireguard.nix:"
echo -e "   Replace: endpoint = \"YOUR_SERVER_IP:51820\";"
echo -e "   With:    endpoint = \"$ENDPOINT\";"
echo ""
echo -e "2. Ensure your secrets file ($SECRETS_FILE) contains:"
echo -e "   wg-key: your_private_key_here"
echo -e "   accent-wg-server: $ENDPOINT"
echo ""
echo -e "3. Test the configuration:"
echo -e "   sudo nixos-rebuild switch"
echo -e "   sudo wg show"
echo -e "   ping 172.22.22.1"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Note: WireGuard will automatically start on boot in NixOS.${NC}"
echo -e "${YELLOW}No manual systemd service configuration is needed.${NC}"

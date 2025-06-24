#!/usr/bin/env bash

# Secure Boot Setup Script for NixOS
# This script generates the necessary keys for Secure Boot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Secure Boot for NixOS...${NC}"

# Create secure boot directory
SECUREBOOT_DIR="/etc/secureboot"
echo -e "${YELLOW}Creating secure boot directory: $SECUREBOOT_DIR${NC}"
sudo mkdir -p "$SECUREBOOT_DIR"
sudo chmod 700 "$SECUREBOOT_DIR"

# Generate keys
echo -e "${YELLOW}Generating Secure Boot keys...${NC}"

# Generate Platform Key (PK)
echo -e "${YELLOW}Generating Platform Key (PK)...${NC}"
sudo openssl req -new -x509 -newkey rsa:2048 -subj "/CN=Platform Key/" -keyout "$SECUREBOOT_DIR/PK.key" -out "$SECUREBOOT_DIR/PK.crt" -days 3650 -nodes -sha256

# Generate Key Exchange Key (KEK)
echo -e "${YELLOW}Generating Key Exchange Key (KEK)...${NC}"
sudo openssl req -new -x509 -newkey rsa:2048 -subj "/CN=Key Exchange Key/" -keyout "$SECUREBOOT_DIR/KEK.key" -out "$SECUREBOOT_DIR/KEK.crt" -days 3650 -nodes -sha256

# Generate Signature Database Key (db)
echo -e "${YELLOW}Generating Signature Database Key (db)...${NC}"
sudo openssl req -new -x509 -newkey rsa:2048 -subj "/CN=Signature Database Key/" -keyout "$SECUREBOOT_DIR/db.key" -out "$SECUREBOOT_DIR/db.crt" -days 3650 -nodes -sha256

# Generate Forbidden Signatures Database Key (dbx)
echo -e "${YELLOW}Generating Forbidden Signatures Database Key (dbx)...${NC}"
sudo openssl req -new -x509 -newkey rsa:2048 -subj "/CN=Forbidden Signatures Database Key/" -keyout "$SECUREBOOT_DIR/dbx.key" -out "$SECUREBOOT_DIR/dbx.crt" -days 3650 -nodes -sha256

# Convert certificates to DER format for UEFI
echo -e "${YELLOW}Converting certificates to DER format...${NC}"
sudo openssl x509 -in "$SECUREBOOT_DIR/PK.crt" -out "$SECUREBOOT_DIR/PK.der" -outform DER
sudo openssl x509 -in "$SECUREBOOT_DIR/KEK.crt" -out "$SECUREBOOT_DIR/KEK.der" -outform DER
sudo openssl x509 -in "$SECUREBOOT_DIR/db.crt" -out "$SECUREBOOT_DIR/db.der" -outform DER
sudo openssl x509 -in "$SECUREBOOT_DIR/dbx.crt" -out "$SECUREBOOT_DIR/dbx.der" -outform DER

# Set proper permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
sudo chmod 600 "$SECUREBOOT_DIR"/*.key
sudo chmod 644 "$SECUREBOOT_DIR"/*.crt
sudo chmod 644 "$SECUREBOOT_DIR"/*.der

echo -e "${GREEN}Secure Boot keys generated successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Enroll the keys in your UEFI firmware:"
echo -e "   - Reboot and enter UEFI settings"
echo -e "   - Find 'Secure Boot' or 'Security' section"
echo -e "   - Enroll the keys from: $SECUREBOOT_DIR"
echo -e "2. Rebuild your NixOS configuration:"
echo -e "   sudo nixos-rebuild boot"
echo -e "3. Test the setup by rebooting"

echo -e "${GREEN}Setup complete!${NC}"

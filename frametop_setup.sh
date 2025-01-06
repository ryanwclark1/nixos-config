#!/usr/bin/env bash


nix-env -iA git gnumake
git clone https://github.com/ryanwclark1/nixos-config ~/nixos-config
cp /etc/nixos/hardware-configuration.nix ~/nixos-config/host/frametop/hardware-configuration.nix

scp administrator@10.10.100.58:~/.ssh/ssh_host_ed25519_key.pub ~/.ssh/ssh_host_ed25519_key.pub
scp administrator@10.10.100.58:~/.ssh/ssh_host_ed25519_key ~/.ssh/ssh_host_ed25519_key

systemctl stop efi.automount
systemctl disable efi.automount
systemctl restart daemon-reload

nixos-rebuild test --flake ~/nixos-config#frametop

cp ~/.ssh/ /home/administrator/.ssh
echo "password" | mkpasswd -s

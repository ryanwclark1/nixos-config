#!/usr/bin/env bash


nix-shell -p git gnumake
git clone https://github.com/ryanwclark1/nixos-configs ~/nixos-configs
cp /etc/nixos/hardware-configuration.nix ~/nixos-configs/host/frametop/hardware-configuration.nix

# scp administrator@10.10.100.58:~/.ssh/id_host_rsa.pub ~/.ssh/id_host_rsa.pub
# scp administrator@10.10.100.58:~/.ssh/id_host_rsa ~/.ssh/id_host_rsa
scp administrator@10.10.100.58:~/.ssh/ssh_host_ed25519_key.pub ~/.ssh/ssh_host_ed25519_key.pub
scp administrator@10.10.100.58:~/.ssh/ssh_host_ed25519_key ~/.ssh/ssh_host_ed25519_key

systemctl stop efi.automount
systemctl disable efi.automount
systemctl restart daemon-reload

nixos-rebuild test --flake ~/nixos-configs#frametop

cp ~/.ssh/ /home/administrator/.ssh
echo "password" | mkpasswd -s

!/usr/bin/env bash


nix-env --install git gnumake
git clone https://github.com/ryanwclark1/nixos-configs.git ~/nixos-configs
cp /etc/nixos/hardware-configuration.nix ~/nixos-configs/host/frametop/hardware-configuration.nix

scp administrator@10.10.100.58:~/.ssh/id_host_rsa.pub ~/.ssh/id_host_rsa.pub
scp administrator@10.10.100.58:~/.ssh/id_host_rsa ~/.ssh/id_host_rsa
scp administrator@10.10.100.58:~/.ssh/id_host_ed25519.pub ~/.ssh/id_host_ed25519.pub
scp administrator@10.10.100.58:~/.ssh/id_host_ed25519 ~/.ssh/id_host_ed25519

systemctl stop efi.automount
systemctl disable efi.automount
systemctl restart daemon-reload

nixos-rebuild test --flake ~/nixos-configs#frametop

cp ~/.ssh/ /home/administrator/.ssh
echo "password" | mkpasswd -s

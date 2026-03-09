# Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) for both NixOS and Home Manager. Encrypted data lives in the repo, and SOPS decrypts to per-host paths at rebuild time.

## Repository layout

- `secrets/secrets.yaml`: Encrypted secrets file used by both system and home configs.
- `.sops.yaml`: Recipient configuration for SOPS.
- `hosts/common/global/sops.nix`: NixOS SOPS config (uses `/var/lib/sops-nix/keys.txt`).
- `home/global/sops.nix`: Home Manager SOPS config (uses `~/.config/sops/age/keys.txt`).

Both system and home configs are set to import SSH host keys and auto-generate an age key if one is missing.

## Initial setup

1. Ensure a host SSH key exists (usually already present on NixOS installs):
   ```sh
   ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
   ```
2. Convert the host SSH public key to an age recipient and add it to `.sops.yaml`:
   ```sh
   nix shell nixpkgs#ssh-to-age -c ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```
3. Encrypt or update the secrets file:
   ```sh
   sops -e -i secrets/secrets.yaml
   ```

## Adding a new host

1. Convert the host SSH public key to an age recipient (same as above).
2. Add the new recipient to `.sops.yaml`.
3. Re-encrypt secrets so the new host can decrypt:
   ```sh
   sops updatekeys secrets/secrets.yaml
   ```

## Quick checks

- Decrypt locally to verify:
  ```sh
  sops -d secrets/secrets.yaml
  ```
- Ensure SOPS key files exist:
  - System: `/var/lib/sops-nix/keys.txt`
  - Home: `~/.config/sops/age/keys.txt`

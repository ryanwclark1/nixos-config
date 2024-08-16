mkdir -p ~/.config/sops/age
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/key.txt"
nix-shell -p age --run "age-keygen -y ~/.config/sops/age/key.txt"


$EDITOR ~/nixos-config/.sops.yaml

keys:
  - &administrator
  - &frametop
creation_rules:
  - path_regex: secrets.yaml$
    key_groups:
    - age:
      - *administrator
      - *frametop

ssh-keygen -t ed25519 -f  /etc/ssh/ssh_host_ed25519_key -N ""
nix-shell -p ssh-to-age --run "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"

nix-shell -p sops --run "sops -y ~/nixos-config/secrets.yaml"

mkpasswd -s
cat etc/ssh/ssh_host_ed25519_key

#note add "|" for multiline yaml

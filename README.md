# nix-config


Create the directory and file for the sops output as the age command does not want to generate a file

```bash
$nix --extra-experimental-features nix-command --extra-experimental-features flakes flake init --template github:vimjoyer/flake-starter-config
$ mkdir -p ~/.config/sops/age/
$ touch ~/.config/sops/age/keys.txt
```

```bash
# generate new key at ~/.config/sops/age/keys.txt
$ nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
```


If you do not want to utilize an SSH Key
```bash
$ ssh-keygen -t ed25519
$ nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt


# get a public key of ~/.config/sops/age/keys.txt
nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt

https://www.youtube.com/watch?v=G5f6GC7SnhU
https://github.com/vimjoyer?tab=repositories

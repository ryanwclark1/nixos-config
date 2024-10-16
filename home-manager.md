sh <(curl -L https://nixos.org/nix/install) --daemon

nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
home-manager switch --flake .#$HOMEMANAGERPROFILE --show-trace --verbose --extra-experimental-features nix-command --extra-experimental-features flakes -b backup

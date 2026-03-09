{
  ...
}:

{
  imports = [
    ./common.nix    # Common shell configuration shared across all shells
    ./bash.nix
    ./carapace.nix
    ./fish.nix
    ./ion.nix
    ./nushell.nix
    ./zsh.nix
  ];
}

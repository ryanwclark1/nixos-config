{
  ...
}:

{
  imports = [
    ./common.nix    # Common shell configuration shared across all shells
    ./bash.nix
    ./fish.nix
    ./ion.nix
    ./nushell.nix
    ./zsh.nix
  ];
}

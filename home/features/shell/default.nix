{
  ...
}:

{
  imports = [
    ./common.nix    # Common shell configuration shared across all shells
    ./enhanced.nix   # Enhanced shell features and additional options
    ./bash.nix
    ./fish.nix
    ./ion.nix
    ./nushell.nix
    ./zsh.nix
  ];
}

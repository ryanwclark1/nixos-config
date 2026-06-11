{
  outputs,
  ...
}:

{
  imports = [
    ../theme
    # ./colorscheme.nix
    # ./style.nix
    ./sops.nix
    ./home.nix
  ];

}

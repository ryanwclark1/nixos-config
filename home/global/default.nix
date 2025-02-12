{
  outputs,
  ...
}:

{
  imports = [
    ./colorscheme.nix
    # ./style.nix
    ./sops.nix
    ./home.nix
  ]
  ++ (builtins.attrValues outputs.homeManagerModules);

  # home.file = {
  #   ".colorscheme".text = config.colorscheme.slug;
  #   ".colorscheme.json".text = builtins.toJSON config.colorscheme;
  # };

}

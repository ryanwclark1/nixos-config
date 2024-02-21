{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    fd #find alternative
    sd #sed alternative
    tree # Directory tree
  ];
  # programs.ripgrep = {
  #   enable = true;
  #   package = pkgs.ripgrep;
  # };
}

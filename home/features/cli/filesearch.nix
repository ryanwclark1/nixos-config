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
  programs.ripgrep = {
    enable = true;
    package = pkgs.ripgrep-all;
  };
  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    enableAliases = true;
  };
  programs.zoxide = {
    enable = true;
  };
}
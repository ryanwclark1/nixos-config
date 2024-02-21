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
}

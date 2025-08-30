{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
   walker
  ];
}


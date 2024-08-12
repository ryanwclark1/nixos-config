{
  pkgs,
  ...
}:

{
  home = {
    packages = with pkgs; [
      openra
    ];
  };
}

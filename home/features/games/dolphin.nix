{
  pkgs,
  ...
}:

{
  home = {
    packages = with pkgs; [
      dolphinEmu
    ];
  };
}

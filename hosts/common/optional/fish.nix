{
  pkgs,
  ...
}:

{
  programs = {
    fish = {
      enable = true;
      package = pkgs.fish;
      useBabelfish = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
    };
  };
}
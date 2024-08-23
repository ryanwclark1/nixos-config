{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.wofi = {
    enable = true;
    package = pkgs.wofi;
    settings = {
      width = 600;
      height = 600;
      prompt = "Search...";
      image_size = 48;
      # term = "kitty";
      columns = 3;
      allow_images = true;
      gtk_dark = true;
      insensitive = true;
      run-always_parse_args = true;
      run-cache_file = "/dev/null";
      run-exec_search = true;
      matching = "multi-contains";
    };
  };

  home.packages = let
    inherit (config.programs.password-store) package enable;
  in
    lib.optional enable (pkgs.pass-wofi.override {pass = package;});
}
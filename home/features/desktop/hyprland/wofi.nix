{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.wofi = {
    enable = false;
    package = pkgs.wofi;
    settings = {
      image_size = 48;
      columns = 3;
      allow_images = true;
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
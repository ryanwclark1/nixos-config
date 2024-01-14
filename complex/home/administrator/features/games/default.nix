{ pkgs, ... }: {
  imports = [
    ./lutris.nix
    ./steam.nix
    ./prism-launcher.nix
    ./runescape.nix
  ];
  home = {
    packages = with pkgs; [ gamescope ];
    # persistence = {
    #   "/persist/home/administrator" = {
    #     allowOther = true;
    #     directories = [{
    #       # Use symlink, as games may be IO-heavy
    #       directory = "Games";
    #       method = "symlink";
    #     }];
    #   };
    # };
  };
}

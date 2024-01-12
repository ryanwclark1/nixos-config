{

}
# {
#   lib,
#   config,
#   pkgs,
#   ...
# }:

# with lib; {
#   options.chrome.enable = mkEnableOption "chrome settings";

#   config = mkIf config.chrome.enable {
#     # Add the google-chrome package nixpkgs packages google-chrome

#     environment.systemPackages = [ pkgs.google-chrome ];

#   };
# }

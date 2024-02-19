{
  pkgs,
  ...
}:

{
  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
    config = {
      theme = "Nord";
    };
    # themes = {
    #   nord = {
    #     src = pkgs.fetchFromGitHub {
    #       owner = "nodetheme";
    #       repo = "sublime"; # Bat uses sublime syntax for its themes
    #       rev = "91eae63dc83ed501aa133d8f3266c301ab0cbf68";
    #       hash = "sha256-PrhDhS1bYL+7AHzytOfNhnLIpi8p6WMv9TPsy/arVew=";
    #     };
    #     file = "Nord.tmTheme";
    #   };
    # };
  };
}
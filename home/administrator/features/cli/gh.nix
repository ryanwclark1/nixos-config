{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      gh-markdown-preview
      gh-dash
      gh-eco
      gh-cal
    ];
    gitCredentialHelper.enable = true;
    # settings = {
    #   version = "1";
    #   git_protocol = "ssh";
    #   prompt = "enabled";
    # };
  };
  # home.persistence = {
  #   "/persist/home/administrator".directories = [ ".config/gh" ];
  # };
}

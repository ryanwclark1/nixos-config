{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    extensions = with pkgs; [
      gh-markdown-preview
      gh-dash
      gh-eco
      gh-cal
    ];

    # settings = {
    #   version = "1";
    #   git_protocol = "ssh";
    #   prompt = "enabled";
    # };
  };

}

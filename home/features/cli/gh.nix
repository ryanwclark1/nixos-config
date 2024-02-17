{ pkgs
, ...
}:

{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    extensions = with pkgs; [
      bump #  CLI tool to draft a GitHub Release for the next semantic version
      gh-markdown-preview
      gh-dash
      gh-eco
      gh-cal
    ];
  };

}

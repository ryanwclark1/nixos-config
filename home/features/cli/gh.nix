{
  pkgs,
  ...
}:

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
  };

}

{
  pkgs,
  ...
}:

{
  programs.gh = {
    enable = true;
    package = pkgs.gh;
    gitCredentialHelper = {
      enable = true;
    };
    settings = {
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
      git_protocal = "https";
    };
    extensions = with pkgs; [
      bump #  CLI tool to draft a GitHub Release for the next semantic version
      gh-markdown-preview # GitHub CLI extension to preview Markdown looks like GitHub.
      gh-dash # A beautiful CLI dashboard for GitHub 🚀
      gh-copilot # Ask for assistance right in your terminal
      gh-f # GitHub CLI ultimate FZF extension
    ];
  };

}

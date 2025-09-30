{
  config,
  lib,
  ...
}:

{
  # Environment variables
  environment = {
    variables = {
      PERSONAL_DOMAIN = "techcasa.io";

      # System-wide environment variables
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      LESS = "-R";

      # Locale settings
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";

      # Development environment
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
    };

    # System-wide shell aliases
    shellAliases = {

      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";

      # System monitoring
      ports = "netstat -tulpn";
      mem = "free -h";
      disk = "df -h";
    };
  };

  environment.sessionVariables = {
    # Application-specific
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };
}

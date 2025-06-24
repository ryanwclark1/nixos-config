{
  config,
  lib,
  ...
}:

{
  # Environment variables
  environment = {
    variables = {
      # Personal domain variables
      # Note: ACCENT_EMAIL is intentionally not set here as it's environment-specific
      # You can set it manually or use a different approach for sensitive data
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
      # Common commands
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";

      # NixOS specific
      rebuild = "sudo nixos-rebuild switch";
      rebuild-test = "sudo nixos-rebuild test";
      rebuild-boot = "sudo nixos-rebuild boot";

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

  # System-wide session variables
  environment.sessionVariables = {
    # Application-specific
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };
}

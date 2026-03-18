{
  pkgs,
  ...
}:

{
  # Install hypridle package
  home.packages = [ pkgs.hypridle ];

  # Copy hypridle configuration file
  home.file.".config/hypr/hypridle.conf".source = ./hypridle.conf;

  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland's idle daemon";
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}

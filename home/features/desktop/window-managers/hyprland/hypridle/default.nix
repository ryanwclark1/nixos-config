{
  pkgs,
  ...
}:

let
  hypridleLauncher = pkgs.writeShellScript "hypridle-launcher" ''
    set -eu

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
    runtime_conf="$state_dir/hypridle.conf"
    template_conf="$HOME/.config/hypr/hypridle.conf"

    mkdir -p "$state_dir"

    if [ ! -s "$runtime_conf" ]; then
      cp "$template_conf" "$runtime_conf"
    fi

    exec ${pkgs.hypridle}/bin/hypridle -c "$runtime_conf"
  '';
in
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
      ExecStart = "${hypridleLauncher}";
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}

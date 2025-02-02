{
  ...
}:

{
  systemd.user.services.update-dots = {
    Unit = {
      Description = "Copy and commit dot config files";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${builtins.getEnv "HOME"}/Code/dotfiles/update_dots.sh";
      WorkingDirectory = "${builtins.getEnv "HOME"}/Code/dotfiles";
      Environment = "PATH=/run/current-system/sw/bin";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers.update-dots = {
    Unit = {
      Description = "Run update_dots.sh daily";
    };

    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "update-dots.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
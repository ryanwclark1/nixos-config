{
  lib,
  ...
}:

{
  imports = [
    ./wlogout
  ];

  home.activation.cleanupLegacyGraphicalSessionWants = lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
    wants_dir="$HOME/.config/systemd/user/graphical-session.target.wants"

    if [ -d "$wants_dir" ]; then
      for unit in \
        hypridle.service \
        hyprpolkitagent.service \
        quickshell.service \
        swayosd.service \
        voxtype.service
      do
        rm -f "$wants_dir/$unit"
      done
    fi
  '';
}

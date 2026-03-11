{
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    file
    wl-clipboard  # For clipboard integration in fzf
    (writeScriptBin "bluetoothz" (builtins.readFile ./bluetoothz.sh))
    (writeScriptBin "dkr" (builtins.readFile ./dkr.sh))
    (writeScriptBin "fv" (builtins.readFile ./fv.sh))
    (writeScriptBin "fzf-git" (builtins.readFile ./fzf-git.sh))
    (writeScriptBin "fzf-preview" (builtins.readFile ./fzf-preview.sh))
    (writeScriptBin "fzmv" (builtins.readFile ./fzmv.sh))
    (writeScriptBin "fztop" (builtins.readFile ./fztop.sh))
    (writeScriptBin "gitup" (builtins.readFile ./gitup.sh))
    (writeScriptBin "igr" (builtins.readFile ./igr.sh))
    (writeScriptBin "sshget" (builtins.readFile ./sshget.sh))
    (writeScriptBin "sysz" (builtins.readFile ./sysz.sh))
    (writeScriptBin "wifiz" (builtins.readFile ./wifiz.sh))
  ];

  home.file = {
    # Hyprland utility scripts directory (only .sh files)
    ".config/scripts" = {
      force = true;
      source = lib.cleanSourceWith {
        src = ./.;
        filter = path: type: if type == "directory" then true else lib.hasSuffix ".sh" (baseNameOf path);
      };
      recursive = true;
      executable = true;
    };
  };
}

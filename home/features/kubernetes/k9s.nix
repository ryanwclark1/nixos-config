{
  pkgs,
  ...
}:

{
  programs = {
    k9s = {
      enable = true;
      alias = {
        # Use pp as an alias for Pod
        pp = "v1/pods";
      };
      hotkey = {
        # Make sure this is camel case
        hotKey = {
          shift-0 = {
            shortCut = "Shift-0";
            description = "Viewing pods";
            command = "pods";
          };
        };
      };
      package = pkgs.k9s;
      plugin = {
        # Defines a plugin to provide a `ctrl-l` shortcut to
        # tail the logs while in pod view.
        fred = {
          shortCut = "Ctrl-L";
          description = "Pod logs";
          scopes = [ "po" ];
          command = "kubectl";
          background = false;
          args = [
            "logs"
            "-f"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CLUSTER"
          ];
        };
      };
    };
  };
}
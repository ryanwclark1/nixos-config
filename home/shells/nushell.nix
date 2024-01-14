{
  lib,
  config,
  ...
}:
with lib; {
  options = {
    nushell.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config = let
    nuLibDirs = "${config.xdg.dataHome}/nu_libs";
  in
    mkIf config.nushell.enable {
      programs.nushell = {
        enable = true;
        # envFile.text = "starship init nu | save -f  ~/.cache/starship/init.nu";
        environmentVariables = {
          # EDITOR = config.editor.terminal;
          PROMPT_COMMAND = "{ def create_left_prompt [] { starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)' } }";
          # STARSHIP_SHELL = "nu";
          NU_LIB_DIRS = "\"${nuLibDirs}\"";
        };

        configFile.text = let
          misc = ''
            $env.config = {
              show_banner: false,
              table: {
                mode: compact
              }

              ls: {
                use_ls_colors: false
              }
              shell_integration: true
            }
          '';
        in
          builtins.concatStringsSep "\n" [misc];
      };

      home.file = {
        # "${nuLibDirs}/job.nu" = {
        # source = job;
        # };
      };
      programs.direnv.enableNushellIntegration = config.direnv.enable;
      programs.starship.enableNushellIntegration = config.starship.enable;
      programs.zoxide.enableNushellIntegration = config.filesearch.enable;
    };
}
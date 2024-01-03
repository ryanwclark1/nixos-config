{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  inputer = placeholder: "${pkgs.gum}/bin/gum input --placeholder=${placeholder}";
  chooser = "${pkgs.gum}/bin/gum choose";
in {
  options = {
    shell = {
      user = mkOption {
        type = types.str;
        default = "${pkgs.zsh}/bin/zsh";
      };
    };

    editor = {
      terminal = mkOption {
        type = types.str;
        default = "${config.helix.package}/bin/hx";
      };
      helix = {
        package = mkOption {
          type = types.package;
          default = pkgs.hx;
        };
      };
    };
    terminal = mkOption {
      type = types.str;
      default = "${pkgs.foot}/bin/foot";
    };
    launcher = mkOption {
      type = types.str;
      default = "${pkgs.fuzzel}/bin/fuzzel";
    };
    multiplexer = {
      tmux = {
        package = mkOption {
          type = types.package;
          default = pkgs.tmux;
        };
        binary = mkOption {
          type = types.str;
          default = "${config.multiplexer.tmux.package}/bin/tmux";
        };
        newSession = {
          withNameAndAttach = mkOption {
            type = types.str;
            default = let inp = inputer "session-name"; in "${config.multiplexer.tmux.binary} new -A -s $(${inp})";
          };
        };
        openAndSelect = mkOption {
          type = types.str;
          default = "${config.multiplexer.tmux.binary} at -t $(${config.multiplexer.tmux.binary} ls | cut --delimiter=\":\" --fields=1 |  ${chooser})";
        };
      };
      zellij = {
        package = mkOption {
          type = types.package;
          default = pkgs.zellij;
        };
        binary = mkOption {
          type = types.str;
          default = "${config.multiplexer.zellij.package}/bin/zellij";
        };
        newSession = {
          withNameAndAttach = mkOption {
            type = types.str;
            default = let inp = inputer "session-name"; in "${config.multiplexer.zellij.binary} attach -c $(${inp})";
          };
        };
        openAndSelect = mkOption {
          type = types.str;
          default = "${config.multiplexer.zellij.binary} attach $(${config.multiplexer.zellij.binary} ls |  ${chooser})";
        };
      };
    };
  };
}
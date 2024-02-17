{
  lib,
  ...
}:

with lib; {
  options = {
    global-fonts = {
      main-family = mkOption {
        type = types.str;
        default = "Monaspace Argon Var";
      };
      second-family = mkOption {
        type = types.str;
        default = "Monaspace Radon Var";
      };
      third-family = mkOption {
        type = types.str;
        default = "Monaspace Neon Var";
      };

      forth-family = mkOption {
        type = types.str;
        default = "Monaspace Xenon Var";
      };

      fifth-family = mkOption {
        type = types.str;
        default = "Monaspace Krypton Var";
      };

      main-black = mkOption {
        type = types.str;
        default = "Monaspace Argon ExtraBold";
      };
      main-black-italic = mkOption {
        type = types.str;
        default = "Monaspace Radon ExtraBold";
      };
      main-bold = mkOption {
        type = types.str;
        default = "Monaspace Argon Bold";
      };
      main-bold-italic = mkOption {
        type = types.str;
        default = "Monaspace Radon Bold";
      };
      main-medium = mkOption {
        type = types.str;
        default = "Monaspace Argon Medium";
      };
      main-medium-italic = mkOption {
        type = types.str;
        default = "Monaspace Radon Medium";
      };
      main-regular = mkOption {
        type = types.str;
        default = "Monaspace Argon";
      };
      main-italic = mkOption {
        type = types.str;
        default = "Monaspace Radon";
      };

      main-light = mkOption {
        type = types.str;
        default = "Monaspcae Argon Light";
      };
      main-light-italic = mkOption {
        type = types.str;
        default = "Monaspace Radon Light";
      };
      main-thin = mkOption {
        type = types.str;
        default = "Monaspace Argon ExtraLight";
      };
      main-thin-italic = mkOption {
        type = types.str;
        default = "Monaspace Radon ExtraLight";
      };
      main-set = mkOption {
        type = types.listOf types.str;
        default = [ "Monaspace Argon" "Monaspace Radon" "Monospace Neon" "Monospace Xenon" "Monospace Krypton" "Lotion" "Cascadia Code" "Maple Mono" "Pragmata Pro" "Operator Mono Book" "LigaOperatorMono Nerd Font" "OperatorMono Nerd Font Mono" "ComicCodeLigatures Nerd Font" "ComicCodeLigatures Nerd Font Complete Mono" "Gintronic" "Vazirmatn" ];
      };
    };
  };
}

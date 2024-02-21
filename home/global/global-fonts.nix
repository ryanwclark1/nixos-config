{
  lib,
  ...
}:
with lib;
{
  options = {
    global-fonts = {
      main-family = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font Var";
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
        default = "JetBrainsMono Nerd Font, Extrabold";
      };
      main-black-italic = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, ExtraBold Italic";
      };
      main-bold = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Bold";
      };
      main-bold-italic = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Bold Italic";
      };
      main-medium = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Medium";
      };
      main-medium-italic = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Medium Italic";
      };
      main-regular = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font";
      };
      main-italic = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Regular Italic";
      };

      main-light = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Light";
      };
      main-light-italic = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Light Italic";
      };
      main-thin = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Extralight";
      };
      main-thin-italic = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font, Extralight Italic";
      };
      main-set = mkOption {
        type = types.listOf types.str;
        default = [ "JetBrainsMono Nerd Font"  "Monaspace Argon" "Monaspace Radon" "Monospace Neon" "Monospace Xenon" "Monospace Krypton" "Lotion" "Cascadia Code" "Maple Mono" "Pragmata Pro" "Operator Mono Book" "LigaOperatorMono Nerd Font" "OperatorMono Nerd Font Mono" "ComicCodeLigatures Nerd Font" "ComicCodeLigatures Nerd Font Complete Mono" "Gintronic" "Vazirmatn" ];
      };
    };
  };
}

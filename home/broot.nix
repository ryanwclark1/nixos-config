# Navigate similar to to the output of tree
{
  config,
  lib,
  ...
}:
with lib; {
  options.brootFile.enable = mkEnableOption "broot settings";

  config = mkIf config.brootFile.enable {
    programs.broot = {
      enable = true;
      settings = {
        modal = true;
        # skin = {
        #   char_match_fg = "";
        #   char_match_bg = "";

        #   code_fg = "";
        #   code_bg = "";

        #   directory_fg = "";
        #   directory_bg = "";

        #   exe_fg = "";
        #   exe_bg = "";

        #   file_fg = "";
        #   file_bg = "";

        #   file_error_fg = "";
        #   file_error_bg = "";

        #   flag_label_fg = "";
        #   flag_label_bg = "";

        #   flag_value_fg = "";
        #   flag_value_bg = "";

        #   input_fg = "";
        #   input_bg = "";

        #   link_fg = "";
        #   link_bg = "";

        #   permissions_fg = "";
        #   permissions_bg = "";

        #   _fg = "";
        #   _bg = "";
        # };
      };
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
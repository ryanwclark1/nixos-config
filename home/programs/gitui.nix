{
  lib,
  config,
  ...
}:

with lib; {
  options.gitui.enable = mkEnableOption "gitui settings";
  config = mkIf config.gitui.enable {
    programs.gitui = {
      enable = true;
      theme = ''
        (
          selected_tab: Reset,
          command_fg: Rgb(202, 211, 245),
          selection_bg: Rgb(91, 96, 120),
          selection_fg: Rgb(202, 211, 245),
          cmdbar_bg: Rgb(30, 32, 48),
          cmdbar_extra_lines_bg: Rgb(30, 32, 48),
          disabled_fg: Rgb(128, 135, 162),
          diff_line_add: Rgb(166, 218, 149),
          diff_line_delete: Rgb(237, 135, 150),
          diff_file_added: Rgb(238, 212, 159),
          diff_file_removed: Rgb(238, 153, 160),
          diff_file_moved: Rgb(198, 160, 246),
          diff_file_modified: Rgb(245, 169, 127),
          commit_hash: Rgb(183, 189, 248),
          commit_time: Rgb(184, 192, 224),
          commit_author: Rgb(125, 196, 228),
          danger_fg: Rgb(237, 135, 150),
          push_gauge_bg: Rgb(138, 173, 244),
          push_gauge_fg: Rgb(36, 39, 58),
          tag_fg: Rgb(244, 219, 214),
          branch_fg: Rgb(139, 213, 202)
        )
      '';
    };
  };
}

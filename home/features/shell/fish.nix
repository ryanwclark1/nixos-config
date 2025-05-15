{
  ...
}:
let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in

{
  home.file.".config/fish/themes/frappe.theme" = {
    text = ''
      # name: 'Catppuccin Frappe'
      # url: 'https://github.com/catppuccin/fish'
      # preferred_background: ${base00}

      fish_color_normal ${base05}
      fish_color_command ${base0D}
      fish_color_param ${base0F}
      fish_color_keyword ${base08}
      fish_color_quote ${base0B}
      fish_color_redirection ${base17}
      fish_color_end ${base09}
      fish_color_comment 838ba7
      fish_color_error ${base08}
      fish_color_gray 737994
      fish_color_selection --background=${base02}
      fish_color_search_match --background=${base02}
      fish_color_option ${base0B}
      fish_color_operator ${base17}
      fish_color_escape ${base12}
      fish_color_autosuggestion 737994
      fish_color_cancel ${base08}
      fish_color_cwd ${base0A}
      fish_color_user ${base0C}
      fish_color_host ${base0D}
      fish_color_host_remote ${base0B}
      fish_color_status ${base08}
      fish_pager_color_progress 737994
      fish_pager_color_prefix ${base17}
      fish_pager_color_completion ${base05}
      fish_pager_color_description 737994
    '';
  };

  programs.fish = {
    enable = true;
    # loginShellInit = /* fish */ ''
    #   # Remove fish greeting
    #   set -U fish_greeting
    # '';
    shellAliases = {
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };

    interactiveShellInit = /* fish */ ''
        # Remove fish greeting
        # set -U fish_greeting

        # Open command buffer in vim when alt+e is pressed
        bind \ee edit_command_buffer
    '';
  };
}

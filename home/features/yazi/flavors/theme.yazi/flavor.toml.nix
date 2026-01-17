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
  home.file.".config/yazi/flavors/theme.yazi/flavor.toml" = {
    text = ''
      [manager]
      cwd = { fg = "#${base0C}" }

      # File list items
      syntect_theme = "~/.config/yazi/flavors/theme.yazi/tmtheme.xml"

      # Hovered
      hovered = { fg = "#${base00}", bg = "#${base0D}" }
      preview_hovered = { fg = "#${base00}", bg = "#${base05}" }

      # Find
      find_keyword = { fg = "#${base0A}", italic = true }
      find_position = { fg = "#${base0F}", bg = "reset", bold = true, italic = true }

      # Marker
      marker_copied = { fg = "#${base0B}", bg = "#${base0B}" }
      marker_cut = { fg = "#${base08}", bg = "#${base08}" }
      marker_marked = { fg = "#${base0C}", bg = "#${base0C}" }
      marker_selected = { fg = "#${base0D}", bg = "#${base0D}" }

      # Tab
      tab_active = { fg = "#${base00}", bg = "#${base05}" }
      tab_inactive = { fg = "#${base05}", bg = "#${base03}" }
      tab_width = 1

      # Count
      count_copied = { fg = "#${base00}", bg = "#${base0B}" }
      count_cut = { fg = "#${base00}", bg = "#${base08}" }
      count_selected = { fg = "#${base00}", bg = "#${base0D}" }

      # Border
      border_symbol = "│"
      border_style = { fg = "#${base04}" }

      [mode]
      normal_main = { fg = "#${base00}", bg = "#${base0D}", bold = true }
      normal_alt = { fg = "#${base0D}", bg = "#${base02}" }

      # Select mode
      select_main = { fg = "#${base00}", bg = "#${base07}", bold = true }
      select_alt = { fg = "#${base07}", bg = "#${base02}" }

      # Unset mode
      unset_main = { fg = "#${base00}", bg = "#${base0F}", bold = true }
      unset_alt = { fg = "#${base0F}", bg = "#${base02}" }

      [status]
      separator_open = ""
      separator_close = ""

      # Progress
      progress_label = { fg = "#ffffff", bold = true }
      progress_normal = { fg = "#${base0D}", bg = "#${base03}" }
      progress_error = { fg = "#${base08}", bg = "#${base03}" }

      # Permissions
      perm_type = { fg = "#${base07}" }
      perm_read = { fg = "#${base0A}" }
      perm_write = { fg = "#${base08}" }
      perm_exec = { fg = "#${base0B}" }
      perm_sep = { fg = "#${base04}" }

      [input]
      border = { fg = "#${base0D}" }
      title = {}
      value = {}
      selected = { reversed = true }

      [pick]
      border = { fg = "#${base0D}" }
      active = { fg = "#${base0F}", bold = true }
      inactive = {}

      [confirm]
      border = { fg = "#${base0D}" }
      title = {fg = "#${base0D}"}
      content = {}
      list = {}
      btn_yes = { reversed = true }
      btn_no = {}

      [cmp]
      border = { fg = "#${base0D}" }

      [tasks]
      border = { fg = "#${base0D}" }
      title = {}
      hovered = { underline = true }

      [which]
      mask = { bg = "#${base02}" }
      cand = { fg = "#${base0C}" }
      rest = { fg = "#${base04}" }
      desc = { fg = "#${base0F}" }
      separator = "  "
      separator_style = { fg = "#${base00}" }

      [help]
      on = { fg = "#${base0D}" }
      run = { fg = "#${base0F}" }
      hovered = { reversed = true, bold = true }
      footer = { fg = "#${base00}", bg = "#${base05}" }

      [notify]
      title_info = { fg = "#${base0B}" }
      title_warn = { fg = "#${base0A}" }
      title_error = { fg = "#${base08}" }


      [filetype]
      rules = [
        # Images
        { mime = "image/*", fg = "#${base0D}" },

        # Media
        { mime = "{audio,video}/*", fg = "#${base0A}" },

        # Archives
        { mime = "application/*zip", fg = "#${base0F}" },
        { mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}", fg = "#${base0F}" },

        # Documents
        { mime = "application/{pdf,doc,rtf}", fg = "#${base0B}" },

        # Fallback
        { name = "*", fg = "#${base05}" },
        { name = "*/", fg = "#${base0D}" }
      ]

      [spot]
      border = { fg = "#${base0D}" }
      title  = { fg = "#${base0D}" }
      tbl_cell = { fg = "#${base0D}", reversed = true }
      tbl_col = { bold = true }

    '';
  };
}

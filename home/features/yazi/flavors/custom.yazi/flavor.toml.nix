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
  home.file.".config/yazi/flavors/custom.yazi/flavor.toml" = {
    text = ''
      # vim:fileencoding=utf-8:foldmethod=marker

      # : Manager {{{

      [manager]
      cwd = { fg = "#${base0C}" }

      # Hovered
      hovered         = { reversed = true }
      preview_hovered = { underline = true }

      # Find
      find_keyword  = { fg = "#${base0A}", bold = true, italic = true, underline = true }
      find_position = { fg = "#${base17}", bg = "reset", bold = true, italic = true }

      # Marker
      marker_copied   = { fg = "#${base0B}", bg = "#${base0B}" }
      marker_cut      = { fg = "#${base08}", bg = "#${base08}" }
      marker_marked   = { fg = "#${base0C}", bg = "#${base0C}" }
      marker_selected = { fg = "#${base0A}", bg = "#${base0A}" }

      # Tab
      tab_active   = { reversed = true }
      tab_inactive = {}
      tab_width    = 1

      # Count
      count_copied   = { fg = "#${base00}", bg = "#${base0B}" }
      count_cut      = { fg = "#${base00}", bg = "#${base08}" }
      count_selected = { fg = "#${base00}", bg = "#${base0A}" }

      # Border
      border_symbol = "│"
      border_style  = { fg = "#838ba7" }

      # : }}}


      # : Mode {{{

      [mode]

      normal_main = { fg = "#${base00}", bg = "#${base0D}", bold = true }
      normal_alt  = { fg = "#${base0D}", bg = "#${base02}" }

      # Select mode
      select_main = { fg = "#${base00}", bg = "#${base0C}", bold = true }
      select_alt  = { fg = "#${base0C}", bg = "#${base02}" }

      # Unset mode
      unset_main = { fg = "#${base00}", bg = "#${base0F}", bold = true }
      unset_alt  = { fg = "#${base0F}", bg = "#${base02}" }

      # : }}}


      # : Status bar {{{

      [status]
      separator_open  = ""
      separator_close = ""

      # Progress
      progress_label  = { fg = "#ffffff", bold = true }
      progress_normal = { fg = "#${base0D}", bg = "#51576d" }
      progress_error  = { fg = "#${base08}", bg = "#51576d" }

      # Permissions
      perm_sep   = { fg = "#838ba7" }
      perm_type  = { fg = "#${base0D}" }
      perm_read  = { fg = "#${base0A}" }
      perm_write = { fg = "#${base08}" }
      perm_exec  = { fg = "#${base0B}" }

      # : }}}


      # : Pick {{{

      [pick]
      border   = { fg = "#${base0D}" }
      active   = { fg = "#${base17}", bold = true }
      inactive = {}

      # : }}}


      # : Input {{{

      [input]
      border   = { fg = "#${base0D}" }
      title    = {}
      value    = {}
      selected = { reversed = true }

      # : }}}


      # : Completion {{{

      [completion]
      border = { fg = "#${base0D}" }

      # : }}}


      # : Tasks {{{

      [tasks]
      border  = { fg = "#${base0D}" }
      title   = {}
      hovered = { fg = "#${base17}", underline = true }

      # : }}}


      # : Which {{{

      [which]
      mask            = { bg = "#${base02}" }
      cand            = { fg = "#${base0C}" }
      rest            = { fg = "#949cbb" }
      desc            = { fg = "#${base17}" }
      separator       = "  "
      separator_style = { fg = "#${base04}" }

      # : }}}


      # : Help {{{

      [help]
      on      = { fg = "#${base0C}" }
      run     = { fg = "#${base17}" }
      hovered = { reversed = true, bold = true }
      footer  = { fg = "#${base02}", bg = "#${base05}" }

      # : }}}


      # : Notify {{{

      [notify]
      title_info  = { fg = "#${base0B}" }
      title_warn  = { fg = "#${base0A}" }
      title_error = { fg = "#${base08}" }

      # : }}}


      # : File-specific styles {{{

      [filetype]

      rules = [
        # Images
        { mime = "image/*", fg = "#${base0C}" },

        # Media
        { mime = "{audio,video}/*", fg = "#${base0A}" },

        # Archives
        { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "#${base17}" },

        # Documents
        { mime = "application/{pdf,doc,rtf}", fg = "#${base0B}" },

        # Fallback
        { name = "*", fg = "#${base05}" },
        { name = "*/", fg = "#${base0D}" }
      ]

      # : }}}
    '';
  };
}
# home/vivid.nix
{ pkgs, lib, config, ... }:
let
  # Base24 palette mapping
  base00 = "303446"; # Default Background
  base01 = "292c3c"; # Lighter Background (Used for status bars, line number and folding marks)
  base02 = "414559"; # Selection Background
  base03 = "51576d"; # Comments, Invisibles, Line Highlighting
  base04 = "626880"; # Dark Foreground (Used for status bars)
  base05 = "c6d0f5"; # Default Foreground, Caret, Delimiters, Operators
  base06 = "f2d5cf"; # Light Foreground (Not often used)
  base07 = "babbf1"; # Light Background (Not often used)
  base08 = "e78284"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
  base09 = "ef9f76"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
  base0A = "e5c890"; # Classes, Markup Bold, Search Text Background
  base0B = "a6d189"; # Strings, Inherited Class, Markup Code, Diff Inserted
  base0C = "81c8be"; # Support, Regular Expressions, Escape Characters, Markup Quotes
  base0D = "8caaee"; # Functions, Methods, Attribute IDs, Headings
  base0E = "ca9ee6"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
  base0F = "eebebe"; # Deprecated, Opening/Closing Embedded Language Tags
  base10 = "292c3c"; # Darker Background
  base11 = "232634"; # Darkest Background  
  base12 = "ea999c"; # Bright Red
  base13 = "f2d5cf"; # Bright Orange
  base14 = "a6d189"; # Bright Yellow
  base15 = "99d1db"; # Bright Green
  base16 = "85c1dc"; # Bright Cyan
  base17 = "f4b8e4"; # Bright Blue

  # Write the vivid theme YAML following the correct schema
  themeYml = pkgs.writeText "theme.yml" ''
    colors:
      # Base24 colors mapped to simple names for use in the theme
      base00: "${base00}"  # Default Background
      base01: "${base01}"  # Lighter Background
      base02: "${base02}"  # Selection Background  
      base03: "${base03}"  # Comments, Invisibles
      base04: "${base04}"  # Dark Foreground
      base05: "${base05}"  # Default Foreground
      base06: "${base06}"  # Light Foreground
      base07: "${base07}"  # Light Background
      base08: "${base08}"  # Variables, Diff Deleted
      base09: "${base09}"  # Constants, Integers
      base0A: "${base0A}"  # Classes, Markup Bold
      base0B: "${base0B}"  # Strings, Diff Inserted
      base0C: "${base0C}"  # Support, Escape Characters
      base0D: "${base0D}"  # Functions, Methods
      base0E: "${base0E}"  # Keywords, Storage
      base0F: "${base0F}"  # Deprecated

    core:
      normal_text: {}
      regular_file: {}
      reset_to_normal: {}

      directory:
        foreground: base0D
        font-style: bold

      symlink:
        foreground: base0C
        font-style: bold

      multi_hard_link:
        foreground: base0E
        font-style: bold

      fifo:
        foreground: base00
        background: base0A

      socket:
        foreground: base00
        background: base09

      door:
        foreground: base00
        background: base0E

      block_device:
        foreground: base0C
        background: base01
        font-style: bold

      character_device:
        foreground: base0A
        background: base01
        font-style: bold

      broken_symlink:
        foreground: base00
        background: base08
        font-style: bold

      missing_symlink_target:
        foreground: base00
        background: base08

      setuid:
        foreground: base00
        background: base08
        font-style: bold

      setgid:
        foreground: base00
        background: base09
        font-style: bold

      file_with_capability:
        foreground: base00
        background: base0A

      sticky_other_writable:
        foreground: base00
        background: base0B
        font-style: bold

      other_writable:
        foreground: base00
        background: base04
        font-style: bold

      sticky:
        foreground: base00
        background: base0D
        font-style: bold

      executable_file:
        foreground: base0B
        font-style: bold

    text:
      special:
        foreground: base00
        background: base0A

      todo:
        foreground: base0A
        font-style: bold

      licenses:
        foreground: base04

      configuration:
        foreground: base0C

      other:
        foreground: base0A

    markup:
      foreground: base0A

    programming:
      source:
        foreground: base0B

      tooling:
        foreground: base0C

        continuous-integration:
          foreground: base0B

    media:
      image:
        foreground: base06
      
      video:
        foreground: base0E
      
      audio:
        foreground: base07

    office:
      foreground: base08

    archives:
      foreground: base09
      font-style: underline

    executable:
      foreground: base0B
      font-style: bold

    unimportant:
      foreground: base03

    # Additional file type categories
    vcs:
      foreground: base0E
      font-style: bold
  '';
in
{
  programs.vivid = {
    enable = true;
    package = pkgs.vivid;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    themes = {
      theme = themeYml;
    };
    colorMode = "24-bit";          # or "8-bit" for limited color support
    activeTheme = "theme";  # Use our base24 theme

    # Home-Manager expects an attrset of absolute paths.
    # We feed our generated base24 theme file here.


    # If you maintain a theme filetype DB, you can also add it like:
    # filetypes = pkgs.fetchurl { url = ".../filetypes.yml"; hash = "sha256-..."; };
  };

  # Note: Vivid program configuration automatically manages theme files
  # No need to manually create theme files
}

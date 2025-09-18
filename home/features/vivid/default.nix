# home/vivid.nix
{ pkgs, lib, ... }:
let
  # Catppuccin Frappé palette (your values)
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
  base10 = "292c3c"; # mantle - darker
  base11 = "232634"; # crust - darkest
  base12 = "ea999c"; # maroon-ish
  base13 = "f2d5cf"; # bright yellow-ish (rosewater)
  base14 = "a6d189"; # bright green
  base15 = "99d1db"; # sky
  base16 = "85c1dc"; # sapphire
  base17 = "f4b8e4"; # pink

  # Write the vivid theme YAML (validated by schemas/theme.json)
  # Note: vivid expects YAML themes; the JSON schema is just for validation.
  themeYml = pkgs.writeText "theme.yml" ''
    # $schema: https://raw.githubusercontent.com/sharkdp/vivid/master/schemas/theme.json
    colors:
      text:        "${base05}"
      muted:       "${base04}"
      subtle:      "${base03}"
      bg:          "${base00}"
      bg-alt:      "${base01}"
      crust:       "${base11}"

      red:         "${base08}"
      peach:       "${base09}"
      yellow:      "${base0A}"
      green:       "${base0B}"
      teal:        "${base0C}"
      blue:        "${base0D}"
      mauve:       "${base0E}"
      flamingo:    "${base0F}"
      rosewater:   "${base06}"
      lavender:    "${base07}"
      sky:         "${base15}"
      sapphire:    "${base16}"
      pink:        "${base17}"

    # Style helpers (foreground/background/font_style)
    # font_style may be a string or array: ["bold","underline"]
    ui:
      # fallbacks for unspecified items
      default:        { foreground: "text" }
      regular:        { foreground: "text" }
      special:        { foreground: "mauve",            font_style: "bold" }
      warning:        { foreground: "peach",            font_style: "bold" }
      danger:         { foreground: "red",              font_style: "bold" }
      good:           { foreground: "green",            font_style: "bold" }
      dim:            { foreground: "muted" }
      invert:         { foreground: "bg", background: "text" }

    # File-type classes map to styles
    # (Names come from vivid's filetype DB; anything not listed uses ui.default)
    classes:
      directory:        { foreground: "blue",     font_style: "bold" }
      symlink:          { foreground: "teal",     font_style: "bold" }
      broken_symlink:   { foreground: "red",      font_style: "bold" }
      executable:       { foreground: "green",    font_style: "bold" }
      multi_hard_link:  { foreground: "mauve",    font_style: "bold" }
      fifo:             { foreground: "yellow" }
      socket:           { foreground: "peach" }
      block_device:     { foreground: "sapphire", background: "bg-alt", font_style: "bold" }
      char_device:      { foreground: "sky",      background: "bg-alt", font_style: "bold" }
      door:             { foreground: "pink" }
      setuid:           { foreground: "red",      background: "crust",  font_style: "bold" }
      setgid:           { foreground: "peach",    background: "crust",  font_style: "bold" }
      capability:       { foreground: "yellow",   background: "crust",  font_style: "bold" }
      sticky_other_writable: { foreground: "bg",  background: "peach",  font_style: "bold" }
      other_writable:   { foreground: "bg",       background: "muted",  font_style: "bold" }
      sticky:           { foreground: "bg",       background: "blue",   font_style: "bold" }
      missing:          { foreground: "red",      font_style: "bold" }

    # Language/framework/file hints (a few tasteful picks)
    # Expand freely — these match keys from vivid's filetypes.yml
    filekinds:
      # archives & compressed
      archive:          { foreground: "peach" }
      compressed:       { foreground: "peach" }
      image:            { foreground: "rosewater" }
      audio:            { foreground: "lavender" }
      video:            { foreground: "pink" }
      document:         { foreground: "text" }
      pdf:              { foreground: "mauve" }
      source:           { foreground: "text" }
      header:           { foreground: "sky" }
      markup:           { foreground: "yellow" }
      config:           { foreground: "teal" }
      binary:           { foreground: "muted" }
      temp:             { foreground: "muted", font_style: "italic" }
      vcs_ignored:      { foreground: "muted", font_style: "italic" }
      hidden:           { foreground: "subtle" }

    # Dotfiles & VCS
    special:
      ".git":           { foreground: "mauve",   font_style: "bold" }
      ".gitignore":     { foreground: "muted",   font_style: "italic" }
      ".env":           { foreground: "teal" }

    # Emphasize readme & license
    by_name:
      "README":         { foreground: "yellow",  font_style: ["bold","underline"] }
      "LICENSE":        { foreground: "green",   font_style: "bold" }
  '';
in
{
  programs.vivid = {
    enable = true;
    package = pkgs.vivid;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    colorMode = "truecolor";       # or "8-bit" if you need it
    activeTheme = "theme";

    # Home-Manager expects an attrset of absolute paths.
    # We feed our generated file here and make it selectable as "catppuccin-frappe-ryan".
    themes = {
      theme = themeYml;
    };

    # If you maintain a theme filetype DB, you can also add it like:
    # filetypes = pkgs.fetchurl { url = ".../filetypes.yml"; hash = "sha256-..."; };
  };

  # (Optional) Also keep a copy under ~/.config/vivid/themes/ for easy inspection
  home.file.".config/vivid/themes/theme.yml".source = themeYml;
}

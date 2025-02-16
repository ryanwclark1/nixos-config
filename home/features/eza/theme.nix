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
  home.file.".config/eza/theme.yml" = {
    text = ''
    colourful: true

    filekinds:
      normal: {foreground: "#${base05}"}
      directory: {foreground: "#${base0D}"}
      symlink: {foreground: "#${base14}"}
      pipe: {foreground: "#${base04}"}
      block_device: {foreground: "#${base12}"}
      char_device: {foreground: "#${base12}"}
      socket: {foreground: "#${base03}"}
      special: {foreground: "#${base0E}"}
      executable: {foreground: "#${base0B}"}
      mount_point: {foreground: "#${base16}"}

    perms:
      user_read: {foreground: "#${base05}"}
      user_write: {foreground: "#${base0A}"}
      user_execute_file: {foreground: "#${base0B}"}
      user_execute_other: {foreground: "#${base0B}"}
      group_read: {foreground: "#${base05}"}
      group_write: {foreground: "#${base0A}"}
      group_execute: {foreground: "#${base0B}"}
      other_read: {foreground: "#${base05}"}
      other_write: {foreground: "#${base0A}"}
      other_execute: {foreground: "#${base0B}"}
      special_user_file: {foreground: "#${base0E}"}
      special_other: {foreground: "#${base03}"}
      attribute: {foreground: "#${base05}"}

    size:
      major: {foreground: "#${base05}"}
      minor: {foreground: "#${base14}"}
      number_byte: {foreground: "#${base05}"}
      number_kilo: {foreground: "#${base05}"}
      number_mega: {foreground: "#${base0D}"}
      number_giga: {foreground: "#${base0E}"}
      number_huge: {foreground: "#${base0E}"}
      unit_byte: {foreground: "#${base05}"}
      unit_kilo: {foreground: "#${base0D}"}
      unit_mega: {foreground: "#${base0E}"}
      unit_giga: {foreground: "#${base0E}"}
      unit_huge: {foreground: "#${base16}"}

    users:
      user_you: {foreground: "#${base05}"}
      user_root: {foreground: "#${base08}"}
      user_other: {foreground: "#${base0E}"}
      group_yours: {foreground: "#${base05}"}
      group_other: {foreground: "#${base04}"}
      group_root: {foreground: "#${base08}"}

    links:
      normal: {foreground: "#${base14}"}
      multi_link_file: {foreground: "#${base16}"}

    git:
      new: {foreground: "#${base0B}"}
      modified: {foreground: "#${base0A}"}
      deleted: {foreground: "#${base08}"}
      renamed: {foreground: "#${base0C}"}
      typechange: {foreground: "#${base17}"}
      ignored: {foreground: "#${base04}"}
      conflicted: {foreground: "#${base12}"}

    git_repo:
      branch_main: {foreground: "#${base05}"}
      branch_other: {foreground: "#${base0E}"}
      git_clean: {foreground: "#${base0B}"}
      git_dirty: {foreground: "#${base08}"}

    security_context:
      colon: {foreground: "#${base04}"}
      user: {foreground: "#${base05}"}
      role: {foreground: "#${base0E}"}
      typ: {foreground: "#${base03}"}
      range: {foreground: "#${base0E}"}

    file_type:
      image: {foreground: "#${base0A}"}
      video: {foreground: "#${base08}"}
      music: {foreground: "#${base0B}"}
      lossless: {foreground: "#${base0C}"}
      crypto: {foreground: "#${base03}"}
      document: {foreground: "#${base05}"}
      compressed: {foreground: "#${base17}"}
      temp: {foreground: "#${base12}"}
      compiled: {foreground: "#${base16}"}
      build: {foreground: "#${base03}"}
      source: {foreground: "#${base0D}"}

    punctuation: {foreground: "#${base04}"}
    date: {foreground: "#${base0A}"}
    inode: {foreground: "#${base05}"}
    blocks: {foreground: "#${base04}"}
    header: {foreground: "#${base05}"}
    octal: {foreground: "#${base0C}"}
    flags: {foreground: "#${base0E}"}

    symlink_path: {foreground: "#${base14}"}
    control_char: {foreground: "#${base16}"}
    broken_symlink: {foreground: "#${base08}"}
    broken_path_overlay: {foreground: "#${base03}"}
    '';
    executable = false;
  };
}
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
      directory: {foreground: "#${base0E}", is_bold: true }
      symlink: {foreground: "#${base0B}"}
      pipe: {foreground: "#${base04}"}
      block_device: {foreground: "#${base09}", is_bold: true }
      char_device: {foreground: "#${base09}", is_bold: true }
      socket: {foreground: "#${base03}"}
      special: {foreground: "#${base07}"}
      executable: {foreground: "#${base0B}", is_bold: true }
      mount_point: {foreground: "#${base0D}", is_bold: true, is_underline: true }

    perms:
      user_read: {foreground: "#${base0A}"}
      user_write: {foreground: "#${base0A}"}
      user_execute_file: {foreground: "#${base0B}"}
      user_execute_other: {foreground: "#${base0B}"}
      group_read: {foreground: "#${base0A}"}
      group_write: {foreground: "#${base0A}"}
      group_execute: {foreground: "#${base0B}"}
      other_read: {foreground: "#${base0A}"}
      other_write: {foreground: "#${base0A}"}
      other_execute: {foreground: "#${base0B}"}
      special_user_file: {foreground: "#${base07}"}
      special_other: {foreground: "#${base03}"}
      attribute: {foreground: "#${base05}"}

    size:
      major: {foreground: "#${base05}"}
      minor: {foreground: "#${base0B}"}
      number_byte: {foreground: "#${base05}"}
      number_kilo: {foreground: "#${base05}"}
      number_mega: {foreground: "#${base0E}"}
      number_giga: {foreground: "#${base07}"}
      number_huge: {foreground: "#${base07}"}
      unit_byte: {foreground: "#${base05}"}
      unit_kilo: {foreground: "#${base0E}"}
      unit_mega: {foreground: "#${base07}"}
      unit_giga: {foreground: "#${base07}"}
      unit_huge: {foreground: "#${base0D}"}

    users:
      user_you: {foreground: "#${base05}", is_bold: true }
      user_root: {foreground: "#${base08}"}
      user_other: {foreground: "#${base07}"}
      group_yours: {foreground: "#${base05}", is_bold: true }
      group_other: {foreground: "#${base04}"}
      group_root: {foreground: "#${base08}"}

    links:
      normal: {foreground: "#${base08}", is_bold: true}
      multi_link_file: {foreground: "#${base08}", background: "#${base0A}"}

    git:
      new: {foreground: "#${base0B}"}
      modified: {foreground: "#${base0D}"}
      deleted: {foreground: "#${base08}"}
      renamed: {foreground: "#${base0C}"}
      typechange: {foreground: "#${base0F}"}
      ignored: {foreground: "#${base04}", is_dimmed: true}
      conflicted: {foreground: "#${base09}"}

    git_repo:
      branch_main: {foreground: "#${base05}"}
      branch_other: {foreground: "#${base07}"}
      git_clean: {foreground: "#${base0B}"}
      git_dirty: {foreground: "#${base08}"}

    security_context:
      colon: {foreground: "#${base04}", is_dimmed: true }
      user: {foreground: "#${base05}"}
      role: {foreground: "#${base07}"}
      typ: {foreground: "#${base03}"}
      range: {foreground: "#${base07}"}

    file_type:
      image: {foreground: "#${base06}"}
      video: {foreground: "#${base08}", is_bold: true }
      music: {foreground: "#${base0B}"}
      lossless: {foreground: "#${base0C}", is_bold: true }
      crypto: {foreground: "#${base07}", is_bold: true }
      document: {foreground: "#${base0A}"}
      compressed: {foreground: "#${base0F}"}
      temp: {foreground: "#${base09}"}
      compiled: {foreground: "#${base0D}"}
      build: {foreground: "#${base03}", background: "#${base08}" is_bold: true, is_underline: true }
      source: {foreground: "#${base0E}", is_bold: true }

    punctuation: {foreground: "#${base00}", is_bold: true }
    date: {foreground: "#${base0A}"}
    inode: {foreground: "#${base05}"}
    blocks: {foreground: "#${base04}"}
    header: {foreground: "#${base05}", is_underline: true }
    octal: {foreground: "#${base0C}"}
    flags: {foreground: "#${base07}"}

    symlink_path: {foreground: "#${base0B}"}
    control_char: {foreground: "#${base08}"}
    broken_symlink: {foreground: "#${base08}"}
    broken_path_overlay: {foreground: "#${base03}", is_underline: true }
    '';
    executable = false;
  };
}

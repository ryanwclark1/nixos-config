{
  lib,
  pkgs,
  ...
}:

{
  # General purpose file previewer designed for Ranger, Lf to make scope.sh redundant
  home.packages = with pkgs; [
    file #A program that shows the type of files.
    exiftool #A program that shows the metadata of files.
    mediainfo
    poppler-utils #pdftotext and pdfinfo
    epub2txt2
    xlsx2csv #for xlsx files
    librsvg
    chafa #for lf image previews
    odt2txt
    elinks
    hexyl
    notcurses
  ];

  programs.pistol = {
    enable = true;
    associations =
    let
      epub2txt = lib.getExe pkgs.epub2txt2;
      exiftool = lib.getExe pkgs.exiftool;
      atool = lib.getExe pkgs.atool;
      xlsx2csv = lib.getExe pkgs.xlsx2csv;
      hexyl = lib.getExe pkgs.hexyl;
    in
    [
      {
        mime = "image/*";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "video/*";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "audio/*";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/gzip";
        command = "${atool} -l %pistol-filename%";
      }
      {
        mime = "application/pdf";
        command = "sh: pdftotext -l 10 -nopgbrk -q -- %pistol-filename% - | fmt -w $(tput cols)";
      }
      {
        mime = "application/epub+zip";
        command = "${epub2txt} %pistol-filename%";
      }
      {
        mime = "application/x-msdownload";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/x-sharedlib";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/x-executable";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/x-font-ttf";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/x-font-woff";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/x-font-otf";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-opentype";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-fontobject";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-excel";
        command = "${exiftool} %pistol-filename%";
      }
      {
        mime = "application/application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        command = "${xlsx2csv} %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-excel";
        command = "${xlsx2csv} %pistol-filename%";
      }
      {
        mime = "application/*";
        command = "${hexyl} %pistol-filename%";
      }
      {
        fpath = ".*.md$";
        command = "sh: bat --paging=never --color=always %pistol-filename% | head -8";
      }
    ];
  };
}

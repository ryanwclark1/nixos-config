{
pkgs,
...
}:

{
  # General purpose file previewer designed for Ranger, Lf to make scope.sh redundant
  programs.pistol = {
    enable = true;
    associations = [
      # {
      #   mime = "image/*";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "video/*";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "audio/*";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/gzip";
      #   command = "${pkgs.atool}/bin/atool -l %pistol-filename%";
      # }
      # {
      #   mime = "application/pdf";
      #   command = "sh: pdftotext -l 10 -nopgbrk -q -- %pistol-filename% - | fmt -w $(tput cols)";
      # }
      # {
      #   mime = "application/epub+zip";
      #   command = "epub2txt %pistol-filename%";
      # }
      # {
      #   mime = "application/x-msdownload";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/x-sharedlib";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/x-executable";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/x-font-ttf";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/x-font-woff";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/x-font-otf";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/vnd.ms-opentype";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/vnd.ms-fontobject";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/vnd.ms-excel";
      #   command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      # }
      # {
      #   mime = "application/application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      #   command = "${pkgs.xlsx2csv}/bin/xlsx2csv %pistol-filename%";
      # }
      # {
      #   mime = "application/vnd.ms-excel";
      #   command = "${pkgs.xlsx2csv}/bin/xlsx2csv %pistol-filename%";
      # }
      # {
      #   mime = "application/*";
      #   command = "${pkgs.hexyl}/bin/hexyl %pistol-filename%";
      # }
      {
        fpath = ".*.md$";
        command = "sh: bat --paging=never --color=always %pistol-filename% | head -8";
      }
    ];
  };
}
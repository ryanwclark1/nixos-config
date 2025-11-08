
#!/usr/bin/env bash
EXIF_TAGS="-FileName -FileSize -FileModifyDate -FilePermissions -FileTypeExtension -MIMEType -ImageSize"

MIMETYPE="$(file --dereference --brief --mime-type -- "$1")"

case "$MIMETYPE" in
  text/html)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.elinks}/bin/elinks dump "$1"
    ;;
  text/*)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.bat}/bin/bat --style=plain --paging=never --color=always -- "$1"
    ;;
  image/*)
    # kitty chafa format is not working.
    case "$TERM" in
      *kitty)
        CHAFA_FORMAT="kitty";;
      *)
        CHAFA_FORMAT="symbols";;
    esac
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.chafa}/bin/chafa --format=symbols -- "$1"
    ;;
  video/*)
    ${pkgs.mediainfo}/bin/mediainfo -- "$1"
    ;;
  audio/*)
    ${pkgs.mediainfo}/bin/mediainfo -- "$1"
    ;;
  application/json)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.jq}/bin/jq --color-output . "$1" | head -n 100
    ;;
  application/x-7z-compressed|application/x-bzip|application/x-bzip2)
      ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1";echo -e "\n"; ${pkgs.p7zip}/bin/7z l "$1" | awk '/  Date/{print}'
    ;;
  application/zip)
      ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.atool}/bin/atool --list -- "$1"
    ;;
  application/gzip|application/x-xz|application/x-tarapplication/x-tar)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1";echo -e "\n"; ${pkgs.atool}/bin/atool --list -- "$1"| sed '\Permission\tUID/GID\t\tSize\tDate\tTime\tFileName\n---------\t-------\t\t----\t----\t----\t--------'
    ;;
  application/x-iso9660-image)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.atool}/bin/atool --list -- "$1"
    ;;
  application/pdf)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.poppler-utils}/bin/pdftotext -l 4 -nopgbrk -q -- "$1" - | fmt -w $(tput cols)
    ;;
  application/epub+zip)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.epub2txt2}/bin/epub2txt "$1"
    ;;
  application/x-msdownload)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/x-sharedlib)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/x-executable)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/x-font-ttf)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/x-font-woff)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/x-font-otf)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/vnd.ms-opentype)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/vnd.ms-fontobject)
    ${pkgs.exiftool}/bin/exiftool "$1"
    ;;
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.xlsx2csv}/bin/xlsx2csv -i -- "$1"
    ;;
  application/vnd.ms-excel)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.xlsx2csv}/bin/xlsx2csv -i -- "$1"
    ;;
  application/vnd.sqlite3)
    # open sqlite3 database and show table names in the terminal
    ${pkgs.exiftool}/bin/exiftool "$1"; echo -e "\n"; sqlite3 "$1" ".tables";echo "$MIMETYPE"; echo "$1"
    ;;
  application/octet-stream)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.hexyl}/bin/hexyl "$1"
    ;;
  application/*)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; echo "$MIMETYPE"; echo "$1"
    ;;
  *)
    ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; echo "$MIMETYPE"; echo "$1"
    ;;
esac

#!/usr/bin/env bash
# shellcheck disable=2034

set -o noclobber -o pipefail
IFS=$'\n'

FILE_PATH=""
PREVIEW_WIDTH=50
PREVIEW_HEIGHT=50
PREVIEW_OFFSET=0
TESTING=false
SCRIPT_FOLDER="${0%/*}"

while [ "$#" -gt 0 ]; do
  case "$1" in
  "--path")
    shift
    FILE_PATH="$1"
    ;;
  "--width")
    shift
    PREVIEW_WIDTH="$1"
    ;;
  "--height")
    shift
    PREVIEW_HEIGHT="$1"
    ;;
  "--offset")
    shift
    PREVIEW_OFFSET="$1"
    ;;
  "--test")
    TESTING=true
    ;;
  esac
  shift
done

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"
FILE_NAME="${FILE_PATH##*/}"

# Standardized EXIF tags for consistent metadata display
EXIF_TAGS="-FileName -FileSize -FileModifyDate -FilePermissions -FileTypeExtension -MIMEType -ImageSize"

exist_command() {
  command -v "$1" &>/dev/null
}

bat() {
  command bat "$@" \
    --color=always --paging=never \
    --style=plain \
    --wrap=character \
    --line-range :5000 \
    --terminal-width="${PREVIEW_WIDTH}"
}

echo_err() {
  if [ -e /dev/stderr ]; then
    echo -e "$*" | fold -w "${PREVIEW_WIDTH}" >>/dev/stderr
  elif [ -e /dev/fd/2 ]; then
    echo -e "$*" | fold -w "${PREVIEW_WIDTH}" >>/dev/fd/2
  else
    echo -e "$*" | fold -w "${PREVIEW_WIDTH}"
  fi
}

die() {
  echo_err "\033[1;31m$*\033[m\n\r"
  exit 255
}

exiftool() {
  command exiftool '--ExifTool*' '--Directory' '--File*' '--ProfileDescription*' "$@"
}

handle_text() {
  # Enhanced text preview with better formatting (from enhanced-preview)
  bat \
    --color=always \
    --paging=never \
    --style=plain \
    --wrap=character \
    --terminal-width="${PREVIEW_WIDTH}" \
    --line-range=:500 \
    "${FILE_PATH}" && exit
}

handle_json() {
  # Show EXIF metadata first
  exiftool -s $EXIF_TAGS "$FILE_PATH" | bat -l yaml
  echo -e "\n--- JSON Content ---"

  # Use jq for better JSON formatting if available
  if exist_command jq; then
    jq --color-output . "$FILE_PATH" 2>/dev/null | head -n 100 && exit
  fi

  # Fallback to bat
  bat -l json "$FILE_PATH" --theme=TwoDark && exit
  handle_text
}

echo_image_path() {
  echo "__preview__image__path__ $1"
  echo -e "\033[1;30m─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m"
}

calc_hash() {
  command md5 -q /dev/stdin 2>/dev/null && return
  (md5sum || sha1sum || shasum || sha256sum) 2>/dev/null | cut -d " " -f 1
}

with_cache() {
  local ext=""
  local echo_image=false
  local cat_cache=false
  local no_stdout=false

  while [ "$#" -gt 0 ]; do
    case "$1" in
    "-ext")
      shift
      ext=".$1"
      ;;
    "-cat")
      cat_cache=true
      ;;
    "-img")
      echo_image=true
      ;;
    "--no-stdout")
      no_stdout=true
      ;;
    "--")
      shift
      break
      ;;
    esac
    shift
  done

  if "$cat_cache" && [ -z "$ext" ]; then
    ext=".ansi"
  fi

  CACHE="${TMPDIR:-/tmp/}yazi/$(ls -l "$FILE_PATH" | calc_hash)${ext}"
  local error=""
  if [ ! -f "$CACHE" ] && ! $TESTING; then
    error="$(
      {
        if "$no_stdout"; then
          "$@" >/dev/null
        else
          "$@" >"$CACHE"
        fi
      } 2>&1
    )"
  fi
  if [ -s "$CACHE" ]; then
    # The file is not-empty.
    if "$echo_image"; then
      echo_image_path "$CACHE"
    elif "$cat_cache" && [ -f "$CACHE" ]; then
      cat "$CACHE"
    fi
    # else
    # The file is empty.
    # rm "$cache"
  fi
  if [ -n "$error" ]; then
    echo_err "$error"
  fi
}

handle_audio() {
  with_cache -img -- exiftool -b -CoverArt -Picture "$FILE_PATH"
  exiftool -Title -SortName -TitleSort -TitleSortOrder -Artist -SortArtist -ArtistSort -PerformerSortOrder \
    -Album -SortAlbum -AlbumSort -AlbumSortOrder -AlbumArtist -SortAlbumArtist -AlbumArtistSort -AlbumArtistSortOrder \
    -Genre -TrackNumber -Year -Duration -SampleRate -AudioSampleRate -AudioBitrate -AvgBitrate -Channels -AudioChannels "$FILE_PATH" | bat -l yaml
  # ffprobe -select_streams a:0 \
  #   -show_entries format=duration,bit_rate:stream=codec_name,sample_rate,channels,bits_per_raw_sample:format_tags \
  #   -sexagesimal -v quiet -of flat "${FILE_PATH}" | bat -l ini
}

# Freedesktop.org thumbnail specification functions
get_xdg_cache_home() {
  if [ -n "$XDG_CACHE_HOME" ]; then
    echo "$XDG_CACHE_HOME"
  else
    echo "$HOME/.cache"
  fi
}

# Generate MD5 hash for freedesktop thumbnail naming
get_file_uri_hash() {
  local file_path="$1"
  local file_uri="file://$(realpath "$file_path")"
  echo -n "$file_uri" | md5sum | cut -d' ' -f1
}

# Determine best freedesktop thumbnail size for yazi dimensions
get_thumbnail_size_info() {
  local target_width="$1"
  local target_height="$2"
  local max_dim=$((target_width > target_height ? target_width : target_height))

  if [ "$max_dim" -le 128 ]; then
    echo "normal 128"
  elif [ "$max_dim" -le 256 ]; then
    echo "large 256"
  elif [ "$max_dim" -le 512 ]; then
    echo "x-large 512"
  else
    echo "xx-large 1024"
  fi
}

# Get or create freedesktop thumbnail for videos
get_freedesktop_video_thumbnail() {
  local file_path="$1"
  local time_offset="${2:-0}"

  local cache_home="$(get_xdg_cache_home)"
  local file_hash="$(get_file_uri_hash "$file_path")"
  local size_info="$(get_thumbnail_size_info 800 600)"
  local size_name="$(echo "$size_info" | cut -d' ' -f1)"
  local size_px="$(echo "$size_info" | cut -d' ' -f2)"

  local thumb_dir="$cache_home/thumbnails/$size_name"
  local thumb_file="$thumb_dir/${file_hash}.png"

  # Check if thumbnail exists and is newer than source
  if [ -f "$thumb_file" ] && [ "$thumb_file" -nt "$file_path" ]; then
    echo_image_path "$thumb_file"
    return 0
  fi

  # Create thumbnail directory if it doesn't exist
  mkdir -p "$thumb_dir" 2>/dev/null || true

  # Generate thumbnail using ffmpeg with proper freedesktop sizing
  local temp_thumb="$(mktemp --suffix=.png)"
  if ffmpeg -v quiet -ss "$time_offset" -i "$file_path" -frames:v 1 \
    -vf "scale=$size_px:$size_px:force_original_aspect_ratio=decrease,pad=$size_px:$size_px:(ow-iw)/2:(oh-ih)/2:color=black@0" \
    -f image2 "$temp_thumb" 2>/dev/null; then

    # Add freedesktop metadata to thumbnail
    if exist_command exiftool; then
      local file_uri="file://$(realpath "$file_path")"
      local file_mtime="$(stat -c %Y "$file_path" 2>/dev/null || stat -f %m "$file_path" 2>/dev/null)"
      local file_size="$(stat -c %s "$file_path" 2>/dev/null || stat -f %z "$file_path" 2>/dev/null)"

      exiftool -overwrite_original \
        -Subject="$file_uri" \
        -Comment="Thumb::URI=$file_uri" \
        -UserComment="Thumb::MTime=$file_mtime" \
        -ImageDescription="Thumb::Size=$file_size" \
        "$temp_thumb" 2>/dev/null || true
    fi

    # Move to final location atomically
    if mv "$temp_thumb" "$thumb_file" 2>/dev/null; then
      echo_image_path "$thumb_file"
      return 0
    fi
  fi

  # Cleanup on failure
  rm -f "$temp_thumb" 2>/dev/null || true
  return 1
}

# Get or create freedesktop thumbnail for images
# Leverages freedesktop.org thumbnail standard for cross-application compatibility
get_freedesktop_image_thumbnail() {
  local file_path="$1"
  local target_width="${2:-800}"
  local target_height="${3:-600}"

  local cache_home="$(get_xdg_cache_home)"
  local file_hash="$(get_file_uri_hash "$file_path")"
  local size_info="$(get_thumbnail_size_info "$target_width" "$target_height")"
  local size_name="$(echo "$size_info" | cut -d' ' -f1)"
  local size_px="$(echo "$size_info" | cut -d' ' -f2)"

  local thumb_dir="$cache_home/thumbnails/$size_name"
  local thumb_file="$thumb_dir/${file_hash}.png"

  # Check if thumbnail exists and is newer than source (freedesktop standard check)
  if [ -f "$thumb_file" ] && [ "$thumb_file" -nt "$file_path" ]; then
    # Verify thumbnail metadata matches (freedesktop standard validation)
    if exist_command exiftool; then
      local file_uri="file://$(realpath "$file_path")"
      local stored_uri="$(exiftool -Comment -b "$thumb_file" 2>/dev/null | grep -o "Thumb::URI=.*" | cut -d'=' -f2-)"
      if [ "$stored_uri" = "$file_uri" ]; then
        echo_image_path "$thumb_file"
        return 0
      fi
    else
      # If exiftool not available, trust file timestamp
      echo_image_path "$thumb_file"
      return 0
    fi
  fi

  # Create thumbnail directory if it doesn't exist
  mkdir -p "$thumb_dir" 2>/dev/null || true

  # Generate thumbnail using ImageMagick or convert (freedesktop-compatible)
  local temp_thumb="$(mktemp --suffix=.png)"
  local success=false

  # Try ImageMagick first (better quality)
  if exist_command convert; then
    if convert "$file_path" -thumbnail "${size_px}x${size_px}>" -background black -gravity center -extent "${size_px}x${size_px}" "$temp_thumb" 2>/dev/null; then
      success=true
    fi
  # Fallback to ffmpeg if ImageMagick not available
  elif exist_command ffmpeg; then
    if ffmpeg -v quiet -i "$file_path" -frames:v 1 \
      -vf "scale=$size_px:$size_px:force_original_aspect_ratio=decrease,pad=$size_px:$size_px:(ow-iw)/2:(oh-ih)/2:color=black@0" \
      -f image2 "$temp_thumb" 2>/dev/null; then
      success=true
    fi
  fi

  if [ "$success" = true ]; then
    # Add freedesktop metadata to thumbnail (required by standard)
    if exist_command exiftool; then
      local file_uri="file://$(realpath "$file_path")"
      local file_mtime="$(stat -c %Y "$file_path" 2>/dev/null || stat -f %m "$file_path" 2>/dev/null)"
      local file_size="$(stat -c %s "$file_path" 2>/dev/null || stat -f %z "$file_path" 2>/dev/null)"

      exiftool -overwrite_original \
        -Subject="$file_uri" \
        -Comment="Thumb::URI=$file_uri" \
        -UserComment="Thumb::MTime=$file_mtime" \
        -ImageDescription="Thumb::Size=$file_size" \
        "$temp_thumb" 2>/dev/null || true
    fi

    # Move to final location atomically
    if mv "$temp_thumb" "$thumb_file" 2>/dev/null; then
      echo_image_path "$thumb_file"
      return 0
    fi
  fi

  # Cleanup on failure
  rm -f "$temp_thumb" 2>/dev/null || true
  return 1
}

handle_video() {
  if [ "$PREVIEW_OFFSET" -gt 9 ] || [ "$PREVIEW_OFFSET" -lt 0 ]; then
    exit 3
  fi

  # Try freedesktop thumbnail first (reuses thumbnails from other apps like file managers)
  if get_freedesktop_video_thumbnail "$FILE_PATH" $((PREVIEW_OFFSET * 10)) 2>/dev/null; then
    # Thumbnail found or created successfully
    :
  else
    # Fallback to temporary thumbnail if freedesktop generation fails
    local thumb_file="${TMPDIR:-/tmp}/yazi_video_$(basename "$FILE_PATH" | tr ' ' '_')_${PREVIEW_OFFSET}.jpg"

    if [ ! -f "$thumb_file" ] || [ "$FILE_PATH" -nt "$thumb_file" ]; then
      ffmpeg -v quiet -ss $((PREVIEW_OFFSET * 10)) -i "$FILE_PATH" -frames:v 1 -q:v 2 -f image2 \
        -vf "scale=800:600:force_original_aspect_ratio=decrease,pad=800:600:(ow-iw)/2:(oh-ih)/2" \
        "$thumb_file" 2>/dev/null
    fi

    if [ -f "$thumb_file" ]; then
      echo_image_path "$thumb_file"
    fi
  fi

  echo "$PREVIEW_OFFSET"

  # Show video metadata
  if exist_command ffprobe; then
    ffprobe -select_streams v:0 \
      -show_entries format=duration,bit_rate:stream=codec_name,width,height,avg_frame_rate,r_frame_rate,display_aspect_ratio,duration:format_tags \
      -sexagesimal -v quiet -of flat "${FILE_PATH}" | bat -l ini
  else
    exiftool '-AvgBitrate' '-ImageSize' '-Video*' '-Media*' '-Audio*' | bat -l yaml
  fi
}

process_compress_file() {
  # Show EXIF metadata first
  exiftool -s $EXIF_TAGS "$FILE_PATH" | bat -l yaml
  echo -e "\n--- Archive Contents ---"

  # Choose best tool based on file type
  case "${FILE_EXTENSION_LOWER}" in
    7z|bz2|bzip2)
      if exist_command 7z; then
        7z l "$FILE_PATH" | awk '/Date/{print}' | bat -l plain
        return
      fi
      ;;
    zip)
      if exist_command atool; then
        atool --list -- "$FILE_PATH" | bat -l plain
        return
      fi
      ;;
    tar|gz|xz|tgz)
      if exist_command atool; then
        echo -e "Permission\tUID/GID\t\tSize\tDate\tTime\tFileName"
        echo -e "---------\t-------\t\t----\t----\t----\t--------"
        atool --list -- "$FILE_PATH" | bat -l plain
        return
      fi
      ;;
  esac

  # Fallback to original method
  (bsdtar --list --file "${FILE_PATH}" || (lsar "${FILE_PATH}" | tail -n +2)) | tree -C --fromfile .
}

handle_compress() {
  with_cache -cat -- process_compress_file
}

handle_bin() {
  nm "$FILE_PATH" && exit
  nm -D "$FILE_PATH" && exit
}

process_pdf() {
  pdftoppm -singlefile -jpeg -jpegopt quality=75 -f $((PREVIEW_OFFSET + 1)) "$FILE_PATH"
  if [ "$?" -eq 99 ]; then
    exit 3
  fi
}

handle_pdf() {
  with_cache -ext "$PREVIEW_OFFSET" -img -- process_pdf
  echo "$PREVIEW_OFFSET"
  pdfinfo "$FILE_PATH" | bat -l yaml
}

# glow() function removed - using piper plugin for markdown rendering instead

process_svg() {
  if exist_command rsvg-convert; then
    rsvg-convert "$FILE_PATH" -o "$CACHE"
  elif exist_command convert; then
    convert "$FILE_PATH" "$CACHE"
  fi
}

process_ipynb() {
  if exist_command jupyter-nbconvert; then
    jupyter-nbconvert "${FILE_PATH}" --to markdown --stdout | handle_text
  else
    handle_json <"${FILE_PATH}"
  fi
}

handle_ipynb() {
  with_cache -cat -- process_ipynb
}

handle_image() {
  # Try to use freedesktop thumbnail first (reuses thumbnails from other apps)
  # Falls back to original image if thumbnail not available or generation fails
  if get_freedesktop_image_thumbnail "$FILE_PATH" "$PREVIEW_WIDTH" "$PREVIEW_HEIGHT" 2>/dev/null; then
    # Thumbnail found or created successfully
    :
  else
    # Fallback to original image if thumbnail generation fails
    echo_image_path "$FILE_PATH"
  fi

  # Show enhanced EXIF metadata (from enhanced-preview - more focused metadata)
  # Only show key fields for cleaner display
  exiftool -s \
    -FileName \
    -FileSize \
    -ImageSize \
    -DateTime \
    -Make \
    -Model \
    -ISO \
    -FNumber \
    -ExposureTime \
    -FocalLength \
    "${FILE_PATH}" 2>/dev/null | bat -l yaml

  # Optional: Add chafa preview for terminal image viewing
  if exist_command chafa && [ "$TESTING" = true ]; then
    echo -e "\n--- Terminal Preview ---"
    case "$TERM" in
      *kitty)
        chafa --format=kitty --size="${PREVIEW_WIDTH}x$((PREVIEW_HEIGHT/2))" "${FILE_PATH}" 2>/dev/null || \
        chafa --format=symbols --size="${PREVIEW_WIDTH}x$((PREVIEW_HEIGHT/2))" "${FILE_PATH}"
        ;;
      *)
        chafa --format=symbols --size="${PREVIEW_WIDTH}x$((PREVIEW_HEIGHT/2))" "${FILE_PATH}"
        ;;
    esac
  fi
}

process_docx() {
  if exist_command pandoc; then
    pandoc -s -t markdown -- "$FILE_PATH" | handle_text
  else
    process_doc
  fi
}

process_doc() {
  if exist_command docx2txt; then
    docx2txt "$FILE_PATH" -
  elif exist_command textutil; then
    textutil -stdout -cat txt "$FILE_PATH"
  fi
}

disable_auto_peek() {
  echo "__disable_auto_peek__"
}

mlr() {
  command mlr --icsv --opprint -C --key-color darkcyan --value-color grey70 head -n 500 && return
  handle_text
}

preview_sqlite3() {
  # Show EXIF metadata
  exiftool -s $EXIF_TAGS "$FILE_PATH" | bat -l yaml

  echo -e "\n--- Database Tables ---"
  sqlite3 "$FILE_PATH" .tables | tr ' ' '\n' | sort | bat -l plain

  echo -e "\n--- Database Schema ---"
  sqlite3 "$FILE_PATH" .schema | sed "s/;/;\n/g" | bat -l sql
}

process_netease_uc() {
  nc2mp3 --info "$FILE_PATH" | bat -l json --theme TwoDark
}

process_epub() {
  local cover="$(lsar "$FILE_PATH" | grep -E 'cover.*\.jpe?g')"
  if [ -z "$cover" ]; then
    return
  fi
  unzip -p -j "$FILE_PATH" "$cover"
}

process_icns() {
  sips -s format png "$1" --out "$CACHE"
}

process_ipa_thumbnail() {
  local app_icon_path="$(unzip -q -l "$FILE_PATH" | /usr/bin/grep -oE "Payload/.*\.app/AppIcon.*\.png" | head -n 1)"
  if [ -n "$app_icon_path" ]; then
    local tmp="$(mktemp)"
    unzip -p -j "$FILE_PATH" "$app_icon_path" >|"$tmp"
    process_icns "$tmp"
    rm "$tmp"
  fi
}

process_ipa_info() {
  local info_plist_path="$(unzip -q -l "$FILE_PATH" | /usr/bin/grep -oE "Payload/.*\.app/Info.plist")"
  if [ -n "$info_plist_path" ]; then
    local tmp="$(mktemp)"
    unzip -p -j "$FILE_PATH" "$info_plist_path" >|"$tmp"
    mac_show_app_info "$tmp"
    rm "$tmp"
  else
    process_compress_file
  fi
}

process_baksmali() {
  baksmali list class "${FILE_PATH}" | tree -C --fromfile .
}

process_xlsx() {
  xlsx2csv -- "$FILE_PATH" | head -n 500 | mlr
}

process_xls() {
  xls2csv -- "$FILE_PATH" | head -n 500 | mlr
}

find_aapt_path() {
  if exist_command aapt; then
    aapt="$(which aapt)"
  else
    local aapt_path="$(ls "${HOME}/Library/Android/sdk/build-tools"/*/aapt | sort --reverse | head -n 1)"
    if [ -x "$aapt_path" ]; then
      aapt="$aapt_path"
    fi
  fi
}

aapt_dump_badging() {
  if [ -z "${aapt_dump}" ]; then
    aapt_dump="$("$aapt" dump badging "$FILE_PATH")"
  fi
  echo -e "$aapt_dump"
}

process_apk_icon() {
  local pattern=" icon='([^']*)'"
  local line="$(aapt_dump_badging | grep "^application: ")"
  [[ "$line" =~ $pattern ]] && icon_path="${BASH_REMATCH[1]}"
  if [[ "${icon_path##*.}" != "xml" ]]; then # adaptive icon is unsupported
    unzip -p -j "$FILE_PATH" "$icon_path"
  fi
}

process_apk_info() {
  local dump="$(aapt_dump_badging)"
  local package_line="$(head -n 1 <<<"$dump")"
  local application_line="$(grep "^application: " <<<"$dump")"

  local package_name version_name label_name

  local pattern=" name='([^']*)'"
  [[ "$package_line" =~ $pattern ]] && package_name="${BASH_REMATCH[1]}"

  local pattern=" versionName='([^']*)'"
  [[ "$package_line" =~ $pattern ]] && version_name="${BASH_REMATCH[1]}"

  local pattern=" label='([^']*)'"
  [[ "$application_line" =~ $pattern ]] && label_name="${BASH_REMATCH[1]}"

  echo -e "App name: $label_name\nPackage: $package_name\nVersion name: $version_name\n" | bat -l yaml
}

mac_show_app_info() {
  /usr/libexec/PlistBuddy -c "Print" "$1" |
    grep -E "CFBundleIdentifier|CFBundleDisplayName|CFBundleName|CFBundleShortVersionString" |
    sed "s/^ *//g" | bat -l ini
}

mac_echo_app_icon_path() {
  local info_plist="$1"
  local icon_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$info_plist")"
  local icon_path="$(find "${info_plist%/*}/Resources" -type f -name "${icon_name}*")"
  local tmp="$(mktemp -u).png"
  sips -s format png "$icon_path" --out "$tmp" &>/dev/null
  echo "$tmp"
}

load_dmg_app_info() {
  if [ -n "${mac_app_info}" ]; then
    return
  fi
  local mount_path="$(hdiutil attach "$FILE_PATH" | grep -oE "/Volumes/.*")"
  if [ -z "$mount_path" ]; then
    hdiutil info
    exit
  fi
  local info_plist="$(echo "$mount_path"/*.app/Contents/Info.plist)"
  if [ -f "$info_plist" ]; then
    mac_app_info="$(mac_show_app_info "$info_plist")"
    mac_icon_path="$(mac_echo_app_icon_path "$info_plist")"
  else
    # fallback to tree contents
    mac_app_info="$(
      echo "# app directory not found, fallback to tree two levels of depth:" | bat -l sh
      tree -C -L 2 "$mount_path"
    )"
  fi
  hdiutil detach "$mount_path" >/dev/null
}

process_dmg_app_info() {
  load_dmg_app_info
  echo -e "$mac_app_info"
}

process_dmg_app_icon() {
  load_dmg_app_info
  if [ -n "${mac_icon_path}" ]; then
    cat "$mac_icon_path"
    rm "$mac_icon_path"
  fi
}

process_ttf() {
  local charset=$'abcdefghijklmnopqrstuvwxyz\nABCDEFGHIJKLMNOPQRSTUVWXYZ\n1234567890\n!@#$\%^&*()-_=+[{]}\n\\\\|;:\'",<.>/?`~'
  convert -font "$1" -background black -fill white -pointsize 50 "label:$charset" "$CACHE"
}

process_woff() {
  local tmp_otf="$(mktemp -u).otf"
  "${SCRIPT_FOLDER}/woff2otf.py" "$1" "$tmp_otf"
  process_ttf "$tmp_otf"
  rm "$tmp_otf"
}

process_woff2() {
  local tmp="$(mktemp -u)"
  local tmp_woff2="${tmp}.woff2"
  local tmp_ttf="${tmp}.ttf"
  cp "$FILE_PATH" "$tmp_woff2"
  woff2_decompress "$tmp_woff2"
  process_ttf "$tmp_ttf"
  rm "$tmp_woff2" "$tmp_ttf"
}

handle_extension() {
  case "${FILE_EXTENSION_LOWER}" in
  # rar)
  #   ## Avoid password prompt by providing empty password
  #   unrar lt -p- -- "${FILE_PATH}" && exit
  #   exit
  #   ;;
  # 7z)
  #   ## Avoid password prompt by providing empty password
  #   7z l -p -- "${FILE_PATH}" && exit
  #   exit
  #   ;;
  mp3 | flac | wav | m4a)
    handle_audio
    ;;
  json)
    handle_json
    ;;
  pdf)
    handle_pdf
    ;;
  toml | tmpl | xml | arsc)
    handle_text
    ;;
  md)
    # Markdown is handled by piper plugin in yazi.toml
    handle_text
    ;;
  ipynb)
    handle_ipynb && exit
    handle_text
    ;;
  dex)
    with_cache -cat -- process_baksmali
    ;;
  apk)
    find_aapt_path
    if [ -n "${aapt}" ]; then
      with_cache -img -ext icon -- process_apk_icon
      with_cache -cat -- process_apk_info
    else
      handle_compress
    fi
    # handle_compress
    ;;
  csv | tsv)
    mlr <"${FILE_PATH}"
    ;;
  uc!)
    with_cache -cat -- process_netease_uc
    ;;
  sqlite3 | sqlite)
    preview_sqlite3
    ;;
  so | dylib)
    handle_bin
    ;;
  torrent)
    transmission-show -- "$FILE_PATH"
    ;;
  doc)
    with_cache -cat -- process_doc
    ;;
  docx | htm | html | xhtml | rtf)
    with_cache -cat -- process_docx
    ;;
  xlsx)
    with_cache -cat -- process_xlsx
    ;;
  xls)
    with_cache -cat -- process_xls
    ;;
  svg)
    with_cache -img -ext png -- process_svg
    exiftool '-ImageSize' '-*' "${FILE_PATH}" | bat -l yaml
    ;;
  epub)
    with_cache -img -- process_epub
    exiftool '--File*' "$FILE_PATH" | bat -l yaml
    ;;
  plist)
    if [ -x "/usr/libexec/PlistBuddy" ]; then
      /usr/libexec/PlistBuddy -c "print" Info.plist | bat -l nix
    else
      handle_text
    fi
    ;;
  icns)
    with_cache -img -ext png -no-stdout -- process_icns "$FILE_PATH"
    exiftool '-ImageSize' '-*' "${FILE_PATH}" | bat -l yaml
    ;;
  ipa)
    # process_ipa_thumbnail
    with_cache -img -ext png -no-stdout -- process_ipa_thumbnail
    with_cache -cat -- process_ipa_info
    ;;
  dmg)
    # hdiutil imageinfo "$FILE_PATH" | bat -l yaml
    with_cache -img -ext png -- process_dmg_app_icon
    with_cache -cat -- process_dmg_app_info
    # load_dmg_app_info
    # echo "$mac_app_info  $mac_icon_path"
    ;;
  ttf | ttc | otf)
    with_cache -img --no-stdout -ext png -- process_ttf "$FILE_PATH"
    exiftool "$FILE_PATH" | bat -l yaml
    ;;
  woff)
    with_cache -img --no-stdout -ext png -- process_woff "$FILE_PATH"
    ;;
  woff2)
    with_cache -img --no-stdout -ext png -- process_woff2 "$FILE_PATH"
    ;;
  ansi)
    cat "$FILE_PATH"
    ;;
  cast)
    asciinema cat "$FILE_PATH"
    ;;
  ##Archive
  7z | rar | ace | alz | arc | arj | bz | bz2 | cab | cpio | deb | gz | jar | lha | lz | lzh | lzma | lzo | \
    rpm | rz | t7z | tar | tbz | tbz2 | tgz | tlz | txz | tz | tzo | war | xpi | xz | z | zip | nds | iso | pkg)
    handle_compress
    ;;
  *)
    return
    ;;
  esac
  exit
}

handle_mime() {
  local mimetype="${1}"

  case "${mimetype}" in
  *archive | *zip)
    handle_compress
    ;;
  text/* | */xml | */javascript)
    handle_text
    ;;
  */json)
    handle_json
    ;;
  image/*)
    handle_image
    ;;
  video/*)
    handle_video
    ;;
  audio/*)
    handle_audio
    ;;
  */pdf)
    handle_pdf
    ;;
  */x-sharedlib | */x-object | */x-mach-binary | *executable)
    handle_bin
    ;;
  *sqlite3)
    preview_sqlite3
    ;;
  *)
    return
    ;;
  esac
  exit
}

if ! [[ -f "$FILE_PATH" ]]; then
  die "<No such file>"
fi

if ! [[ -r "$FILE_PATH" ]]; then
  die "<Permission denied>"
fi

# File size check - skip very large files (> 10MB) for performance
if [[ -f "$FILE_PATH" ]]; then
  local file_size=$(stat -c%s "$FILE_PATH" 2>/dev/null || stat -f%z "$FILE_PATH" 2>/dev/null || echo "0")
  if [[ $file_size -gt 10485760 ]]; then  # 10MB
    echo_err "⚠ File size exceeds 10MB, preview disabled for performance"
    echo "File size: $(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "${file_size} bytes")"
    exit 0
  fi
fi

# Handle directories with enhanced tree view (from enhanced-preview)
if [[ -d "$FILE_PATH" ]]; then
  if exist_command eza; then
    # Enhanced directory preview with eza tree view (3 levels)
    eza --tree --level=3 --icons=never --color=always "$FILE_PATH" 2>/dev/null | head -n "$PREVIEW_HEIGHT" && exit
  elif exist_command tree; then
    # Fallback to tree if eza not available
    tree -C -L 3 "$FILE_PATH" 2>/dev/null | head -n "$PREVIEW_HEIGHT" && exit
  else
    # Basic ls fallback
    ls -lah --color=always "$FILE_PATH" 2>/dev/null | head -n "$PREVIEW_HEIGHT" && exit
  fi
  exit
fi

handle_extension
handle_mime "$(file -bL --mime-type -- "${FILE_PATH}")"

# fallback to display raw text
head -c 100000 "$FILE_PATH" | LC_CTYPE=C LANG=C sed 's/[^[:print:]]//g' | fold -w "$PREVIEW_WIDTH"

#!/usr/bin/env bash

# Start and stop a screenrecording, which will be saved to ~/Videos by default.
# Alternative location can be set via OS_SCREENRECORD_DIR or XDG_VIDEOS_DIR ENVs.
# Resolution is capped to 4K for monitors above 4K, native otherwise.
# Override via --resolution= (e.g. --resolution=1920x1080, --resolution=0x0 for native).

set -euo pipefail

[[ -f "$HOME/.config/user-dirs.dirs" ]] && source "$HOME/.config/user-dirs.dirs"
readonly DEFAULT_OUTPUT_DIR="${OS_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"

DESKTOP_AUDIO="false"
MICROPHONE_AUDIO="false"
WEBCAM="false"
WEBCAM_DEVICE=""
RESOLUTION=""
STOP_RECORDING="false"
CAPTURE_SOURCE="portal"
FPS="60"
QUALITY="very_high"
RECORD_CURSOR="true"
OUTPUT_DIR_OVERRIDE=""
RECORDING_FILE="/tmp/os-screenrecord-filename"

for arg in "$@"; do
  case "$arg" in
    --with-desktop-audio) DESKTOP_AUDIO="true" ;;
    --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
    --with-webcam) WEBCAM="true" ;;
    --webcam-device=*) WEBCAM_DEVICE="${arg#*=}" ;;
    --resolution=*) RESOLUTION="${arg#*=}" ;;
    --capture-source=*) CAPTURE_SOURCE="${arg#*=}" ;;
    --fps=*) FPS="${arg#*=}" ;;
    --quality=*) QUALITY="${arg#*=}" ;;
    --record-cursor=*) RECORD_CURSOR="${arg#*=}" ;;
    --output-dir=*) OUTPUT_DIR_OVERRIDE="${arg#*=}" ;;
    --stop-recording) STOP_RECORDING="true" ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: $0 [--with-desktop-audio] [--with-microphone-audio] [--with-webcam] [--webcam-device=PATH] [--resolution=WxH] [--capture-source=portal|screen] [--fps=N] [--quality=medium|high|very_high] [--record-cursor=true|false] [--output-dir=PATH] [--stop-recording]" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$OUTPUT_DIR_OVERRIDE" ]]; then
  OUTPUT_DIR="$OUTPUT_DIR_OVERRIDE"
fi

if [[ "$OUTPUT_DIR" == "~" ]]; then
  OUTPUT_DIR="$HOME"
elif [[ "$OUTPUT_DIR" == "~/"* ]]; then
  OUTPUT_DIR="$HOME/${OUTPUT_DIR#~/}"
fi

mkdir -p "$OUTPUT_DIR"

cleanup_webcam() {
  pkill -f "WebcamOverlay" 2>/dev/null || true
}

start_webcam_overlay() {
  cleanup_webcam

  # Auto-detect first available webcam if none specified
  if [[ -z "$WEBCAM_DEVICE" ]]; then
    WEBCAM_DEVICE=$(v4l2-ctl --list-devices 2>/dev/null | grep -m1 "^[[:space:]]*/dev/video" | tr -d '\t')
    if [[ -z "$WEBCAM_DEVICE" ]]; then
      notify-send "No webcam devices found" -u critical -t 3000
      return 1
    fi
  fi

  if [[ ! -c "$WEBCAM_DEVICE" ]]; then
    notify-send "Warning" "Webcam device $WEBCAM_DEVICE not found" -t 2000
    return 1
  fi

  # Get monitor scale
  local scale
  scale=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .scale' | head -1 || echo "1.0")

  # Target width (base 360px, scaled to monitor)
  local target_width
  target_width=$(awk "BEGIN {printf \"%.0f\", 360 * $scale}")

  # Try preferred 16:9 resolutions in order, use first available
  local preferred_resolutions=("640x360" "1280x720" "1920x1080")
  local video_size_arg=""
  local available_formats
  available_formats=$(v4l2-ctl --list-formats-ext -d "$WEBCAM_DEVICE" 2>/dev/null || echo "")

  for resolution in "${preferred_resolutions[@]}"; do
    if echo "$available_formats" | grep -q "$resolution"; then
      video_size_arg="-video_size $resolution"
      break
    fi
  done

  if ! command -v ffplay &>/dev/null; then
    notify-send "Error" "ffplay not found" -u critical
    return 1
  fi

  # shellcheck disable=SC2086
  ffplay -f v4l2 $video_size_arg -framerate 30 "$WEBCAM_DEVICE" \
    -vf "scale=${target_width}:-1" \
    -window_title "WebcamOverlay" \
    -noborder \
    -fflags nobuffer -flags low_delay \
    -probesize 32 -analyzeduration 0 \
    -loglevel quiet &
  sleep 1
}

default_resolution() {
  local width height
  read -r width height < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | "\(.width) \(.height)"')
  if ((width > 3840 || height > 2160)); then
    echo "3840x2160"
  else
    echo "0x0"
  fi
}

start_screenrecording() {
  local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local audio_devices=""
  local audio_args=()
  local capture_target="$CAPTURE_SOURCE"
  local cursor_flag="yes"

  [[ "$DESKTOP_AUDIO" == "true" ]] && audio_devices+="default_output"

  if [[ "$MICROPHONE_AUDIO" == "true" ]]; then
    # Merge audio tracks into one - separate tracks only play one at a time in most players
    [[ -n "$audio_devices" ]] && audio_devices+="|"
    audio_devices+="default_input"
  fi

  [[ -n "$audio_devices" ]] && audio_args+=(-a "$audio_devices" -ac aac)

  local resolution="${RESOLUTION:-$(default_resolution)}"
  [[ "$RECORD_CURSOR" == "false" ]] && cursor_flag="no"

  case "$capture_target" in
    portal) ;;
    screen|fullscreen) capture_target="screen" ;;
    *)
      notify-send "Error" "Unsupported capture source: $capture_target" -u critical
      exit 1
      ;;
  esac

  if ! command -v gpu-screen-recorder &>/dev/null; then
    notify-send "Error" "gpu-screen-recorder not found" -u critical
    exit 1
  fi

  gpu-screen-recorder -w "$capture_target" -k auto -s "$resolution" -f "$FPS" -q "$QUALITY" -cursor "$cursor_flag" -fm cfr -fallback-cpu-encoding yes -o "$filename" "${audio_args[@]}" &
  local pid=$!

  # Wait for recording to actually start (file appears after portal selection)
  while kill -0 "$pid" 2>/dev/null && [[ ! -f "$filename" ]]; do
    sleep 0.2
  done

  if kill -0 "$pid" 2>/dev/null; then
    echo "$filename" >"$RECORDING_FILE"
    toggle_screenrecording_indicator
  fi
}

stop_screenrecording() {
  pkill -SIGINT -f "^gpu-screen-recorder"  # SIGINT required to save video properly

  # Wait a maximum of 5 seconds to finish before hard killing
  local count=0
  while pgrep -f "^gpu-screen-recorder" >/dev/null && ((count < 50)); do
    sleep 0.1
    count=$((count + 1))
  done

  toggle_screenrecording_indicator
  cleanup_webcam

  if pgrep -f "^gpu-screen-recorder" >/dev/null; then
    pkill -9 -f "^gpu-screen-recorder"
    notify-send "Screen recording error" "Recording process had to be force-killed. Video may be corrupted." -u critical -t 5000
  else
    trim_first_frame
    local filename
    filename=$(cat "$RECORDING_FILE" 2>/dev/null || echo "")
    local preview="${filename%.mp4}-preview.png"

    # Generate a preview thumbnail from the first frame
    ffmpeg -y -i "$filename" -ss 00:00:00.1 -vframes 1 -q:v 2 "$preview" -loglevel quiet 2>/dev/null || true

    (
      ACTION=$(notify-send "Screen recording saved" "Open with Super + Alt + , (or click this)" -t 10000 -i "${preview:-$filename}" -A "default=open" || echo "")
      [[ "$ACTION" == "default" ]] && mpv "$filename"
      rm -f "$preview"
    ) &
  fi

  rm -f "$RECORDING_FILE"
}

toggle_screenrecording_indicator() {
  pkill -RTMIN+8 waybar 2>/dev/null || true
}

screenrecording_active() {
  pgrep -f "^gpu-screen-recorder" >/dev/null
}

trim_first_frame() {
  local latest
  latest=$(cat "$RECORDING_FILE" 2>/dev/null || echo "")

  if [[ -n "$latest" && -f "$latest" ]]; then
    local trimmed="${latest%.mp4}-trimmed.mp4"
    if ffmpeg -y -ss 0.1 -i "$latest" -c copy "$trimmed" -loglevel quiet 2>/dev/null; then
      mv "$trimmed" "$latest"
    else
      rm -f "$trimmed"
    fi
  fi
}

if screenrecording_active; then
  stop_screenrecording
elif [[ "$STOP_RECORDING" == "true" ]]; then
  exit 1
else
  [[ "$WEBCAM" == "true" ]] && start_webcam_overlay

  start_screenrecording || cleanup_webcam
fi

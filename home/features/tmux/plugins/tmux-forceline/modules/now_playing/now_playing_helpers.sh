#!/usr/bin/env bash
# Now Playing Helper Functions for tmux-forceline v3.0
# Cross-platform media player detection and monitoring

# Default configurations
NOW_PLAYING_MAX_LEN="${FORCELINE_NOW_PLAYING_MAX_LEN:-30}"
NOW_PLAYING_TRUNCATE_SYMBOL="${FORCELINE_NOW_PLAYING_TRUNCATE_SYMBOL:-…}"
NOW_PLAYING_SHOW_PLAYER="${FORCELINE_NOW_PLAYING_SHOW_PLAYER:-no}"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Truncate text if necessary
truncate_text() {
    local text="$1"
    local max_len="$2"
    local truncate_symbol="$3"
    
    if [ -n "$max_len" ] && [ "${#text}" -gt "$max_len" ]; then
        echo "${text:0:$((max_len-1))}$truncate_symbol"
    else
        echo "$text"
    fi
}

# Get playing status from Spotify (Linux/macOS)
get_spotify_status() {
    local player="spotify"
    local status=""
    local artist=""
    local title=""
    
    if command_exists playerctl; then
        # Linux with playerctl
        status=$(playerctl --player=spotify status 2>/dev/null)
        if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
            artist=$(playerctl --player=spotify metadata artist 2>/dev/null)
            title=$(playerctl --player=spotify metadata title 2>/dev/null)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with AppleScript
        local spotify_state
        spotify_state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
        if [ "$spotify_state" = "playing" ] || [ "$spotify_state" = "paused" ]; then
            status="$spotify_state"
            artist=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)
            title=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)
        fi
    fi
    
    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo "$status:$player:$artist:$title"
        return 0
    fi
    
    return 1
}

# Get playing status from Apple Music (macOS)
get_apple_music_status() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 1
    fi
    
    local player="apple_music"
    local status=""
    local artist=""
    local title=""
    
    local music_state
    music_state=$(osascript -e 'tell application "Music" to player state as string' 2>/dev/null)
    if [ "$music_state" = "playing" ] || [ "$music_state" = "paused" ]; then
        status="$music_state"
        artist=$(osascript -e 'tell application "Music" to artist of current track as string' 2>/dev/null)
        title=$(osascript -e 'tell application "Music" to name of current track as string' 2>/dev/null)
    fi
    
    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo "$status:$player:$artist:$title"
        return 0
    fi
    
    return 1
}

# Get playing status from Spotifyd via MPRIS when playing
get_spotifyd_status() {
    # Check if spotifyd is running
    if ! pgrep -f spotifyd >/dev/null 2>&1; then
        return 1
    fi
    
    # Try to get info via MPRIS - Spotifyd only exposes this when playing
    local mpris_service
    mpris_service=$(dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null | grep -o 'org\.mpris\.MediaPlayer2\.spotifyd' | head -1)
    
    if [ -n "$mpris_service" ]; then
        local status artist title
        status=$(dbus-send --print-reply --dest="$mpris_service" /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null | grep -o 'Playing\|Paused' | head -1)
        
        if [ -n "$status" ]; then
            local metadata
            metadata=$(dbus-send --print-reply --dest="$mpris_service" /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)
            
            artist=$(echo "$metadata" | grep -A1 'xesam:artist' | grep 'string' | sed 's/.*string "\([^"]*\)".*/\1/' | head -1)
            title=$(echo "$metadata" | grep -A1 'xesam:title' | grep 'string' | sed 's/.*string "\([^"]*\)".*/\1/' | head -1)
            
            if [ -n "$title" ]; then
                echo "$(echo "$status" | tr '[:upper:]' '[:lower:]'):spotifyd:${artist:-Unknown}:$title"
                return 0
            fi
        fi
    fi
    
    return 1
}

# Get playing status from MPD
get_mpd_status() {
    if ! command_exists mpc; then
        return 1
    fi
    
    local player="mpd"
    local mpc_output
    mpc_output=$(mpc current 2>/dev/null)
    
    if [ -z "$mpc_output" ]; then
        return 1
    fi
    
    local status
    status=$(mpc status | grep -o "\[playing\]" 2>/dev/null)
    if [ -n "$status" ]; then
        status="playing"
    else
        status=$(mpc status | grep -o "\[paused\]" 2>/dev/null)
        if [ -n "$status" ]; then
            status="paused"
        else
            return 1
        fi
    fi
    
    # Parse current track (format: "Artist - Title")
    local artist title
    if [[ "$mpc_output" =~ ^(.+)\ -\ (.+)$ ]]; then
        artist="${BASH_REMATCH[1]}"
        title="${BASH_REMATCH[2]}"
    else
        artist="Unknown"
        title="$mpc_output"
    fi
    
    echo "$status:$player:$artist:$title"
    return 0
}

# Get playing status from any available player
get_now_playing_status() {
    local show_player="$1"
    local max_len="$2"
    local truncate_symbol="$3"
    
    # Try different players in order of preference
    local status_output=""
    
    # Try Spotify first (desktop app)
    if status_output=$(get_spotify_status); then
        :
    # Try Spotifyd (headless Spotify daemon)
    elif status_output=$(get_spotifyd_status); then
        :
    # Try Apple Music on macOS
    elif status_output=$(get_apple_music_status); then
        :
    # Try MPD
    elif status_output=$(get_mpd_status); then
        :
    else
        return 1
    fi
    
    # Parse output: status:player:artist:title
    local status player artist title
    IFS=: read -r status player artist title <<< "$status_output"
    
    # Format output
    local result=""
    local track_info=""
    
    if [ -n "$artist" ] && [ -n "$title" ]; then
        track_info="$artist - $title"
    elif [ -n "$title" ]; then
        track_info="$title"
    else
        return 1
    fi
    
    # Truncate if necessary
    track_info=$(truncate_text "$track_info" "$max_len" "$truncate_symbol")
    
    # Add player name if requested
    if [ "$show_player" = "yes" ]; then
        result="[$player] $track_info"
    else
        result="$track_info"
    fi
    
    # Add status indicator
    case "$status" in
        "playing")
            echo "▶ $result"
            ;;
        "paused")
            echo "⏸ $result"
            ;;
        *)
            echo "$result"
            ;;
    esac
    
    return 0
}

# Get player icon based on detected player
get_player_icon() {
    local status_output=""
    
    if status_output=$(get_spotify_status); then
        echo "󰓇"  # Spotify icon
    elif status_output=$(get_spotifyd_status); then
        echo "󰓇"  # Spotify icon (same as regular Spotify)
    elif status_output=$(get_apple_music_status); then
        echo "󰎆"  # Apple Music icon
    elif status_output=$(get_mpd_status); then
        echo "󰎈"  # Music icon
    else
        echo "󰝚"  # Generic music icon
    fi
}
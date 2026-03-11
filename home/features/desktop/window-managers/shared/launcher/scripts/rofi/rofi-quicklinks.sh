#!/usr/bin/env bash
set -eu

## Applets : Quick Links

# Find and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_HELPERS=""
URL_HANDLER=""

if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-url-handler.sh" ]]; then
    URL_HANDLER="$HOME/.local/bin/scripts/system/os-url-handler.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-url-handler.sh" ]]; then
    URL_HANDLER="$SCRIPT_DIR/../../../../common/scripts/system/os-url-handler.sh"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

if [[ -n "$URL_HANDLER" ]]; then
    # shellcheck source=/dev/null
    source "$URL_HANDLER"
fi

# Import Current Theme
# source "$HOME"/.config/rofi/applets/shared/theme.bash
type="$HOME/.config/rofi/applets/type-3"
style='style-3.rasi'
theme="$type/$style"

# Check dependencies
if command -v check_rofi >/dev/null 2>&1; then
    check_rofi || exit 1
else
    if ! command -v rofi >/dev/null 2>&1; then
        echo "Error: rofi not found" >&2
        exit 1
    fi
fi

# Theme Elements
prompt='Quick Links'
BROWSER="${BROWSER:-firefox}"
mesg="Using '$BROWSER' as web browser"

if [[ ( "$theme" == *'type-1'* ) || ( "$theme" == *'type-3'* ) || ( "$theme" == *'type-5'* ) ]]; then
	list_col='1'
	list_row='6'
elif [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
	list_col='6'
	list_row='1'
fi

if [[ ( "$theme" == *'type-1'* ) || ( "$theme" == *'type-5'* ) ]]; then
	efonts="JetBrains Mono Nerd Font 10"
else
	efonts="JetBrains Mono Nerd Font 28"
fi

# Options
if [[ -f "$theme" ]]; then
    layout=$(grep 'USE_ICON' "$theme" 2>/dev/null | cut -d'=' -f2 | tr -d ' "'"'" || echo "YES")
else
    layout="YES"
fi
if [[ "$layout" == 'NO' ]]; then
	option_1="  Google"
	option_2="  Gmail"
	option_3="  Youtube"
	option_4="  Github"
	option_5="  Reddit"
	option_6="  Twitter"
else
	option_1=""
	option_2=""
	option_3=""
	option_4=""
	option_5=""
	option_6=""
fi

# Rofi CMD
rofi_cmd() {
	rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
		-theme-str 'textbox-prompt-colon {str: " ";}' \
		-theme-str "element-text {font: \"$efonts\";}" \
		-dmenu \
		-p "$prompt" \
		-mesg "$mesg" \
		-markup-rows \
		-theme $theme
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

# Execute Command
run_cmd() {
	local url=""
	case "$1" in
		'--opt1') url='https://www.google.com/' ;;
		'--opt2') url='https://mail.google.com/' ;;
		'--opt3') url='https://www.youtube.com/' ;;
		'--opt4') url='https://www.github.com/' ;;
		'--opt5') url='https://www.reddit.com/' ;;
		'--opt6') url='https://www.twitter.com/' ;;
		*) return 1 ;;
	esac

	if [[ -n "$url" ]]; then
		# Use shared open_url function if available
		if command -v open_url >/dev/null 2>&1; then
			if ! open_url "$url"; then
				notify-send "Error" "Failed to open: $url" 2>/dev/null || \
					echo "Error: Failed to open: $url" >&2
				return 1
			fi
		else
			# Fallback to xdg-open
			if ! xdg-open "$url" 2>/dev/null; then
				notify-send "Error" "Failed to open: $url" 2>/dev/null || \
					echo "Error: Failed to open: $url" >&2
				return 1
			fi
		fi
	fi
}

# Actions
chosen="$(run_rofi)"
case $chosen in
		$option_1)
		run_cmd --opt1
				;;
		$option_2)
		run_cmd --opt2
				;;
		$option_3)
		run_cmd --opt3
				;;
		$option_4)
		run_cmd --opt4
				;;
		$option_5)
		run_cmd --opt5
				;;
		$option_6)
		run_cmd --opt6
				;;
esac

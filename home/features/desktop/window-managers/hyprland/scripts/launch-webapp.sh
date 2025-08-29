#!/usr/bin/env bash

# Launch web application using the default browser
# Usage: launch-webapp.sh <URL> [additional_args...]

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Error: No URL provided" >&2
    echo "Usage: $0 <URL> [additional_args...]" >&2
    exit 1
fi

# Get default browser, fallback to known browsers if xdg-settings fails
browser=$(xdg-settings get default-web-browser 2>/dev/null)

# If xdg-settings fails, try to find a suitable browser
if [ -z "$browser" ] || [ "$?" -ne 0 ]; then
    for app in google-chrome.desktop brave-browser.desktop chromium.desktop firefox.desktop; do
        if command -v "${app%%.desktop}" >/dev/null 2>&1; then
            browser="$app"
            break
        fi
    done
fi

# Ensure we have a browser that supports --app mode for Chrome-based browsers
case $browser in
google-chrome* | brave-browser* | microsoft-edge* | opera* | vivaldi*) ;;
*) browser="chromium.desktop" ;;
esac

# Find the browser executable
browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' {~/.local,~/.nix-profile,/usr}/share/applications/"$browser" 2>/dev/null | head -1)

# If we couldn't find the executable through desktop files, try direct commands
if [ -z "$browser_exec" ]; then
    case $browser in
        google-chrome*) browser_exec="google-chrome-stable" ;;
        chromium*) browser_exec="chromium" ;;
        *) browser_exec="chromium" ;;
    esac
fi

# Check if browser executable exists
if ! command -v "$browser_exec" >/dev/null 2>&1; then
    echo "Error: Browser executable '$browser_exec' not found" >&2
    exit 1
fi

# Launch the web app
exec setsid uwsm app -- "$browser_exec" --app="$1" "${@:2}"

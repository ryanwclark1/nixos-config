#!/usr/bin/env bash

# Show current date and time as notification

# Get current date/time information
CURRENT_TIME=$(date +"%H:%M:%S")
CURRENT_DATE=$(date +"%A, %B %d, %Y")
WEEK_NUMBER=$(date +"%V")
DAY_OF_YEAR=$(date +"%j")

# Get timezone
TIMEZONE=$(date +"%Z %z")

# Create notification message
MESSAGE="Time: $CURRENT_TIME
Date: $CURRENT_DATE
Week: $WEEK_NUMBER • Day: $DAY_OF_YEAR
Zone: $TIMEZONE"

# Send notification
notify-send "🕐 Current Time" "$MESSAGE"

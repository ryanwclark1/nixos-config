#!/usr/bin/env bash
# Simple disk usage script for tmux-forceline v2.0

# Get disk usage percentage for root filesystem
df -h / | awk 'NR==2 {print $5}'
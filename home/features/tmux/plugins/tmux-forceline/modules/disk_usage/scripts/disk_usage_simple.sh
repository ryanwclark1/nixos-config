#!/usr/bin/env bash
# Simple disk usage script for tmux-forceline v3.0

# Get disk usage percentage for root filesystem
df -h / | awk 'NR==2 {print $5}'
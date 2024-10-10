#!/usr/bin/env bash


while true; do
  # Read the one-minute load average directly from /proc/loadavg
  read one_minute _ < /proc/loadavg

  # Format the one-minute load average to two significant digits
  one_minute=$(printf "%.2g" "$one_minute")
  echo "$one_minute"
  sleep 1
done
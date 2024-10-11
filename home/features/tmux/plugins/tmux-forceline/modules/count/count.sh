#!/usr/bin/env bash

print () {
tmux_counter=0
  while true; do
    tmux_counter=$((tmux_counter + 1))
    echo "$tmux_counter"
    sleep 1
  done
}

main () {
  print
}

main
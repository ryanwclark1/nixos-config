#!/usr/bin/env bash

# Open a new terminal in the current terminal's working directory

current_dir=$(terminal-cwd)
cd "$current_dir" && kitty &
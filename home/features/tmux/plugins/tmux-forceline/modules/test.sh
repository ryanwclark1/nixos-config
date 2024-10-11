#!/usr/bin/env bash

# Initialize the number
force_number=0

# Infinite loop
while true; do
  # Print the current number
  echo $force_number

  # Wait for 10 seconds
  sleep 10

  # Increment the number
  force_number=$((force_number + 1))
  echo $force_number
done
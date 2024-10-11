#!/usr/bin/env bash

# Initialize the number
number=0

# Infinite loop
while true; do
  # Print the current number
  echo $number

  # Wait for 10 seconds
  sleep 10

  # Increment the number
  number=$((number + 1))
  echo $number
done
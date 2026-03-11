#!/usr/bin/env bash
# Decrease audio volume - delegates to os-volume
exec os-volume decrease "$@"

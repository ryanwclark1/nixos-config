#!/usr/bin/env bash
# Increase audio volume - delegates to os-volume
exec os-volume increase "$@"

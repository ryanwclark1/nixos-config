#!/usr/bin/env bash
# Toggle audio mute - delegates to os-volume
exec os-volume toggle "$@"

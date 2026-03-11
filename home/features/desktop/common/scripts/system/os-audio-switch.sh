#!/usr/bin/env bash
# Switch audio output device - delegates to os-volume
exec os-volume switch "$@"

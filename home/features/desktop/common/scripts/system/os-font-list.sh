#!/usr/bin/env bash

set -euo pipefail

fc-list :spacing=100 -f "%{family[0]}\n" 2>/dev/null | grep -v -i -E 'emoji|signwriting' | sort -u || echo ""

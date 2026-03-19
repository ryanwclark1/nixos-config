#!/usr/bin/env bash
# OCR text extraction script for OcrService
# Usage: qs-ocr <image_path>
# Output: OK|<extracted text> or ERROR|<reason>

set -uo pipefail

IMAGE_PATH="${1:-}"
LANGUAGE="${2:-eng}"

if [[ -z "$IMAGE_PATH" ]]; then
  echo "ERROR|no image path provided"
  exit 1
fi

if [[ ! -f "$IMAGE_PATH" ]]; then
  echo "ERROR|image file not found: $IMAGE_PATH"
  exit 1
fi

if ! command -v tesseract >/dev/null 2>&1; then
  echo "ERROR|missing dependency: tesseract"
  exit 1
fi

TEXT=$(tesseract "$IMAGE_PATH" stdout -l "$LANGUAGE" 2>/dev/null)

if [[ -z "$TEXT" || "$TEXT" =~ ^[[:space:]]*$ ]]; then
  echo "ERROR|no text detected"
  exit 0
fi

# Copy to clipboard
if command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$TEXT" | wl-copy >/dev/null 2>&1 || true
fi

echo "OK|${TEXT}"

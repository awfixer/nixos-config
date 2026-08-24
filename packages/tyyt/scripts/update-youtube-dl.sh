#!/usr/bin/env bash
# Refresh vendored yt-dlp (youtube-dl) source + standalone Linux binary.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-2026.07.04}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching yt-dlp ${TAG} source…"
curl -fsSL -o "$TMP/src.tar.gz" \
  "https://github.com/yt-dlp/yt-dlp/archive/refs/tags/${TAG}.tar.gz"
rm -rf "$ROOT/vendor/youtube-dl"
mkdir -p "$ROOT/vendor"
tar -xzf "$TMP/src.tar.gz" -C "$ROOT/vendor"
mv "$ROOT/vendor/yt-dlp-${TAG}" "$ROOT/vendor/youtube-dl"
rm -rf "$ROOT/vendor/youtube-dl/.github" \
       "$ROOT/vendor/youtube-dl/test" \
       "$ROOT/vendor/youtube-dl/docs" \
       "$ROOT/vendor/youtube-dl/devscripts" 2>/dev/null || true

echo "Fetching standalone Linux binary…"
mkdir -p "$ROOT/vendor/bin"
curl -fsSL -o "$ROOT/vendor/bin/youtube-dl" \
  "https://github.com/yt-dlp/yt-dlp/releases/download/${TAG}/yt-dlp_linux"
chmod +x "$ROOT/vendor/bin/youtube-dl"

echo "Vendored version: $("$ROOT/vendor/bin/youtube-dl" --version)"
echo "Update vendor/README.md pin if needed."

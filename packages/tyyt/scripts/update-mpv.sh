#!/usr/bin/env bash
# Refresh vendored mpv source + Nix-built binary (Linux/Nix store-linked).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-v0.41.0}"
# Strip leading v for tarball directory name conventions if needed
VER="${TAG#v}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! command -v nix-build >/dev/null 2>&1 && ! command -v nix >/dev/null 2>&1; then
  echo "error: Nix is required to build vendor/bin/mpv" >&2
  exit 1
fi

echo "Fetching mpv ${TAG} source…"
curl -fsSL -o "$TMP/src.tar.gz" \
  "https://github.com/mpv-player/mpv/archive/refs/tags/${TAG}.tar.gz"
rm -rf "$ROOT/vendor/mpv"
mkdir -p "$ROOT/vendor"
tar -xzf "$TMP/src.tar.gz" -C "$ROOT/vendor"
# GitHub tarball extracts to mpv-<tag without v? or mpv-0.41.0>
if [ -d "$ROOT/vendor/mpv-${VER}" ]; then
  mv "$ROOT/vendor/mpv-${VER}" "$ROOT/vendor/mpv"
elif [ -d "$ROOT/vendor/mpv-${TAG}" ]; then
  mv "$ROOT/vendor/mpv-${TAG}" "$ROOT/vendor/mpv"
else
  echo "error: unexpected tarball layout under vendor/" >&2
  ls -la "$ROOT/vendor" >&2
  exit 1
fi
rm -rf "$ROOT/vendor/mpv/.github" \
       "$ROOT/vendor/mpv/DOCS" \
       "$ROOT/vendor/mpv/ci" \
       "$ROOT/vendor/mpv/test" \
       "$ROOT/vendor/mpv/.gitignore" 2>/dev/null || true

echo "Building mpv via Nix and copying binary…"
mkdir -p "$ROOT/vendor/bin"
if command -v nix-build >/dev/null 2>&1; then
  nix-build -E 'with import <nixpkgs> {}; mpv' -o "$TMP/mpv-out"
  cp -L "$TMP/mpv-out/bin/mpv" "$ROOT/vendor/bin/mpv"
else
  nix build nixpkgs#mpv -o "$TMP/mpv-out"
  cp -L "$TMP/mpv-out/bin/mpv" "$ROOT/vendor/bin/mpv"
fi
chmod +x "$ROOT/vendor/bin/mpv"

echo "Vendored binary version:"
"$ROOT/vendor/bin/mpv" --version | head -n 1 || true
echo "Source tree: $ROOT/vendor/mpv (tag ${TAG})"
echo "Update vendor/README.md and README.md pin if needed."

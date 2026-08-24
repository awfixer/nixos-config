{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    pkg-config
    gtk4
    libadwaita
    openssl
    # Optional: only needed if vendor/bin/youtube-dl is missing (source path).
    python3
  ];

  shellHook = ''
    echo "tyyt dev shell — extractors/players are vendored under vendor/"
    echo "  youtube-dl: vendor/bin/youtube-dl  (or vendor/youtube-dl + python3)"
    echo "  mpv:        vendor/bin/mpv         (./scripts/update-mpv.sh if missing)"
    if [ ! -x vendor/bin/mpv ]; then
      echo "WARNING: vendor/bin/mpv missing — run ./scripts/update-mpv.sh"
    fi
    echo "try: cargo run"
  '';
}

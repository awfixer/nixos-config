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
    # Runtime dependencies, resolved from PATH during development.
    yt-dlp
    mpv
  ];

  shellHook = ''
    echo "tyyt dev shell — extractor/player come from the system (nixpkgs)"
    echo "  yt-dlp: $(command -v yt-dlp || echo MISSING)"
    echo "  mpv:    $(command -v mpv || echo MISSING)"
    echo "try: cargo run"
  '';
}

{ pkgs ? import <nixpkgs> { } }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "tyyt";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = with pkgs; [
    gtk4
    libadwaita
    openssl
  ];

  # youtube-dl is vendored under vendor/ — not taken from nixpkgs.
  # mpv is resolved at runtime via $out/libexec/tyyt/mpv (wrapper to nixpkgs mpv).
  doCheck = false;

  # Keep vendored extractor out of the cargo "clean" src filter.
  # (rustPlatform already includes normal source; ensure vendor is present.)
  cargoBuildFlags = [ ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "$out/libexec/tyyt"
    )
  '';

  postInstall = ''
    mkdir -p $out/libexec/tyyt
    mkdir -p $out/share/tyyt
    mkdir -p $out/share/applications

    # Bundled mpv: GC-safe wrapper to nixpkgs mpv (not a system package on PATH).
    cat > $out/libexec/tyyt/mpv <<EOF
#!${pkgs.runtimeShell}
exec ${pkgs.mpv}/bin/mpv "\$@"
EOF
    chmod +x $out/libexec/tyyt/mpv

    # Prefer the standalone binary (no Python). Fall back to a Python launcher
    # over the vendored source tree for non-x86_64 or if the binary is absent.
    if [ -f vendor/bin/youtube-dl ]; then
      install -Dm755 vendor/bin/youtube-dl $out/libexec/tyyt/youtube-dl
    fi

    if [ -d vendor/youtube-dl ]; then
      cp -a vendor/youtube-dl $out/share/tyyt/youtube-dl
    fi

    if [ ! -x $out/libexec/tyyt/youtube-dl ]; then
      # Portable launcher: python3 + vendored yt_dlp package
      cat > $out/libexec/tyyt/youtube-dl <<EOF
#!${pkgs.python3.interpreter}
import runpy, sys
sys.path.insert(0, "$out/share/tyyt/youtube-dl")
sys.argv[0] = "youtube-dl"
runpy.run_module("yt_dlp", run_name="__main__")
EOF
      chmod +x $out/libexec/tyyt/youtube-dl
    fi

    cat > $out/share/applications/dev.tyyt.Tyyt.desktop <<EOF
[Desktop Entry]
Name=tyyt
Comment=Lightweight YouTube client with adblock-rust
Exec=tyyt
Icon=video-x-generic
Type=Application
Categories=AudioVideo;Player;Network;
Terminal=false
EOF
  '';

  meta = with pkgs.lib; {
    description = "Lightweight GTK4 YouTube client with vendored youtube-dl (yt-dlp), bundled mpv, and adblock-rust";
    homepage = "https://github.com/awfixer/tyyt";
    license = licenses.gpl3Plus;
    mainProgram = "tyyt";
    platforms = platforms.linux;
  };
}

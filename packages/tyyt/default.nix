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
  ];

  doCheck = false;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "$out/libexec/tyyt"
    )
  '';

  postInstall = ''
    mkdir -p $out/libexec/tyyt
    mkdir -p $out/share/applications

    # Runtime tools come from nixpkgs; GC-safe wrappers pin the store paths.
    cat > $out/libexec/tyyt/mpv <<EOF
#!${pkgs.runtimeShell}
exec ${pkgs.mpv}/bin/mpv "\$@"
EOF
    chmod +x $out/libexec/tyyt/mpv

    # The app looks for an extractor named youtube-dl next to its binary;
    # symlink the nixpkgs yt-dlp under that name.
    ln -s ${pkgs.yt-dlp}/bin/yt-dlp $out/libexec/tyyt/youtube-dl

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
    description = "Lightweight GTK4 YouTube client with adblock-rust";
    homepage = "https://github.com/awfixer/tyyt";
    license = licenses.gpl3Plus;
    mainProgram = "tyyt";
    platforms = platforms.linux;
  };
}

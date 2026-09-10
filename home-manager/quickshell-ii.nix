# illogical-impulse (end-4's dots-hyprland) desktop shell on Quickshell.
#
# Extracted sources live in dots/ii/config/:
#   - quickshell-ii/   full QML shell → ~/.config/quickshell/ii
#   - fuzzel/, wlogout/, matugen/, kde-material-you-colors/, Kvantum/
#   - darklyrc, kdeglobals, dolphinrc, fontconfig/fonts.conf
#
# Everything the shell spawns at runtime resolves through the wrapped `qs`
# binary's PATH (makeBinPath below), so the session works regardless of what
# the interactive shell PATH happens to be. User state is written to
# ~/.config/illogical-impulse, ~/.cache/quickshell and ~/.local/state/quickshell,
# never into the read-only store-symlinked config tree.
{
  config,
  pkgs,
  lib,
  quickshell,
  ...
}:

let
  iiDots = ../dots/ii/config;

  qsBase = pkgs.callPackage ../packages/quickshell { inherit quickshell; };

  # Python env for ii's theming/image scripts. They do
  #   source $ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/activate && exec python3 …
  # so we ship a nix python env plus a minimal `bin/activate` shim.
  iiPython = pkgs.python3.withPackages (
    ps: with ps; [
      materialyoucolor
      pillow
      numpy
      opencv4
      google-auth
      requests
    ]
  );

  iiVenv = pkgs.runCommand "illogical-impulse-python-env" { } ''
    mkdir -p $out/bin
    ln -s ${iiPython}/bin/python3 $out/bin/python3
    ln -s ${iiPython}/bin/python3 $out/bin/python
    cat > $out/bin/activate <<SH
export VIRTUAL_ENV="$out"
export PATH="$out/bin:\$PATH"
deactivate() { :; }
SH
    chmod +x $out/bin/activate
  '';

  # Tools spawned by QML (`Quickshell.execDetached`, `Process {}`) or by the
  # scripts under quickshell-ii/scripts/. Mirrors upstream deps-info.md groups.
  runtimeTools = with pkgs; [
    bc
    bibata-cursors
    brave-search # launcher web-search handoff (LauncherSearch.qml)
    brightnessctl
    cliphist
    ddcutil
    fuzzel
    ghostty
    grim
    hypridle
    hyprpicker
    hyprsunset
    imagemagick
    jq
    python313Packages.kde-material-you-colors
    kdePackages.kdialog
    libqalculate # qalc — searchbar math
    mpvpaper # video wallpapers
    ffmpeg # video wallpaper probe/transcode
    playerctl
    ripgrep
    slurp
    swappy
    translate-shell
    wf-recorder
    wl-clipboard
    wlogout
    wtype
    xdg-user-dirs
    ydotool
    (tesseract.override { enableLanguages = [ "eng" ]; })
  ];

  # Patched qs (see packages/quickshell) plus the Qt modules ii actually
  # imports, gsettings schemas, and a PATH of runtime tools. Based on
  # upstream sdata/dist-nix/home-manager/quickshell.nix.
  qsWrapped =
    pkgs.stdenv.mkDerivation {
      name = "quickshell-ii";
      meta.mainProgram = "qs";

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
        pkgs.qt6.wrapQtAppsHook
      ];

      # Only Qt modules the ii QML tree actually imports. wrapQtAppsHook
      # otherwise dumps qtmultimedia → qtquick3d, virtualkeyboard, sensors,
      # timeline, and FluentWinUI3 onto the QML import path (~tens of MB RSS).
      # kirigami: AppIcon.qml. qt5compat: GraphicalEffects. qtpositioning +
      # qtlocation: Weather.qml. Video wallpapers go through mpvpaper, not
      # QtMultimedia. OSK is a custom PanelWindow, not Qt Virtual Keyboard.
      buildInputs = with pkgs; [
        qsBase
        gsettings-desktop-schemas
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qt5compat
        qt6.qtimageformats
        qt6.qtpositioning
        qt6.qtsvg
        qt6.qttranslations
        qt6.qtwayland
        kdePackages.kirigami
        kdePackages.syntax-highlighting
        kdePackages.qtlocation
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        # QT_LOGGING_RULES drops Qt/QML debug spam (binding loops, etc.) from the
        # journal; warnings and errors still get through.
        makeWrapper ${qsBase}/bin/qs $out/bin/qs \
          --set QT_LOGGING_RULES "*.debug=false" \
          --set QT_QUICK_CONTROLS_STYLE Basic \
          --set QT_IMAGEIO_MAXALLOC 64 \
          --set MALLOC_CONF "narenas:2,background_thread:true,dirty_decay_ms:1000,muzzy_decay_ms:0,abort_conf:true" \
          --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
          --prefix PATH : ${lib.makeBinPath runtimeTools}
        runHook postInstall
      '';
    };

  fontPkgs =
    with pkgs;
    [
      rubik
      material-symbols
      twemoji-color-font
      nerd-fonts.jetbrains-mono
      noto-fonts
    ]
    ++ [
      (pkgs.callPackage ../packages/space-grotesk { })
      (pkgs.callPackage ../packages/readex-pro { })
    ];
in
{
  # ---------------------------------------------------------------- config --
  xdg.configFile = {
    # Out-of-store so QML edits (and qs file-watch reloads) apply without a
    # rebuild. A store copy of shell.qml was what hid the panel family: qs -c ii
    # kept running the previous generation while the git tree was being fixed.
    "quickshell/ii".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/dots/ii/config/quickshell-ii";
    "fuzzel".source = "${iiDots}/fuzzel";
    "wlogout".source = "${iiDots}/wlogout";
    "matugen".source = "${iiDots}/matugen";
    "kde-material-you-colors".source = "${iiDots}/kde-material-you-colors";
    "Kvantum".source = "${iiDots}/Kvantum";
    "darklyrc".source = "${iiDots}/darklyrc";
    "kdeglobals".source = "${iiDots}/kdeglobals";
    "dolphinrc".source = "${iiDots}/dolphinrc";
    "fontconfig/fonts.conf".source = "${iiDots}/fontconfig/fonts.conf";
  };

  home.packages =
    [
      qsWrapped
      # NOTE: iiVenv is intentionally NOT on PATH — it would shadow python3.
      # Scripts reach it via ILLOGICAL_IMPULSE_VIRTUAL_ENV + `bin/activate`.
      pkgs.adw-gtk3 # gsettings gtk-theme targets set by switchwall.sh
      pkgs.whitesur-icon-theme # macOS-style icons (kdeglobals [Icons] Theme)
    ]
    ++ fontPkgs
    ++ runtimeTools;

  # ----------------------------------------------------------------- env ----
  home.sessionVariables = {
    # Theming scripts activate this venv for material-you color generation.
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${iiVenv}";
  };

  # -------------------------------------------------------------- daemons ---
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Runs when something calls `loginctl lock-session` (keybind or the
        # listeners below) — brings up the ii Quickshell lock screen.
        lock_cmd = "qs -c ii ipc call lock activate";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "qs -c ii ipc call lock focus";
        inhibit_sleep = 3;
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session"; # ii session-lock UI appears
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend || loginctl suspend";
        }
      ];
    };
  };

  # Fonts must be discoverable by Qt/fontconfig in this session.
  fonts.fontconfig.enable = true;
}

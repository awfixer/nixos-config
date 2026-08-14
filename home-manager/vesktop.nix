{
  lib,
  pkgs,
  ...
}:

let
  # HM does `cfg.package.override { withSystemVencord = … }`, so the package
  # must remain overridable. Wrap the real vesktop to add PipeWire capture.
  vesktopWithScreenshare = lib.makeOverridable (
    {
      withSystemVencord ? false,
    }:
    let
      base = pkgs.vesktop.override { inherit withSystemVencord; };
    in
    pkgs.symlinkJoin {
      name = "vesktop-screenshare";
      paths = [ base ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      # Electron WebRTC on Wayland needs this feature so Chromium talks to the
      # XDG ScreenCast portal (xdg-desktop-portal-hyprland) → PipeWire.
      # nixpkgs' stock wrapper only adds WaylandWindowDecorations under NIXOS_OZONE_WL.
      postBuild = ''
        wrapProgram $out/bin/vesktop \
          --add-flags "--enable-features=WebRTCPipeWireCapturer" \
          --set-default ELECTRON_OZONE_PLATFORM_HINT auto
      '';
      meta = base.meta // {
        description = "${base.meta.description or "Vesktop"} (PipeWire screenshare)";
      };
    }
  );
in
{
  programs.vesktop = {
    enable = true;
    package = vesktopWithScreenshare { };

    settings = {
      discordBranch = "stable";
      minimizeToTray = true;
      arRPC = true;
      # Helps WebRTC/PipeWire compositing on Intel iGPU
      hardwareAcceleration = true;
      hardwareVideoAcceleration = true;
    };
  };
}

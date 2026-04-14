# flatpak and appimage work, I consider them the same they are both userspace files not fully managed by nix.

{ ... }:

{
  services.flatpak = {
    enable = true;
    update.auto.enable = true;
    uninstallUnmanaged = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      "com.github.unrud.VideoDownloader"
      "io.github.prateekmedia.appimagepool"
      "app.fluxer.Fluxer"
      "io.github.brunofin.Cohesion"
    ];
    overrides.global = {
      Context.sockets = [
        "wayland"
        "x11"
      ];
    };
  };
}

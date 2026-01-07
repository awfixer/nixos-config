{ ... }:

{
  services.flatpak = {
    enable = true;
    update.auto.enable = true;
    uninstallUnmanaged = true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
    ];
    packages = [
      "com.fastmail.Fastmail"
      "io.github.brunofin.Cohesion"
      "com.github.unrud.VideoDownloader"
    ];
    overrides.global = {
      Context.sockets = [ "wayland" "x11" ];
    };
  };
}

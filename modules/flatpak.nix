{ ... }:

{
  # Flatpak for Cohesion (Spotify web client wrapper) and Orion.
  # Both remotes must be declared — NixOS installs `packages` via a boot-time
  # systemd service that fails silently per-package when a remote is missing
  # (Cohesion lives on Flathub, Orion on its own repo).
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      {
        name = "orion-beta";
        location = "https://flatpak.orionbrowser.com/orion-beta.flatpakrepo";
      }
    ];

    # Attribute form (appId + origin), NOT "remote:appId" strings: flatpak 1.18
    # rejects ids containing ":" ("Name can't contain :"), which crashed
    # flatpak-managed-install.service on every activation.
    packages = [
      { appId = "io.github.brunofin.Cohesion"; origin = "flathub"; }
      { appId = "com.kagi.orion"; origin = "orion-beta"; }
    ];
  };
}

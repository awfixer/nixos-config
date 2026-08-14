{ ... }:

{
  # Flatpak runtime + session helper stay off to free RAM / document-portal churn.
  # Spotify is native via modules/spotify.nix (not Flatpak).
  # Re-enable when you need Cohesion; package list is kept for that.
  services.flatpak = {
    enable = false;
    packages = [
      "io.github.brunofin.Cohesion"
    ];
  };
}

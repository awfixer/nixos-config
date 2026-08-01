{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [
      "io.github.brunofin.Cohesion"
    ];
  };
}

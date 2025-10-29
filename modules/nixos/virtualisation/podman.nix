{ ... }:

{
# Podman container platform (Docker alternative)
    podman = {
      enable = true;              # Enable Podman - https://podman.io/
      autoPrune = {
        enable = true;            # Automatically clean up unused containers/images
        dates = "daily";          # Run cleanup daily
      };
    };
}

# Podman Container Runtime Configuration
#
# Configures Podman as an alternative container runtime to Docker.
# Podman is daemonless and provides rootless container management.
# Includes automatic cleanup of unused containers and images.
#
# Reference: https://podman.io/

{ ... }:

{
  virtualisation = {
    podman = {
      enable = true;            # Enable Podman container runtime
      autoPrune = {
        enable = true;          # Automatically clean up unused containers/images
        dates = "daily";        # Run cleanup daily
      };
    };
  };
}

# Docker Container Runtime Configuration
#
# Configures Docker for containerized application deployment and development.
# Includes automatic cleanup of unused containers and images to manage disk space.
#
# Reference: https://www.docker.com/

{ ... }:

{
  virtualisation = {
    docker = {
      enable = true;            # Enable Docker daemon
      autoPrune = {
        enable = true;          # Automatically clean up unused containers/images
        dates = "daily";        # Run cleanup daily
      };
    };
  };
}

{ ... }:

{
  docker = {
    enable = true;              # Enable Docker daemon - https://www.docker.com/
    autoPrune = {
      enable = true;            # Automatically clean up unused containers/images
      dates = "daily";          # Run cleanup daily
    };
  };
}

{ ... }:
{
  home-manager.sharedModules = [
    { home.enableNixpkgsReleaseCheck = false; }
  ];
  imports = [
    ./awfixer
  ];
}
{ ... }:
{
  imports = [
    ./cursor.nix
    ./cal.nix
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}

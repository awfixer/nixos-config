{ ... }:
{
  imports = [
    ./cursor.nix
    ./cal.nix
    #./zips
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}

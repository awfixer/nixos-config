{
  nix.gc = {
    automatic = true;
    frequency = "daily";
    options = "--delete-older-than 5d";
    persistent = true;
  };

}

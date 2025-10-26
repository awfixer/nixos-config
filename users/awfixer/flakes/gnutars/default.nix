{ ... }:

# this basically calls the subfiles using nix-prefetch-url, unpacks them, then installs them
# one day I will submit them to the nixpkgs repo. I actually prolly wont they will be added to my own repo.

{
  imports = [
    ./kraken.nix
  ];
}

{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      nextdns
      (chromium.override { enableWideVine = true; })
      llvm
      llvmPackages.llvm
      llvmPackages.llvm-manpages
      gh
      glab
      ghunt
      git-repo
      reposurgeon
      repomix
      cachix
      autorandr
      killall
      libnotify
      openssl
    ];
  };
}

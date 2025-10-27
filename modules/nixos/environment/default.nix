{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      gh
      glab
      ghunt
      wireshark-cli
      ruby
      rails-new
      tor-browser
      git-repo
      reposurgeon
      repomix
      cachix
      ghostty
      obsidian
      autorandr
      youtube-music
      zed-editor
      devbox
      vesktop
      llvm
      llvmPackages.llvm
      llvmPackages.llvm-manpages
      clang
      clang-tools
      yara
      brave
    ];
  };
}

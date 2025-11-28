{ ... }:
{
  imports = [
    ./gnupg
    ./nix-ld
  ];

  programs = {
    adb.enable = true;
    bat.enable = true;
    htop.enable = true;
    neovim.enable = true;
    vim.enable = true;
    nano.enable = false;
    usbtop.enable = true;
    direnv.enable = true;
    mtr.enable = true;
  };
}

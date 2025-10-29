# System Programs Configuration
# System-wide program enablement and development services
# NixOS programs: https://search.nixos.org/options?query=programs
{ pkgs, ... }:
{
  imports = [
    ./gnupg     # GnuPG encryption and signing configuration
    ./nix-ld    # Dynamic linker for non-NixOS binaries
  ];
  
  # System-wide program configurations
  # These programs are available system-wide with NixOS-specific integration
  programs = {
    bat.enable = true;        # Enhanced cat with syntax highlighting - https://github.com/sharkdp/bat
    htop.enable = true;       # Interactive process viewer - https://htop.dev/
    neovim.enable = true;     # Modern Vim-based editor - https://neovim.io/
    vim.enable = true;        # Classic Vi/Vim editor - https://www.vim.org/
    nano.enable = false;      # Nano text editor (disabled in favor of vim/neovim)
    usbtop.enable = true;     # USB device activity monitor - https://github.com/aguinet/usbtop
    direnv.enable = true;     # Per-directory environment management - https://direnv.net/
    mtr.enable = true;        # Network diagnostic tool - https://www.bitwizard.nl/mtr/
  };

  # Development and database services
  # These services run system-wide and are available to all users
  
  # MySQL/MariaDB database server
  services.mysql = {
    enable = true;            # Enable MySQL service
    package = pkgs.mariadb;   # Use MariaDB as MySQL implementation - https://mariadb.org/
  };
  
  # PostgreSQL database server
  services.postgresql = {
    enable = true;                  # Enable PostgreSQL service
    package = pkgs.postgresql_17;   # Use PostgreSQL 17 - https://www.postgresql.org/
  };
  
  # Emacs editor daemon
  services.emacs = {
    enable = true;            # Enable Emacs daemon service
    install = true;           # Install Emacs package system-wide
    # Documentation: https://www.gnu.org/software/emacs/
  };
}

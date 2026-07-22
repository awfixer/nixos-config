{ config, pkgs, ... }:

{
  # GNOME Keyring = libsecret "login" keystore for apps (browsers, Seahorse, etc.)
  # Unlocked at SDDM login via security.pam.services.sddm.enableGnomeKeyring (system module).
  # SSH agent stays with 1Password (see ssh.nix / git.nix), not gnome-keyring.ssh.
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  # sops CLI looks here for age keys when editing secrets/
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  home.packages = with pkgs; [
    libsecret
    seahorse
    sops
    age
  ];
}
# GNOME Keyring Configuration - Credential Storage
# Provides secure storage for passwords, certificates, and keys
# GNOME Keyring: https://wiki.gnome.org/Projects/GnomeKeyring
# NixOS keyring options: https://search.nixos.org/options?query=gnome-keyring
{ ... }:
{
  services.gnome.gnome-keyring = {
    enable = true;                # Enable GNOME Keyring service
    
    # Additional configuration options:
    # components = [ "secrets" "ssh" "pkcs11" ];  # Enable specific components
  };
  
  # GNOME Keyring provides:
  # - Password storage for applications
  # - SSH key management
  # - Certificate storage
  # - Integration with web browsers and applications
  # - Automatic unlocking on login
}

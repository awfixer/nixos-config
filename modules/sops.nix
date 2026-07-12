{ config, pkgs, ... }:

{
  # ---------------------------------------------------------------------------
  # sops-nix — age-encrypted secrets
  #
  # Private key locations (same key on this single-user laptop):
  #   ~/.config/sops/age/keys.txt   — used by `sops` CLI when editing
  #   sops.age.keyFile below         — used by NixOS activation to decrypt
  #
  # Backup the AGE-SECRET-KEY- line in 1Password, then delete
  #   ~/1password-import/*
  # ---------------------------------------------------------------------------

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # Dedicated age key (OpenSSH host keys are unavailable — sshd is disabled)
    age = {
      keyFile = "/home/awfixer/.config/sops/age/keys.txt";
      # Do not try to import non-existent SSH host keys
      sshKeyPaths = [ ];
      generateKey = false;
    };

    # Declare secrets here as you add them to secrets/secrets.yaml, e.g.:
    #   sops.secrets.tailscale-authkey = { };
    # Then reference: config.sops.secrets.tailscale-authkey.path
    secrets = {
      # Placeholder so the module validates the sops file at eval time.
      # Safe to leave; path is /run/secrets/placeholder
      placeholder = { };
    };
  };

  # CLI tools for creating/editing secrets
  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}

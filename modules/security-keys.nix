{ pkgs, ... }:

# Physical security keys (YubiKey, Nitrokey, SoloKeys, etc.)
#
# Goals:
#   - FIDO2 / U2F / WebAuthn for browsers (Chromium, Helium, …) and native apps
#   - PC/SC (CCID) for PIV, OpenPGP card, OATH, smart-card apps
#   - Session user access via udev TAG+="uaccess" (logind seat), no root needed
#
# PAM login/sudo with a key is intentionally NOT enabled here — that needs
# enrollment (`pamu2fcfg`) first. Uncomment the pam block after you have
# ~/.config/Yubico/u2f_keys.
{
  # ---------------------------------------------------------------------------
  # Device access (udev)
  #
  # systemd already ships 60-fido-id.rules + 70-uaccess.rules so that anything
  # tagged ID_SECURITY_TOKEN / ID_SMARTCARD_READER is usable by the active
  # graphical seat. Vendor packages fill gaps (YubiKey OTP interfaces, etc.).
  # ---------------------------------------------------------------------------
  services.udev.packages = with pkgs; [
    yubikey-personalization # Yubico USB IDs → ID_SECURITY_TOKEN=1
    libfido2 # extra FIDO2 device rules when present
    libu2f-host # legacy U2F host rules
  ];

  # GnuPG smart-card udev (OpenPGP applet on YubiKey / Nitrokey / etc.)
  hardware.gpgSmartcards.enable = true;

  # Nitrokey udev (no-op if you only use other brands)
  hardware.nitrokey.enable = true;

  # ---------------------------------------------------------------------------
  # Smart card daemon (PIV / CCID / Yubico Authenticator / many enterprise apps)
  #
  # FIDO2 WebAuthn does NOT need this — browsers talk HID directly — but PIV,
  # OpenPGP card, and OATH TOTP-on-key apps do.
  # ---------------------------------------------------------------------------
  services.pcscd = {
    enable = true;
    # Default plugins already include pkgs.ccid (USB CCID readers + YubiKey CCID).
  };

  # ---------------------------------------------------------------------------
  # CLI / GUI tooling (on-demand; no always-on agents that steal SSH_AUTH_SOCK)
  # ---------------------------------------------------------------------------
  programs.yubikey-manager.enable = true;

  environment.systemPackages = with pkgs; [
    libfido2 # fido2-token, fido2-cred, fido2-assert — WebAuthn smoke tests
    pam_u2f # pamu2fcfg — enroll keys for optional PAM later
    yubikey-personalization # ykpersonalize / ykinfo
    yubico-piv-tool # PIV certs / slots
    pcsc-tools # pcsc_scan — list CCID readers / cards
    opensc # pkcs11-tool, opensc-tool for smart-card debugging
    # Desktop OATH UI (Yubico Authenticator) — open when needed
    yubioath-flutter
  ];

  # ---------------------------------------------------------------------------
  # Optional: OS login / sudo with FIDO U2F (disabled until enrolled)
  #
  # Enroll first:
  #   mkdir -p ~/.config/Yubico
  #   pamu2fcfg > ~/.config/Yubico/u2f_keys
  #   # second key: pamu2fcfg -n >> ~/.config/Yubico/u2f_keys
  #
  # Then enable:
  #   security.pam.services = {
  #     login.u2fAuth = true;
  #     sudo.u2fAuth = true;
  #     sddm.u2fAuth = true; # display manager
  #   };
  #   # cue = prompt "Please touch the device"
  #   security.pam.u2f = {
  #     enable = true;
  #     settings.cue = true;
  #     control = "sufficient"; # key OR password; use "required" for MFA
  #   };
  # ---------------------------------------------------------------------------
}

{ config, lib, pkgs, ... }:

{
  # xkb layout only — full X server stack is not required for Wayland SDDM/Hyprland,
  # but NixOS still wires xkb via this option for greeter/XWayland.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    # No X desktop extras.
    excludePackages = [ ];
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # No 32-bit Steam/wine stack on this box — drop multi-lib audio.
    alsa.support32Bit = false;
    pulse.enable = true;
    jack.enable = false;
    # WirePlumber: A2DP/HFP + PipeWire video nodes for portal ScreenCast
    wireplumber.enable = true;

    # -----------------------------------------------------------------
    # Bluetooth (BCM4350 MacBook UART + JBL Tune Buds 2):
    #
    # HFP/HSP SCO on this controller is unreliable (mSBC always silent;
    # CVSD intermittently silent). Do not expose headset profiles at all
    # — buds stay A2DP speakers only; mic = laptop CS4208 (proven working).
    #
    # Vesktop: Output = JBL / Default, Input = Built-in / Default.
    # -----------------------------------------------------------------
    wireplumber.extraConfig."10-bluez-a2dp-only" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = false;
        "bluez5.enable-hw-volume" = true;
        # Speakers only — no HFP/HSP Audio Gateway (no broken SCO mic path).
        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
        ];
      };
    };

    wireplumber.extraConfig."11-bluetooth-policy" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Bluetooth (Broadcom BCM4350 combo on this laptop — hci0 present)
  # Radio stays powered. UI lives in the ii Quickshell Bluetooth panel
  # (kcm_bluetooth); no blueman tray applet anymore.
  # ---------------------------------------------------------------------------
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        ControllerMode = "dual";
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
}

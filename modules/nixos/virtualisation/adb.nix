# Android Debug Bridge (ADB) Configuration
#
# Enables the Android Debug Bridge for debugging and interfacing with Android devices.
# Useful for Android development, device management, and debugging.
#
# Reference: https://developer.android.com/tools/adb

{ ... }:

{
  programs = {
    adb = {
      enable = true;  # Enable Android Debug Bridge
    };
  };
}

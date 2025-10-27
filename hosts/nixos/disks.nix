{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/hardware/network/broadcom-43xx.nix")
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
  boot.loader.grub = {
    enable = lib.mkForce true;
    efiSupport = lib.mkForce true;
    efiInstallAsRemovable = lib.mkForce true;
    useOSProber = true;
    device = lib.mkForce "nodev";
  };
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/07113103-f36b-40e1-b01d-92dbeecf16e0";
      fsType = "ext4";
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E885-539B";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  swapDevices =
    [ { device = "/dev/disk/by-uuid/cb030267-2208-4fe8-bc18-28aee719249a"; }
    ];
    networking.useDHCP = lib.mkDefault true;
# networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

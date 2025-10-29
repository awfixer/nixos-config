{ ... }:

{
  # QEMU guest agent for when running as a VM
  services.qemuGuest = {
    enable = true;                # Enable QEMU guest agent
  };
}

{ ... }:
{
  config = {
    services.udisks2.enable = true;
    services.devmon.enable = true;
    services.gvfs.enable = true;
    services.fstrim.enable = true;
  };
}

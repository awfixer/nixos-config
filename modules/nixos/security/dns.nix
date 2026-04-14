{ ... }:

{
  services.nextdns = {
    enable = false;
    arguments = [
      "-config"
      "abcdef"
      "-cache-size"
      "10MB"
    ];
  };
}

{ ... }:

{
  services.nextdns = {
    enable = true;
    arguments = [ "-config" "abcdef" "-cache-size" "10MB" ];  };
}

# System Services Configuration Module
# System-wide service configurations and daemon management
# NixOS services: https://search.nixos.org/options?query=services
{ ... }:
{
  imports = [
    #./python    # Python-related services (currently disabled)
    ./ssh        # SSH daemon configuration
    #./printing  # Printing services configuration (currently disabled)
    #./dns       # DNS services configuration (currently disabled)
    #./audio     # Audio services configuration (currently disabled)
  ];
  
  # Additional services can be configured here or in separate modules
  # Examples of services that could be added:
  # - Web servers (nginx, apache)
  # - Database services (already in programs module)
  # - Monitoring and logging services
  # - Container orchestration
  # - Backup services
}
